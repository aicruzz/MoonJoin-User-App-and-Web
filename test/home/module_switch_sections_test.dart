// Slice E2b — after a module switch, a load that belonged to the previous module
// must not be applied to categories, flash sale, banners, item campaigns or
// advertisements (the E2 pattern for the store list, extended). Module A's result
// is still cached under module A's own key by the repository; only the in-memory
// UI state is protected. Advertisements are additionally cleared on switch.
//
// Answers are released explicitly with Completers — no timing assumptions.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/models/banner_model.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/category/controllers/category_controller.dart';
import 'package:moonjoin/features/category/domain/models/category_model.dart';
import 'package:moonjoin/features/category/domain/services/category_service_interface.dart';
import 'package:moonjoin/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:moonjoin/features/flash_sale/domain/models/flash_sale_model.dart' show FlashSaleModel;
import 'package:moonjoin/features/flash_sale/domain/services/flash_sale_service_interface.dart';
import 'package:moonjoin/features/home/controllers/advertisement_controller.dart';
import 'package:moonjoin/features/home/domain/models/advertisement_model.dart';
import 'package:moonjoin/features/home/domain/repositories/advertisement_repository.dart';
import 'package:moonjoin/features/home/domain/services/advertisement_service.dart';
import 'package:moonjoin/features/home/domain/services/advertisement_service_interface.dart';
import 'package:moonjoin/features/item/controllers/campaign_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/services/campaign_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final ModuleModel _grocery = ModuleModel(id: 5, moduleType: 'grocery');
final ModuleModel _fashion = ModuleModel(id: 8, moduleType: 'ecommerce');

/// Real SplashController whose active module the test switches directly.
class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _FakeSplashService());
  ModuleModel? active = _grocery;
  @override
  ModuleModel? get module => active;
  @override
  Module getModuleConfig(String? moduleType) => Module(newVariation: false);
}

/// One held answer per service call, released by the test.
class _Gate<T> {
  final List<({DataSourceEnum source, Completer<T?> answer})> calls = <({DataSourceEnum source, Completer<T?> answer})>[];
  Future<T?> call(DataSourceEnum source) {
    final Completer<T?> c = Completer<T?>();
    calls.add((source: source, answer: c));
    return c.future;
  }
}

class _CategoryService implements CategoryServiceInterface {
  final _Gate<List<CategoryModel>> gate = _Gate<List<CategoryModel>>();
  @override
  Future<List<CategoryModel>?> getCategoryList(bool allCategory, {DataSourceEnum? source}) => gate.call(source!);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FlashService implements FlashSaleServiceInterface {
  final _Gate<FlashSaleModel> gate = _Gate<FlashSaleModel>();
  @override
  Future<FlashSaleModel?> getFlashSale(DataSourceEnum source) => gate.call(source);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BannerService implements BannerServiceInterface {
  final _Gate<BannerModel> gate = _Gate<BannerModel>();
  @override
  Future<BannerModel?> getBannerList({required DataSourceEnum source}) => gate.call(source);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CampaignService implements CampaignServiceInterface {
  final _Gate<List<Item>> gate = _Gate<List<Item>>();
  @override
  Future<List<Item>?> getItemCampaignList(DataSourceEnum dataSource) => gate.call(dataSource);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AdService implements AdvertisementServiceInterface {
  final _Gate<List<AdvertisementModel>> gate = _Gate<List<AdvertisementModel>>();
  @override
  Future<List<AdvertisementModel>?> getAdvertisementList(DataSourceEnum source) => gate.call(source);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Network for the ads cache test: each GET waits for the test to answer it.
class _GatedApiClient implements ApiClient {
  final List<Completer<Response>> pending = <Completer<Response>>[];
  Map<String, String> headers = <String, String>{'moduleId': '5', 'zoneId': '[7]'};
  @override
  Map<String, String> getHeader() => headers;
  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) {
    final Completer<Response> c = Completer<Response>();
    pending.add(c);
    return c.future;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lets queued microtasks and completed futures run.
Future<void> _flush() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<CategoryModel> _cats(List<int> ids) => <CategoryModel>[for (final int id in ids) CategoryModel(id: id, name: 'Cat $id')];
BannerModel _banner(String image) => BannerModel.fromJson(<String, dynamic>{
      'campaigns': <dynamic>[],
      'banners': <dynamic>[<String, dynamic>{'id': 1, 'title': image, 'type': 'default', 'image_full_url': image}],
    });
List<Item> _items(List<int> ids) => <Item>[
      for (final int id in ids) Item(id: id, name: 'Item $id', moduleType: 'grocery', variations: <Variation>[], foodVariations: <FoodVariation>[]),
    ];
List<AdvertisementModel> _ads(List<int> ids) => <AdvertisementModel>[for (final int id in ids) AdvertisementModel(id: id, title: 'Ad $id')];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Splash splash;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Get.put<SharedPreferences>(await SharedPreferences.getInstance());
    splash = _Splash();
    Get.put<SplashController>(splash);
  });

  tearDown(Get.reset);

  // ---------------------------------------------------------------------------
  group('Categories', () {
    late _CategoryService service;
    late CategoryController c;
    late int updates;
    setUp(() {
      service = _CategoryService();
      c = CategoryController(categoryServiceInterface: service);
      updates = 0;
      c.addListener(() => updates++);
    });

    test('same module: cache then network both apply', () async {
      c.getCategoryList(false);
      service.gate.calls[0].answer.complete(_cats(<int>[1]));
      await _flush();
      expect(c.categoryList!.single.id, 1);
      expect(service.gate.calls[1].source, DataSourceEnum.client);
      service.gate.calls[1].answer.complete(_cats(<int>[2, 3]));
      await _flush();
      expect(c.categoryList!.map((x) => x.id), <int>[2, 3]);
      expect(updates, 2);
    });

    test('Grocery cache answer after switching to Fashion: ignored, no repaint, no follow-up network load', () async {
      c.getCategoryList(false);
      splash.active = _fashion;
      c.clearCategoryList();
      service.gate.calls[0].answer.complete(_cats(<int>[501, 502]));
      await _flush();
      expect(c.categoryList, isNull);
      expect(updates, 0);
      expect(service.gate.calls, hasLength(1), reason: 'the stale load must not start its network step');
    });

    test('Grocery network answer after Fashion already applied: ignored; Fashion stays; no repaint', () async {
      c.getCategoryList(false);                                 // Grocery
      service.gate.calls[0].answer.complete(_cats(<int>[501]));
      await _flush();                                           // Grocery network in flight (calls[1])

      splash.active = _fashion;
      c.clearCategoryList();
      c.getCategoryList(false);                                 // Fashion
      service.gate.calls[2].answer.complete(_cats(<int>[801]));
      await _flush();
      service.gate.calls[3].answer.complete(_cats(<int>[802]));
      await _flush();
      expect(c.categoryList!.single.id, 802);
      final int before = updates;

      service.gate.calls[1].answer.complete(_cats(<int>[503])); // late Grocery network
      await _flush();
      expect(c.categoryList!.single.id, 802, reason: 'Fashion must never show Grocery categories');
      expect(updates, before);
    });

    test('reload=true still clears and refreshes', () async {
      c.getCategoryList(false);
      service.gate.calls[0].answer.complete(_cats(<int>[1]));
      await _flush();
      service.gate.calls[1].answer.complete(_cats(<int>[2]));
      await _flush();
      c.getCategoryList(true);
      expect(c.categoryList, isNull);
      service.gate.calls[2].answer.complete(_cats(<int>[2]));
      await _flush();
      service.gate.calls[3].answer.complete(_cats(<int>[4]));
      await _flush();
      expect(c.categoryList!.single.id, 4);
    });
  });

  // ---------------------------------------------------------------------------
  group('Flash sale', () {
    late _FlashService service;
    late FlashSaleController c;
    late int updates;
    setUp(() {
      service = _FlashService();
      c = FlashSaleController(flashSaleServiceInterface: service);
      updates = 0;
      c.addListener(() => updates++);
    });

    test('same module: cache then network both apply', () async {
      c.getFlashSale(false, false);
      service.gate.calls[0].answer.complete(FlashSaleModel(id: 1, title: 'Grocery flash'));
      await _flush();
      expect(c.flashSaleModel!.id, 1);
      service.gate.calls[1].answer.complete(FlashSaleModel(id: 2, title: 'Grocery flash 2'));
      await _flush();
      expect(c.flashSaleModel!.id, 2);
    });

    test('Grocery answers after switching to Fashion: not applied, no repaint, countdown timer NOT started', () async {
      c.getFlashSale(false, false);
      splash.active = _fashion;
      c.setEmptyFlashSale(fromModule: true);
      final String future = DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String().replaceFirst('Z', '');
      service.gate.calls[0].answer.complete(FlashSaleModel(id: 501, title: 'Mango / Fruset', endDate: future));
      await _flush();
      expect(c.flashSaleModel, isNull);
      expect(c.duration, isNull, reason: 'a stale answer must not (re)start the countdown');
      expect(updates, 0);
      expect(service.gate.calls, hasLength(1));
    });

    test('Grocery network answer after Fashion applied: ignored; Fashion stays', () async {
      c.getFlashSale(false, false);
      service.gate.calls[0].answer.complete(FlashSaleModel(id: 501));
      await _flush();
      splash.active = _fashion;
      c.setEmptyFlashSale(fromModule: true);
      c.getFlashSale(false, false);
      service.gate.calls[2].answer.complete(FlashSaleModel(id: 801));
      await _flush();
      service.gate.calls[3].answer.complete(FlashSaleModel(id: 802));
      await _flush();
      final int before = updates;
      service.gate.calls[1].answer.complete(FlashSaleModel(id: 503));
      await _flush();
      expect(c.flashSaleModel!.id, 802);
      expect(updates, before);
    });

    test('reload=true still clears and refreshes', () async {
      c.getFlashSale(false, false);
      service.gate.calls[0].answer.complete(FlashSaleModel(id: 1));
      await _flush();
      service.gate.calls[1].answer.complete(FlashSaleModel(id: 2));
      await _flush();
      c.getFlashSale(true, false);
      expect(c.flashSaleModel, isNull);
      service.gate.calls[2].answer.complete(FlashSaleModel(id: 2));
      await _flush();
      service.gate.calls[3].answer.complete(FlashSaleModel(id: 4));
      await _flush();
      expect(c.flashSaleModel!.id, 4);
    });
  });

  // ---------------------------------------------------------------------------
  group('Banners', () {
    late _BannerService service;
    late BannerController c;
    late int updates;
    setUp(() {
      service = _BannerService();
      c = BannerController(bannerServiceInterface: service);
      updates = 0;
      c.addListener(() => updates++);
    });

    test('same module: cache then network both apply', () async {
      c.getBannerList(false);
      service.gate.calls[0].answer.complete(_banner('grocery-1'));
      await _flush();
      expect(c.bannerImageList, <String?>['grocery-1']);
      service.gate.calls[1].answer.complete(_banner('grocery-2'));
      await _flush();
      expect(c.bannerImageList, <String?>['grocery-2']);
    });

    test('Grocery cache answer after switching to Fashion: banner state untouched, no repaint', () async {
      c.getBannerList(false);
      splash.active = _fashion;
      c.clearBanner();
      service.gate.calls[0].answer.complete(_banner('grocery-1'));
      await _flush();
      expect(c.bannerImageList, isNull);
      expect(c.bannerDataList, isNull);
      expect(updates, 0);
      expect(service.gate.calls, hasLength(1));
    });

    test('Grocery network answer after Fashion applied: ignored; Fashion banner stays', () async {
      c.getBannerList(false);
      service.gate.calls[0].answer.complete(_banner('grocery-1'));
      await _flush();
      splash.active = _fashion;
      c.clearBanner();
      c.getBannerList(false);
      service.gate.calls[2].answer.complete(_banner('fashion-1'));
      await _flush();
      service.gate.calls[3].answer.complete(_banner('fashion-2'));
      await _flush();
      final int before = updates;
      service.gate.calls[1].answer.complete(_banner('grocery-2'));
      await _flush();
      expect(c.bannerImageList, <String?>['fashion-2']);
      expect(updates, before);
    });

    test('reload=true still clears and refreshes', () async {
      c.getBannerList(false);
      service.gate.calls[0].answer.complete(_banner('a'));
      await _flush();
      service.gate.calls[1].answer.complete(_banner('b'));
      await _flush();
      c.getBannerList(true);
      expect(c.bannerImageList, isNull);
      service.gate.calls[2].answer.complete(_banner('b'));
      await _flush();
      service.gate.calls[3].answer.complete(_banner('c'));
      await _flush();
      expect(c.bannerImageList, <String?>['c']);
    });
  });

  // ---------------------------------------------------------------------------
  group('Item campaigns', () {
    late _CampaignService service;
    late CampaignController c;
    late int updates;
    setUp(() {
      service = _CampaignService();
      c = CampaignController(campaignServiceInterface: service);
      updates = 0;
      c.addListener(() => updates++);
    });

    test('same module: cache then network both apply', () async {
      c.getItemCampaignList(false);
      service.gate.calls[0].answer.complete(_items(<int>[1]));
      await _flush();
      expect(c.itemCampaignList!.single.id, 1);
      service.gate.calls[1].answer.complete(_items(<int>[2, 3]));
      await _flush();
      expect(c.itemCampaignList!.map((x) => x.id), <int>[2, 3]);
    });

    test('Grocery cache answer after switching to Fashion: campaign state untouched, no repaint', () async {
      c.getItemCampaignList(false);
      splash.active = _fashion;
      c.itemAndBasicCampaignNull();
      service.gate.calls[0].answer.complete(_items(<int>[501]));
      await _flush();
      expect(c.itemCampaignList, isNull);
      expect(updates, 0);
      expect(service.gate.calls, hasLength(1));
    });

    test('Grocery network answer after Fashion applied: ignored; Fashion stays', () async {
      c.getItemCampaignList(false);
      service.gate.calls[0].answer.complete(_items(<int>[501]));
      await _flush();
      splash.active = _fashion;
      c.itemAndBasicCampaignNull();
      c.getItemCampaignList(false);
      service.gate.calls[2].answer.complete(_items(<int>[801]));
      await _flush();
      service.gate.calls[3].answer.complete(_items(<int>[802]));
      await _flush();
      final int before = updates;
      service.gate.calls[1].answer.complete(_items(<int>[503]));
      await _flush();
      expect(c.itemCampaignList!.single.id, 802);
      expect(updates, before);
    });

    test('reload=true still refreshes', () async {
      c.getItemCampaignList(false);
      service.gate.calls[0].answer.complete(_items(<int>[1]));
      await _flush();
      service.gate.calls[1].answer.complete(_items(<int>[2]));
      await _flush();
      c.getItemCampaignList(true);
      service.gate.calls[2].answer.complete(_items(<int>[2]));
      await _flush();
      service.gate.calls[3].answer.complete(_items(<int>[4]));
      await _flush();
      expect(c.itemCampaignList!.single.id, 4);
    });
  });

  // ---------------------------------------------------------------------------
  group('Advertisements', () {
    late _AdService service;
    late AdvertisementController c;
    late int updates;
    setUp(() {
      service = _AdService();
      c = AdvertisementController(advertisementServiceInterface: service);
      updates = 0;
      c.addListener(() => updates++);
    });

    test('same module: cache then network both apply', () async {
      c.getAdvertisementList();
      service.gate.calls[0].answer.complete(_ads(<int>[1]));
      await _flush();
      expect(c.advertisementList!.single.id, 1);
      service.gate.calls[1].answer.complete(_ads(<int>[2]));
      await _flush();
      expect(c.advertisementList!.single.id, 2);
    });

    test('clearAdvertisementList() sets the in-memory list to null', () async {
      c.getAdvertisementList();
      service.gate.calls[0].answer.complete(_ads(<int>[1]));
      await _flush();
      expect(c.advertisementList, isNotNull);
      c.clearAdvertisementList();
      expect(c.advertisementList, isNull);
    });

    test('after the switch clear, an uncached Fashion never shows Grocery ads', () async {
      c.getAdvertisementList();                                  // Grocery
      service.gate.calls[0].answer.complete(_ads(<int>[501]));
      await _flush();
      service.gate.calls[1].answer.complete(_ads(<int>[502]));
      await _flush();
      expect(c.advertisementList!.single.id, 502);

      splash.active = _fashion;
      c.clearAdvertisementList();                                // switchModule
      c.getAdvertisementList();                                  // Fashion
      service.gate.calls[2].answer.complete(null);               // no Fashion cache yet
      await _flush();
      expect(c.advertisementList, isNull, reason: 'Grocery ads must not be visible while Fashion loads');
      service.gate.calls[3].answer.complete(_ads(<int>[801]));
      await _flush();
      expect(c.advertisementList!.single.id, 801);
    });

    test('late Grocery answers after switching to Fashion are ignored (cache and network), no repaint', () async {
      c.getAdvertisementList();                                  // Grocery cache pending
      splash.active = _fashion;
      c.clearAdvertisementList();
      service.gate.calls[0].answer.complete(_ads(<int>[501]));
      await _flush();
      expect(c.advertisementList, isNull);
      expect(updates, 0);
      expect(service.gate.calls, hasLength(1), reason: 'no follow-up network load for the stale module');

      c.getAdvertisementList();                                  // Fashion
      service.gate.calls[1].answer.complete(_ads(<int>[801]));
      await _flush();
      splash.active = _grocery;                                  // switch away while Fashion network is in flight
      c.clearAdvertisementList();
      final int before = updates;
      service.gate.calls[2].answer.complete(_ads(<int>[802]));   // late Fashion network
      await _flush();
      expect(c.advertisementList, isNull);
      expect(updates, before);
    });

    test('reload (another load) still refreshes the same module', () async {
      c.getAdvertisementList();
      service.gate.calls[0].answer.complete(_ads(<int>[1]));
      await _flush();
      service.gate.calls[1].answer.complete(_ads(<int>[2]));
      await _flush();
      c.getAdvertisementList();
      service.gate.calls[2].answer.complete(_ads(<int>[2]));
      await _flush();
      service.gate.calls[3].answer.complete(_ads(<int>[3]));
      await _flush();
      expect(c.advertisementList!.single.id, 3);
    });
  });

  // ---------------------------------------------------------------------------
  group('Advertisements — persistent cache survives a discarded result (real repository + drift)', () {
    final Directory tmp = Directory.systemTemp.createTempSync('moonjoin_e2b_ads_');
    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async => tmp.path,
      );
    });

    test('Grocery ads fetched while switching to Fashion are not shown, but are cached for Grocery and read back later', () async {
      final _GatedApiClient api = _GatedApiClient();
      final AdvertisementRepository repo = AdvertisementRepository(apiClient: api);
      final AdvertisementController c = AdvertisementController(
        advertisementServiceInterface: AdvertisementService(advertisementRepositoryInterface: repo),
      );

      // Grocery: cache read (empty) → network request goes out and is held.
      c.getAdvertisementList();
      for (int i = 0; i < 200 && api.pending.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(api.pending, hasLength(1));

      // User switches to Fashion before the Grocery answer arrives.
      splash.active = _fashion;
      c.clearAdvertisementList();
      api.pending.single.complete(Response(statusCode: 200, body: <Map<String, dynamic>>[<String, dynamic>{'id': 77, 'title': 'Grocery ad'}]));
      await _flush();
      expect(c.advertisementList, isNull, reason: 'the Grocery result is not applied on Fashion');

      // Back on Grocery, its cache holds the ad (written under Grocery's key).
      splash.active = _grocery;
      List<AdvertisementModel>? cached;
      for (int i = 0; i < 200 && (cached == null || cached.isEmpty); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        cached = await repo.getList(source: DataSourceEnum.local);
      }
      expect(cached!.single.id, 77);
    });
  });
}
