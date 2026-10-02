// Store-open waterfall. StoreScreen used to wait for stores/details before
// requesting the first-page products, store banners and recommended items. With
// a known store ID (promotional banner, store card) they now start together with
// the details; none of them reads the details. A slug link still waits: the
// details resolve the ID and move the user's address to the store first.
// Page 1 still asks for category 0: getStoreDetails resets the category index
// and the previous store before the products request is sent.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/category/controllers/category_controller.dart';
import 'package:moonjoin/features/category/domain/models/category_model.dart';
import 'package:moonjoin/features/category/domain/services/category_service_interface.dart';
import 'package:moonjoin/features/checkout/controllers/checkout_controller.dart';
import 'package:moonjoin/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/language/controllers/language_controller.dart';
import 'package:moonjoin/features/language/domain/service/language_service_interface.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/location/domain/services/location_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/models/recommended_product_model.dart';
import 'package:moonjoin/features/store/domain/models/store_banner_model.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';
import 'package:moonjoin/features/store/screens/store_screen.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}
class _CategoryService extends _NoSuch implements CategoryServiceInterface {}
class _CheckoutService extends _NoSuch implements CheckoutServiceInterface {}
class _LanguageService extends _NoSuch implements LanguageServiceInterface {}
class _LocationService extends _NoSuch implements LocationServiceInterface {}
class _AuthService extends _NoSuch implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;
  @override
  bool isLoggedIn() => true;
  @override
  bool isGuestLoggedIn() => false;
  @override
  String getUserCountryCode() => '+234';
}

/// Every store request in start order.
final List<String> _started = <String>[];

/// stores/details is held until the test answers it; the rest answer at once.
class _StoreService extends _NoSuch implements StoreServiceInterface {
  final List<Completer<Store?>> details = <Completer<Store?>>[];
  final List<String> detailSlugs = <String>[];

  @override
  Future<Store?> getStoreDetails(String storeID, bool fromCart, String slug, String languageCode, ModuleModel? module, int? cacheModuleId, int? moduleId) {
    _started.add('details($storeID)');
    detailSlugs.add(slug);
    final Completer<Store?> c = Completer<Store?>();
    details.add(c);
    return c.future;
  }

  @override
  Future<ItemModel?> getStoreItemList({int? storeID, required int offset, int? categoryID, String? type, List<String>? filter, int? rating, double? lowerValue, double? upperValue}) async {
    _started.add('items(store=$storeID,category=$categoryID,offset=$offset)');
    return null;
  }

  @override
  Future<List<StoreBannerModel>?> getStoreBannerList(int? storeId) async {
    _started.add('storeBanners($storeId)');
    return null;
  }

  @override
  Future<RecommendedItemModel?> getStoreRecommendedItemList(int? storeId) async {
    _started.add('recommended($storeId)');
    return null;
  }
}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  @override
  ModuleModel? get module => ModuleModel(id: 3, moduleType: 'food');
  @override
  ModuleModel? get cacheModule => ModuleModel(id: 3, moduleType: 'food');
}

class _Category extends CategoryController {
  _Category() : super(categoryServiceInterface: _CategoryService());
  List<CategoryModel>? categories;
  @override
  List<CategoryModel>? get categoryList => categories;
  @override
  Future<void> getCategoryList(bool reload, {bool allCategory = false, dynamic dataSource, bool fromRecall = false}) async => _started.add('categories');
}

class _Checkout extends CheckoutController {
  _Checkout() : super(checkoutServiceInterface: _CheckoutService());
  @override
  Future<void> initializeTimeSlot(Store store) async {}
  @override
  void setOrderType(String? type, {bool notify = true}) {}
  @override
  Future<double?> getDistanceInKM(LatLng originLatLng, LatLng destinationLatLng) async => null;
}

class _Localization extends LocalizationController {
  _Localization() : super(languageServiceInterface: _LanguageService());
  @override
  void loadCurrentLanguage() {}
}

class _Location extends LocationController {
  _Location() : super(locationServiceInterface: _LocationService());
  @override
  Future<void> setStoreAddressToUserAddress(LatLng storeAddress) async => _started.add('storeAddress');
}

Store _resolved(int id) => Store(id: id, latitude: '8.1', longitude: '4.2', delivery: true, categoryIds: <int>[]);

void main() {
  late _StoreService service;
  late StoreController store;
  late _Category category;

  setUp(() async {
    Get.testMode = true;
    _started.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userAddress: jsonEncode(<String, dynamic>{'latitude': '8.16', 'longitude': '4.25'}),
    });
    Get.put<SharedPreferences>(await SharedPreferences.getInstance());
    service = _StoreService();
    store = StoreController(storeServiceInterface: service);
    category = _Category();
    Get.put<AuthController>(AuthController(authServiceInterface: _AuthService()));
    Get.put<SplashController>(_Splash());
    Get.put<StoreController>(store);
    Get.put<CategoryController>(category);
    Get.put<CheckoutController>(_Checkout());
    Get.put<LocalizationController>(_Localization());
    Get.put<LocationController>(_Location());
  });

  tearDown(Get.reset);

  test('known store ID: products, store banners and recommended items start before stores/details answers', () async {
    bool done = false;
    final Future<void> load = StoreScreen.loadStoreData(9, fromModule: false).whenComplete(() => done = true);
    await pumpEventQueue();

    expect(_started.first, 'details(9)', reason: 'details still requested, first');
    expect(_started, containsAll(<String>['items(store=9,category=0,offset=1)', 'storeBanners(9)', 'recommended(9)']));
    expect(done, isFalse, reason: 'loadStoreData still waits for the details');
    expect(_started, isNot(contains('categories')), reason: 'category list still loads after the details');

    service.details.single.complete(_resolved(9));
    await load;
    expect(_started.last, 'categories', reason: 'missing category list loaded after the details, as before');
    expect(_started.where((String s) => s.startsWith('details')), hasLength(1));
    expect(_started.where((String s) => s.startsWith('items')), hasLength(1), reason: 'no second products request');
    expect(store.store?.id, 9);
  });

  test('slug link without an ID: the details resolve the ID (and store address) before any content request', () async {
    final Future<void> load = StoreScreen.loadStoreData(null, fromModule: false, slug: 'zona-pop');
    await pumpEventQueue();
    expect(_started, <String>['details(null)']);
    expect(service.detailSlugs.single, 'zona-pop');

    service.details.single.complete(_resolved(77));
    await load;
    expect(_started, containsAllInOrder(<String>['details(null)', 'storeAddress', 'categories', 'storeBanners(77)', 'recommended(77)', 'items(store=77,category=0,offset=1)']));
  });

  test('slug link with an ID: still sequential (address moves to the store first)', () async {
    final Future<void> load = StoreScreen.loadStoreData(9, fromModule: false, slug: 'zona-pop');
    await pumpEventQueue();
    expect(_started, <String>['details(9)']);

    service.details.single.complete(_resolved(9));
    await load;
    expect(_started, containsAllInOrder(<String>['details(9)', 'storeAddress', 'storeBanners(9)', 'items(store=9,category=0,offset=1)']));
  });

  test('page 1 asks for category 0 even when the previous store left a category selected', () async {
    // Previous store page: store A with category 42 selected.
    category.categories = <CategoryModel>[CategoryModel(id: 42, name: 'Ice Cream')];
    await store.getStoreDetails(Store(id: 1, name: 'A', categoryIds: <int>[42]), false);
    store.setCategoryList();
    store.setCategoryIndex(1);
    await pumpEventQueue();
    expect(_started.last, 'items(store=1,category=42,offset=1)', reason: 'precondition: category 42 selected on store A');
    _started.clear();

    final Future<void> load = StoreScreen.loadStoreData(9, fromModule: false);
    await pumpEventQueue();
    expect(_started, contains('items(store=9,category=0,offset=1)'));
    expect(_started.where((String s) => s.contains('category=42')), isEmpty, reason: 'no stale category from store A');

    service.details.single.complete(_resolved(9));
    await load;
    expect(_started, isNot(contains('categories')), reason: 'category list already loaded → not requested again');
  });

  test('details failure: content requests already made, loadStoreData completes, no stale store kept', () async {
    final Future<void> load = StoreScreen.loadStoreData(9, fromModule: false);
    await pumpEventQueue();
    service.details.single.complete(null);
    await load;
    expect(store.store, isNull);
    expect(_started.where((String s) => s.startsWith('items')), hasLength(1));
  });
}
