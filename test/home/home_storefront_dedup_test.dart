// Slice D2 — HomeScreen.loadData and AllStoreScreen.initState load the same
// storefront lists in the same frame. Each list must reach the backend ONCE per
// concurrent load, without sharing across module/zone/language, and without
// blocking later refreshes or retries.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/repositories/banner_repository.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service.dart';
import 'package:moonjoin/features/brands/controllers/brands_controller.dart';
import 'package:moonjoin/features/brands/domain/repositories/brands_repository.dart';
import 'package:moonjoin/features/brands/domain/services/brands_service.dart';
import 'package:moonjoin/features/category/controllers/category_controller.dart';
import 'package:moonjoin/features/category/domain/reposotories/category_repository.dart';
import 'package:moonjoin/features/category/domain/services/category_service.dart';
import 'package:moonjoin/features/flash_sale/domain/repositories/flash_sale_repository.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/repositories/store_repository.dart';
import 'package:moonjoin/features/store/domain/services/store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Real SplashController with the active module pinned (repositories read it for
/// their cache ids).
class _TestSplash extends SplashController {
  _TestSplash() : super(splashServiceInterface: _FakeSplashService());
  @override
  ModuleModel? get module => ModuleModel(id: 3, moduleType: 'food');
}

/// Every GET is held until the test answers it, so concurrency is deterministic.
class _GatedApiClient implements ApiClient {
  final List<String> calls = <String>[];
  final List<Completer<Response>> pending = <Completer<Response>>[];
  Map<String, String> headers = <String, String>{'moduleId': '3', 'zoneId': '[7]', 'X-localization': 'en'};

  @override
  Map<String, String> getHeader() => headers;

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) {
    calls.add(uri);
    final Completer<Response> c = Completer<Response>();
    pending.add(c);
    return c.future;
  }

  void answerAll(Response response) {
    for (final Completer<Response> c in pending) {
      if (!c.isCompleted) c.complete(response);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Response _ok(Object body) => Response(statusCode: 200, body: body);
const Response _fail = Response(statusCode: 500, statusText: 'Server error');
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));
/// Controllers read the (real, drift) cache before going to the network; the first
/// read opens the database, so give it longer than a plain microtask hop.
Future<void> _settleDb() => Future<void>.delayed(const Duration(milliseconds: 600));

final Map<String, dynamic> _stores = <String, dynamic>{'stores': <Map<String, dynamic>>[<String, dynamic>{'id': 56, 'name': 'ZonaPOP', 'featured': 0}]};
final Map<String, dynamic> _banners = <String, dynamic>{'campaigns': <dynamic>[], 'banners': <dynamic>[]};
final List<Map<String, dynamic>> _categories = <Map<String, dynamic>>[<String, dynamic>{'id': 42, 'name': 'Ice Cream'}];
final List<Map<String, dynamic>> _brands = <Map<String, dynamic>>[<String, dynamic>{'id': 1, 'name': 'Brand'}];
final Map<String, dynamic> _flash = <String, dynamic>{'id': 9, 'title': 'Flash'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Directory tmp = Directory.systemTemp.createTempSync('moonjoin_home_dedup_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async => tmp.path,
  );

  late _GatedApiClient api;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Get.put<SharedPreferences>(await SharedPreferences.getInstance());
    Get.put<SplashController>(_TestSplash());
    api = _GatedApiClient();
  });

  tearDown(() async {
    api.answerAll(_fail); // never leave a shared in-flight entry behind for the next test
    await _settle();
    Get.reset();
  });

  group('repositories: concurrent identical loads share one request', () {
    Future<void> expectShared(String name, Future<Object?> Function() load, Object body) async {
      final Future<Object?> home = load();      // HomeScreen.loadData
      final Future<Object?> allStore = load();  // AllStoreScreen.initState
      await _settle();
      expect(api.calls, hasLength(1), reason: '$name must reach the backend once');
      api.answerAll(_ok(body));
      final Object? a = await home;
      final Object? b = await allStore;
      expect(a, isNotNull, reason: '$name: first caller gets the result');
      expect(b, isNotNull, reason: '$name: second caller gets the result');
    }

    test('stores/latest', () async {
      final StoreRepository repo = StoreRepository(apiClient: api, sharedPreferences: Get.find());
      await expectShared('stores/latest', () => repo.getList(isLatestStoreList: true, type: 'all', source: DataSourceEnum.client), _stores);
    });

    test('banners', () async {
      final BannerRepository repo = BannerRepository(apiClient: api);
      await expectShared('banners', () => repo.getList(isBanner: true, source: DataSourceEnum.client), _banners);
    });

    test('categories', () async {
      final CategoryRepository repo = CategoryRepository(apiClient: api);
      await expectShared('categories', () => repo.getList(categoryList: true, allCategory: false, source: DataSourceEnum.client), _categories);
    });

    test('flash-sales', () async {
      final FlashSaleRepository repo = FlashSaleRepository(apiClient: api);
      await expectShared('flash-sales', () => repo.getFlashSale(source: DataSourceEnum.client), _flash);
    });

    test('brand', () async {
      final BrandsRepository repo = BrandsRepository(apiClient: api);
      await expectShared('brand', () => repo.getBrandList(source: DataSourceEnum.client), _brands);
    });
  });

  group('guard boundaries', () {
    test('a different module (header) in flight is NOT shared', () async {
      final BannerRepository repo = BannerRepository(apiClient: api);
      final Future<Object?> food = repo.getList(isBanner: true, source: DataSourceEnum.client);
      api.headers = <String, String>{...api.headers, 'moduleId': '5'};
      final Future<Object?> grocery = repo.getList(isBanner: true, source: DataSourceEnum.client);
      await _settle();
      expect(api.calls, hasLength(2));
      api.answerAll(_ok(_banners));
      await food;
      await grocery;
    });

    test('a zone change while a request is in flight starts a new request', () async {
      final StoreRepository repo = StoreRepository(apiClient: api, sharedPreferences: Get.find());
      final Future<Object?> before = repo.getList(isLatestStoreList: true, type: 'all', source: DataSourceEnum.client);
      api.headers = <String, String>{...api.headers, 'zoneId': '[8]'};
      final Future<Object?> after = repo.getList(isLatestStoreList: true, type: 'all', source: DataSourceEnum.client);
      await _settle();
      expect(api.calls, hasLength(2));
      api.answerAll(_ok(_stores));
      await before;
      await after;
    });

    test('after completion a reload reaches the network again', () async {
      final CategoryRepository repo = CategoryRepository(apiClient: api);
      final Future<Object?> first = repo.getList(categoryList: true, allCategory: false, source: DataSourceEnum.client);
      await _settle();
      api.answerAll(_ok(_categories));
      await first;
      final Future<Object?> reload = repo.getList(categoryList: true, allCategory: false, source: DataSourceEnum.client);
      await _settle();
      expect(api.calls, hasLength(2));
      api.answerAll(_ok(_categories));
      expect(await reload, isNotNull);
    });

    test('a failed shared request returns null to both callers, then a retry works', () async {
      final StoreRepository repo = StoreRepository(apiClient: api, sharedPreferences: Get.find());
      final Future<Object?> a = repo.getList(isLatestStoreList: true, type: 'all', source: DataSourceEnum.client);
      final Future<Object?> b = repo.getList(isLatestStoreList: true, type: 'all', source: DataSourceEnum.client);
      await _settle();
      expect(api.calls, hasLength(1));
      api.answerAll(_fail);
      expect(await a, isNull);
      expect(await b, isNull);

      final Future<Object?> retry = repo.getList(isLatestStoreList: true, type: 'all', source: DataSourceEnum.client);
      await _settle();
      expect(api.calls, hasLength(2));
      api.answerAll(_ok(_stores));
      expect(await retry, isNotNull);
    });
  });

  group('controllers: the Home + AllStoreScreen double call now costs one request per list', () {
    test('BannerController.getBannerList(false) twice → 1 banner request, list populated', () async {
      final BannerController c = BannerController(bannerServiceInterface: BannerService(bannerRepositoryInterface: BannerRepository(apiClient: api)));
      c.getBannerList(false);
      c.getBannerList(false);
      await _settleDb();
      expect(api.calls.where((u) => u.contains('banners')), hasLength(1));
      api.answerAll(_ok(<String, dynamic>{'campaigns': <dynamic>[], 'banners': <dynamic>[<String, dynamic>{'id': 1, 'title': 'b', 'type': 'default', 'image_full_url': 'https://x/b.png'}]}));
      await _settleDb();
      expect(c.bannerImageList, isNotNull);
    });

    test('CategoryController.getCategoryList(false) twice → 1 category request, list populated', () async {
      final CategoryController c = CategoryController(categoryServiceInterface: CategoryService(categoryRepositoryInterface: CategoryRepository(apiClient: api)));
      c.getCategoryList(false);
      c.getCategoryList(false);
      await _settleDb();
      expect(api.calls, hasLength(1));
      api.answerAll(_ok(_categories));
      await _settleDb();
      expect(c.categoryList!.single.id, 42);
    });

    test('StoreController.getLatestStoreList(false) twice → 1 stores/latest request, list populated', () async {
      final StoreController c = StoreController(storeServiceInterface: StoreService(storeRepositoryInterface: StoreRepository(apiClient: api, sharedPreferences: Get.find())));
      c.getLatestStoreList(false, 'all', false);
      c.getLatestStoreList(false, 'all', false);
      await _settleDb();
      expect(api.calls, hasLength(1));
      api.answerAll(_ok(_stores));
      await _settleDb();
      expect(c.latestStoreList!.single.id, 56);
    });

    test('BrandsController.getBrandList() twice (Ecommerce loadData + AllStoreScreen) → 1 brand request', () async {
      final BrandsController c = BrandsController(brandsServiceInterface: BrandsService(brandsRepositoryInterface: BrandsRepository(apiClient: api)));
      c.getBrandList();
      c.getBrandList();
      await _settleDb();
      expect(api.calls, hasLength(1));
      api.answerAll(_ok(_brands));
      await _settleDb();
      expect(c.brandList!.single.id, 1);
    });

    test('reload=true after completion still refreshes (module switch / post-order / location change)', () async {
      final CategoryController c = CategoryController(categoryServiceInterface: CategoryService(categoryRepositoryInterface: CategoryRepository(apiClient: api)));
      c.getCategoryList(false);
      await _settleDb();
      api.answerAll(_ok(_categories));
      await _settleDb();
      c.getCategoryList(true);
      await _settleDb();
      expect(api.calls, hasLength(2));
      api.answerAll(_ok(<Map<String, dynamic>>[<String, dynamic>{'id': 43, 'name': 'Cakes'}]));
      await _settleDb();
      expect(c.categoryList!.single.id, 43);
    });
  });
}
