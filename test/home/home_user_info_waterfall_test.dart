// customer/info startup waterfall. HomeScreen.loadData used to await
// getUserInfo() before starting Home requests that never read the profile.
// They now start alongside customer/info — getModules() included, so the All
// Module landing (the cold-start screen on mobile) renders without waiting for
// the profile. loadData still completes only after customer/info and the
// pharmacy chain. A module tapped before the profile arrives joins the request
// Home started (no second customer/info) and evaluates the interest page once
// it answers; with no profile the decision is skipped instead of throwing.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_checker.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/address/controllers/address_controller.dart';
import 'package:moonjoin/features/address/domain/services/address_service_interface.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/category/controllers/category_controller.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/category/domain/services/category_service_interface.dart';
import 'package:moonjoin/features/coupon/controllers/coupon_controller.dart';
import 'package:moonjoin/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:moonjoin/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:moonjoin/features/flash_sale/domain/services/flash_sale_service_interface.dart';
import 'package:moonjoin/features/home/controllers/advertisement_controller.dart';
import 'package:moonjoin/features/home/controllers/home_controller.dart';
import 'package:moonjoin/features/home/domain/services/advertisement_service_interface.dart';
import 'package:moonjoin/features/home/domain/services/home_service_interface.dart';
import 'package:moonjoin/features/home/screens/home_screen.dart';
import 'package:moonjoin/features/item/controllers/campaign_controller.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/common_condition_model.dart';
import 'package:moonjoin/features/item/domain/services/campaign_service_interface.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/location/domain/services/location_service_interface.dart';
import 'package:moonjoin/features/notification/controllers/notification_controller.dart';
import 'package:moonjoin/features/notification/domain/service/notification_service_interface.dart';
import 'package:moonjoin/features/parcel/controllers/parcel_controller.dart';
import 'package:moonjoin/features/parcel/domain/services/parcel_service_interface.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/profile/domain/models/userinfo_model.dart';
import 'package:moonjoin/features/profile/domain/services/profile_service_interface.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/domain/services/taxi_cart_service_interface.dart';
import 'package:moonjoin/features/rental_module/rental_favourite/controllers/taxi_favourite_controller.dart';
import 'package:moonjoin/features/rental_module/rental_favourite/domain/services/taxi_favourite_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';
import 'package:moonjoin/util/app_constants.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}
class _LocationService extends _NoSuch implements LocationServiceInterface {}
class _FlashService extends _NoSuch implements FlashSaleServiceInterface {}
class _StoreService extends _NoSuch implements StoreServiceInterface {}
class _BannerService extends _NoSuch implements BannerServiceInterface {}
class _ItemService extends _NoSuch implements ItemServiceInterface {}
class _CategoryService extends _NoSuch implements CategoryServiceInterface {}
class _CampaignService extends _NoSuch implements CampaignServiceInterface {}
class _AdService extends _NoSuch implements AdvertisementServiceInterface {}
class _ProfileService extends _NoSuch implements ProfileServiceInterface {}
class _NotificationService extends _NoSuch implements NotificationServiceInterface {}
class _CouponService extends _NoSuch implements CouponServiceInterface {}
class _AddressService extends _NoSuch implements AddressServiceInterface {}
class _ParcelService extends _NoSuch implements ParcelServiceInterface {}
class _FavouriteService extends _NoSuch implements FavouriteServiceInterface {}
class _CartService extends _NoSuch implements CartServiceInterface {}
class _HomeService extends _NoSuch implements HomeServiceInterface {}
class _TaxiCartService extends _NoSuch implements TaxiCartServiceInterface {}
class _TaxiFavouriteService extends _NoSuch implements TaxiFavouriteServiceInterface {}
class _AuthService extends _NoSuch implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;
}

/// Every Home load in start order.
final List<String> _started = <String>[];

/// Requests held until the test answers them.
final Map<String, Completer<void>> _gates = <String, Completer<void>>{};
Future<void> _gate(String name) => (_gates[name] = Completer<void>()).future;

/// Requests that answer 401 through the real ApiChecker (as ApiClient.handleResponse does).
final Set<String> _unauthorized = <String>{};
Future<void> _request(String name) async {
  _started.add(name);
  if (_unauthorized.contains(name)) {
    await _gate(name);
    ApiChecker.checkApi(const Response(statusCode: 401, statusText: 'Unauthenticated.'));
  }
}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  ModuleModel? active;
  bool parcel = false;
  @override
  ModuleModel? get module => active;
  @override
  ConfigModel? get configModel => ConfigModel(moduleConfig: ModuleConfig(module: Module(isParcel: parcel, isTaxi: false)));
  @override
  Future<void> getModules({Map<String, String>? headers, dynamic dataSource}) async => _started.add('modules');
}

class _Auth extends AuthController {
  _Auth() : super(authServiceInterface: _AuthService());
  bool loggedIn = true;
  bool guest = false;
  int clears = 0;
  int guestLogins = 0;
  @override
  bool isLoggedIn() => loggedIn;
  @override
  bool isGuestLoggedIn() => guest && !loggedIn;
  @override
  Future<bool> clearSharedData({bool removeToken = true}) async {
    clears++;
    loggedIn = false;
    await guestLogin();
    return true;
  }
  @override
  Future<ResponseModel> guestLogin() async {
    guestLogins++;
    return ResponseModel(true, '1');
  }
}

class _Favourite extends FavouriteController {
  _Favourite() : super(favouriteServiceInterface: _FavouriteService());
  int removes = 0;
  @override
  void removeFavourite() => removes++;
  @override
  Future<void> getFavouriteList() async => _started.add('favourites');
}

class _Profile extends ProfileController {
  _Profile() : super(profileServiceInterface: _ProfileService());
  /// What customer/info yields once its gate is answered (null = failed).
  UserInfoModel? answer;
  UserInfoModel? loaded;
  @override
  UserInfoModel? get userInfoModel => loaded;
  @override
  Future<void> getUserInfo() async {
    _started.add('customer/info');
    await _gate('customer/info');
    loaded = answer ?? loaded;
    if (_unauthorized.contains('customer/info')) {
      ApiChecker.checkApi(const Response(statusCode: 401, statusText: 'Unauthenticated.'));
    }
  }
}

class _Notification extends NotificationController {
  _Notification() : super(notificationServiceInterface: _NotificationService());
  @override
  Future<int> getNotificationList(bool reload) async {
    await _request('notifications');
    return 0;
  }
}

class _Coupon extends CouponController {
  _Coupon() : super(couponServiceInterface: _CouponService());
  @override
  Future<void> getCouponList() => _request('coupons');
}

class _Address extends AddressController {
  _Address() : super(addressServiceInterface: _AddressService());
  @override
  Future<void> getAddressList() async => _started.add('addressList');
}

class _Parcel extends ParcelController {
  _Parcel() : super(parcelServiceInterface: _ParcelService());
  @override
  Future<void> getParcelCategoryList() async => _started.add('parcelCategories');
}

class _Location extends LocationController {
  _Location() : super(locationServiceInterface: _LocationService());
  @override
  Future<void> syncZoneData() async => _started.add('zoneSync');
}

class _Flash extends FlashSaleController {
  _Flash() : super(flashSaleServiceInterface: _FlashService());
  @override
  void setEmptyFlashSale({bool fromModule = false}) {}
  @override
  Future<void> getFlashSale(bool reload, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _started.add('flashSale');
}

class _Store extends StoreController {
  _Store() : super(storeServiceInterface: _StoreService());
  @override
  Future<void> getVisitAgainStoreList({bool fromModule = false, dynamic dataSource, bool fromRecall = false}) async => _started.add('visitAgain');
  @override
  Future<void> getRecommendedStoreList({dynamic dataSource, bool fromRecall = false}) async => _started.add('recommendedStores');
  @override
  Future<void> getPopularStoreList(bool reload, String type, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _started.add('popularStores');
  @override
  Future<void> getLatestStoreList(bool reload, String type, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _started.add('latestStores');
  @override
  Future<void> getTopOfferStoreList(bool reload, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _started.add('topOfferStores');
  @override
  Future<void> getStoreList(int offset, bool reload, {dynamic source}) async => _started.add('storeGrid');
  @override
  Future<void> getFeaturedStoreList({dynamic dataSource}) async => _started.add('featuredStores');
}

class _Banner extends BannerController {
  _Banner() : super(bannerServiceInterface: _BannerService());
  @override
  Future<void> getBannerList(bool reload, {dynamic dataSource, bool fromRecall = false}) async => _started.add('banners');
  @override
  Future<void> getPromotionalBannerList(bool reload) async => _started.add('promotionalBanner');
  @override
  Future<void> getFeaturedBanner() async => _started.add('featuredBanner');
}

class _Item extends ItemController {
  _Item() : super(itemServiceInterface: _ItemService());
  List<CommonConditionModel>? conditions;
  @override
  List<CommonConditionModel>? get commonConditions => conditions;
  @override
  Future<void> getDiscountedItemList({required String offset, dynamic dataSource, bool notify = false, bool firstTimeCategoryLoad = false}) async => _started.add('discountedItems');
  @override
  Future<void> getPopularItemList({required String offset, dynamic dataSource, bool notify = false, bool firstTimeCategoryLoad = false}) async => _started.add('popularItems');
  @override
  Future<void> getReviewedItemList({required String offset, dynamic dataSource, bool notify = false, bool firstTimeCategoryLoad = false}) async => _started.add('reviewedItems');
  @override
  Future<void> getRecommendedItemList(bool reload, String type, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _started.add('recommendedItems');
  @override
  Future<void> getBasicMedicine(bool reload, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _started.add('basicMedicine');
  @override
  Future<void> getCommonConditions(bool notify) async {
    _started.add('commonConditions');
    await _gate('commonConditions');
    conditions = <CommonConditionModel>[CommonConditionModel(id: 4)];
  }
  @override
  Future<void> getConditionsWiseItem(int id, bool notify) async => _started.add('conditionItems($id)');
}

class _Category extends CategoryController {
  _Category() : super(categoryServiceInterface: _CategoryService());
  @override
  Future<void> getCategoryList(bool reload, {bool allCategory = false, dynamic dataSource, bool fromRecall = false}) async => _started.add('categories(reload=$reload)');
}

class _Campaign extends CampaignController {
  _Campaign() : super(campaignServiceInterface: _CampaignService());
  @override
  Future<void> getBasicCampaignList(bool reload, {dynamic dataSource, bool fromRecall = false}) async => _started.add('basicCampaigns');
  @override
  Future<void> getItemCampaignList(bool reload, {dynamic dataSource, bool fromRecall = false}) async => _started.add('itemCampaigns');
}

class _Ads extends AdvertisementController {
  _Ads() : super(advertisementServiceInterface: _AdService());
  @override
  Future<void> getAdvertisementList({dynamic dataSource}) async => _started.add('ads');
}

class _Cart extends CartController {
  _Cart() : super(cartServiceInterface: _CartService());
  @override
  Future<void> getCartDataOnline() async => _started.add('cart');
}

class _HomeCtl extends HomeController {
  _HomeCtl() : super(homeServiceInterface: _HomeService());
  @override
  Future<void> getCashBackOfferList() async => _started.add('cashback');
}

final List<ModuleModel> _allModules = <ModuleModel>[
  ModuleModel(id: 3, moduleType: AppConstants.food), ModuleModel(id: 5, moduleType: AppConstants.grocery),
  ModuleModel(id: 12, moduleType: AppConstants.parcel), ModuleModel(id: 9, moduleType: AppConstants.pharmacy),
  ModuleModel(id: 14, moduleType: AppConstants.taxi),
];

class _TaxiCart extends TaxiCartController {
  _TaxiCart() : super(taxiCartServiceInterface: _TaxiCartService());
  @override
  Future<bool> getCarCartList() async {
    _started.add('taxiCart');
    return true;
  }
}

class _TaxiFavourite extends TaxiFavouriteController {
  _TaxiFavourite() : super(taxiFavouriteServiceInterface: _TaxiFavouriteService());
  @override
  Future<void> getFavouriteTaxiList() async => _started.add('taxiFavourites');
}

/// The module list from the local cache (and later the network), as the
/// real repository serves it.
class _SwitchSplashService extends _NoSuch implements SplashServiceInterface {
  @override
  Future<List<ModuleModel>?> getModules({Map<String, String>? headers, required DataSourceEnum source}) async {
    _started.add(source == DataSourceEnum.local ? 'modules(cache)' : 'modules(network)');
    return _allModules;
  }
  @override
  Future<void> setModule(ModuleModel? module) async {}
  @override
  Future<ModuleModel?> setCacheModule(ModuleModel? module) async => module;
}

/// Real SplashController (getModules / setModule / switchModule / interest
/// page); only the config is pinned.
class _SwitchSplash extends SplashController {
  _SwitchSplash() : super(splashServiceInterface: _SwitchSplashService());
  @override
  ConfigModel? get configModel => ConfigModel(moduleConfig: ModuleConfig(module: Module(isParcel: module?.moduleType == AppConstants.parcel, isTaxi: false)));
}

final ModuleModel _pharmacy = ModuleModel(id: 6, moduleType: AppConstants.pharmacy);
final ModuleModel _parcelModule = ModuleModel(id: 9, moduleType: AppConstants.parcel);

void main() {
  late _Splash splash;
  late _Auth auth;
  late _Favourite favourite;
  late _Profile profile;

  setUp(() {
    Get.testMode = true;
    _started.clear();
    _gates.clear();
    _unauthorized.clear();
    HomeScreen.profileLoad = null;
    splash = _Splash();
    auth = _Auth();
    favourite = _Favourite();
    profile = _Profile();
    Get.put<SplashController>(splash);
    Get.put<AuthController>(auth);
    Get.put<FavouriteController>(favourite);
    Get.put<ProfileController>(profile);
    Get.put<NotificationController>(_Notification());
    Get.put<CouponController>(_Coupon());
    Get.put<AddressController>(_Address());
    Get.put<ParcelController>(_Parcel());
    Get.put<LocationController>(_Location());
    Get.put<FlashSaleController>(_Flash());
    Get.put<StoreController>(_Store());
    Get.put<BannerController>(_Banner());
    Get.put<ItemController>(_Item());
    Get.put<CategoryController>(_Category());
    Get.put<CampaignController>(_Campaign());
    Get.put<AdvertisementController>(_Ads());
  });

  tearDown(Get.reset);

  /// Tracks whether the loadData future has completed.
  ({Future<void> future, bool Function() done}) start() {
    bool completed = false;
    final Future<void> f = HomeScreen.loadData(false).whenComplete(() => completed = true);
    return (future: f, done: () => completed);
  }

  int count(String name) => _started.where((String s) => s == name).length;

  test('All Module landing, logged in: modules and the independent requests start while customer/info is pending; loadData waits for it', () async {
    final load = start();
    await pumpEventQueue();

    expect(_started, containsAll(<String>['customer/info', 'modules', 'notifications', 'coupons', 'featuredBanner', 'featuredStores', 'addressList']));
    expect(load.done(), isFalse, reason: 'loadData waits for customer/info');
    expect(count('customer/info'), 1, reason: 'one customer/info');

    _gates['customer/info']!.complete();
    await load.future;
    expect(count('customer/info'), 1);
    expect(count('modules'), 1, reason: 'getModules started once, not again after the profile');
  });

  test('Pharmacy, logged in: modules + pharmacy chain start with customer/info; loadData waits for both', () async {
    splash.active = _pharmacy;
    final load = start();
    await pumpEventQueue();

    expect(_started, containsAll(<String>['customer/info', 'modules', 'notifications', 'coupons', 'basicMedicine', 'featuredStores', 'commonConditions']));

    _gates['customer/info']!.complete();
    await pumpEventQueue();
    expect(load.done(), isFalse, reason: 'loadData still waits for the pharmacy chain');
    expect(_started, isNot(contains('conditionItems(4)')));

    _gates['commonConditions']!.complete();
    await load.future;
    expect(_started.last, 'conditionItems(4)', reason: 'pharmacy chain order preserved');
  });

  test('Pharmacy: customer/info finishing last still gates loadData', () async {
    splash.active = _pharmacy;
    final load = start();
    await pumpEventQueue();
    _gates['commonConditions']!.complete();
    await pumpEventQueue();
    expect(_started, contains('conditionItems(4)'));
    expect(load.done(), isFalse, reason: 'loadData waits for customer/info');

    _gates['customer/info']!.complete();
    await load.future;
    expect(load.done(), isTrue);
  });

  test('Parcel, logged in: parcel categories and modules start while customer/info is pending', () async {
    splash.active = _parcelModule;
    splash.parcel = true;
    final load = start();
    await pumpEventQueue();
    expect(_started, containsAll(<String>['customer/info', 'modules', 'parcelCategories']));
    expect(load.done(), isFalse);
    _gates['customer/info']!.complete();
    await load.future;
  });

  test('guest: no customer/info, no notifications/coupons/address; modules started in its original place', () async {
    auth.loggedIn = false;
    await HomeScreen.loadData(false);
    expect(_started, isNot(contains('customer/info')));
    expect(_started, isNot(contains('notifications')));
    expect(_started, isNot(contains('coupons')));
    expect(_started, isNot(contains('addressList')));
    expect(_started, containsAllInOrder(<String>['modules', 'featuredBanner', 'featuredStores']));
    expect(HomeScreen.profileLoad, isNull);
  });

  testWidgets('concurrent 401s on customer/info + notifications + coupons → exactly one session recovery', (WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/start',
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/start', page: () => const Scaffold(body: Text('start'))),
        GetPage<dynamic>(name: '/', page: () => const Scaffold(body: Text('initial'))),
      ],
    ));
    _unauthorized.addAll(<String>['customer/info', 'notifications', 'coupons']);

    final Future<void> load = HomeScreen.loadData(false);
    await tester.pump();
    expect(_started, containsAll(<String>['customer/info', 'notifications', 'coupons']));

    _gates['customer/info']!.complete();
    _gates['notifications']!.complete();
    _gates['coupons']!.complete();
    await tester.pumpAndSettle();
    await load;

    expect(auth.clears, 1);
    expect(auth.guestLogins, 1);
    expect(favourite.removes, 1);
    expect(find.text('initial'), findsOneWidget);
    expect(ApiChecker.sessionRecovery, isNull, reason: 'guard released');
  });

  group('early module tap (real SplashController.switchModule)', () {
    late _SwitchSplash switchSplash;
    final ModuleModel food = _allModules[0];

    setUp(() {
      Get.delete<SplashController>(force: true);
      switchSplash = _SwitchSplash();
      Get.put<SplashController>(switchSplash);
      Get.put<CartController>(_Cart());
      Get.put<HomeController>(_HomeCtl());
    });

    /// The interest decision ran (its category check) before the switch's own Home load.
    bool interestEvaluated() {
      final int interest = _started.indexOf('categories(reload=true)');
      final int switchLoad = _started.lastIndexOf('zoneSync');
      return interest != -1 && interest < switchLoad;
    }

    test('cached modules: the landing tiles are available while customer/info is pending', () async {
      final load = start();
      await pumpEventQueue();
      expect(_started, contains('modules(cache)'));
      expect(switchSplash.moduleList, isNotEmpty, reason: 'All Module landing renders without the profile');
      expect(load.done(), isFalse);
      _gates['customer/info']!.complete();
      await load.future;
    });

    test('tap while the profile is pending: joins the in-flight customer/info, then the same interest decision runs', () async {
      final load = start();
      await pumpEventQueue();
      profile.answer = UserInfoModel(selectedModuleForInterest: <int>[]); // Food not chosen yet → interest page

      final Future<void> tap = switchSplash.switchModule(0, true);
      await pumpEventQueue();
      expect(switchSplash.module?.id, food.id);
      expect(count('customer/info'), 1, reason: 'no second customer/info for the tap');
      expect(count('zoneSync'), 1, reason: 'the switch waits for the profile before its Home load');
      expect(_started, isNot(contains('categories(reload=true)')));

      _gates['customer/info']!.complete();
      await tap;
      expect(interestEvaluated(), isTrue, reason: 'interest decision evaluated once the profile arrived');
      expect(count('zoneSync'), 2, reason: 'the switch continued into its Home load');
      await load.future;
    });

    test('tap while pending, module already chosen: no interest page, switch continues', () async {
      final load = start();
      await pumpEventQueue();
      profile.answer = UserInfoModel(selectedModuleForInterest: <int>[food.id!]);

      final Future<void> tap = switchSplash.switchModule(0, true);
      await pumpEventQueue();
      _gates['customer/info']!.complete();
      await tap;
      expect(interestEvaluated(), isFalse);
      expect(count('zoneSync'), 2);
      await load.future;
    });

    test('profile already loaded before the tap: decision runs at once, unchanged', () async {
      final load = start();
      await pumpEventQueue();
      profile.answer = UserInfoModel(selectedModuleForInterest: <int>[]);
      _gates['customer/info']!.complete();
      await load.future;

      await switchSplash.switchModule(0, true);
      expect(interestEvaluated(), isTrue);
      expect(count('zoneSync'), 2);
    });

    test('tap while pending and customer/info fails: no null exception, interest skipped, switch continues', () async {
      final load = start();
      await pumpEventQueue();
      profile.answer = null; // failed lookup: userInfoModel stays null

      final Future<void> tap = switchSplash.switchModule(0, true);
      await pumpEventQueue();
      _gates['customer/info']!.complete();
      await tap; // used to throw on userInfoModel!
      expect(interestEvaluated(), isFalse);
      expect(count('zoneSync'), 2, reason: 'Home still loads for the new module');
      await load.future;
    });

    test('early Package Delivery tap: no wait for customer/info — the switch loads parcel categories at once', () async {
      final load = start();
      await pumpEventQueue();
      final Completer<void> launchProfile = _gates['customer/info']!;

      final Future<void> tap = switchSplash.switchModule(2, true); // Package Delivery (parcel)
      await tap;
      expect(launchProfile.isCompleted, isFalse, reason: 'launch customer/info still pending');
      expect(count('zoneSync'), 2, reason: 'the switch went straight into its Home load');
      expect(_started, contains('parcelCategories'));
      expect(interestEvaluated(), isFalse, reason: 'no interest page for parcel');

      launchProfile.complete();
      _gates['customer/info']!.complete(); // the switch's own Home load
      await load.future;
    });

    test('early Pharmacy tap: no wait for customer/info — the pharmacy chain starts at once', () async {
      final load = start();
      await pumpEventQueue();
      final Completer<void> launchProfile = _gates['customer/info']!;

      final Future<void> tap = switchSplash.switchModule(3, true); // Pharmacy
      await tap;
      expect(launchProfile.isCompleted, isFalse, reason: 'launch customer/info still pending');
      expect(count('zoneSync'), 2, reason: 'the switch went straight into its Home load');
      expect(_started, containsAll(<String>['basicMedicine', 'commonConditions']));
      expect(interestEvaluated(), isFalse, reason: 'no interest page for pharmacy');

      launchProfile.complete();
      _gates['customer/info']!.complete();
      _gates['commonConditions']!.complete();
      await load.future;
    });

    test('tap after a failed customer/info (nothing in flight): no exception, switch continues', () async {
      final load = start();
      await pumpEventQueue();
      _gates['customer/info']!.complete();
      await load.future;
      expect(profile.userInfoModel, isNull);

      await switchSplash.switchModule(0, true);
      expect(interestEvaluated(), isFalse);
      expect(count('zoneSync'), 2);
      expect(count('customer/info'), 2, reason: 'only the switch\'s own Home load requests it, as before');
    });
  });

  group('module switch refreshes cart/cashback once (setModule only)', () {
    late _SwitchSplash switchSplash;

    setUp(() async {
      Get.delete<SplashController>(force: true);
      switchSplash = _SwitchSplash();
      Get.put<SplashController>(switchSplash);
      Get.put<CartController>(_Cart());
      Get.put<HomeController>(_HomeCtl());
      Get.put<TaxiCartController>(_TaxiCart());
      Get.put<TaxiFavouriteController>(_TaxiFavourite());
      // Profile already loaded, Food and Grocery already chosen: no interest page.
      profile.loaded = UserInfoModel(selectedModuleForInterest: <int>[3, 5]);
      await switchSplash.getModules();
      await pumpEventQueue();
      _started.clear();
    });

    test('logged in: switching module requests cart, cashback and favourites once each; Home loads', () async {
      await switchSplash.switchModule(0, true); // Food
      await pumpEventQueue();
      expect(switchSplash.module?.id, 3);
      expect(count('cart'), 1, reason: 'switchModule used to request the cart again');
      expect(count('cashback'), 1, reason: 'switchModule used to request the cashback offers again');
      expect(count('favourites'), 1);
      expect(count('zoneSync'), 1, reason: 'the switch still loads Home for the new module');
    });

    test('switching away and back: one refresh per switch, both directions', () async {
      await switchSplash.switchModule(0, true); // Food
      await switchSplash.switchModule(1, true); // Grocery
      await switchSplash.switchModule(0, true); // Food again
      await pumpEventQueue();
      expect(switchSplash.module?.id, 3);
      expect(count('cart'), 3);
      expect(count('cashback'), 3);
      expect(count('favourites'), 3);
      expect(count('zoneSync'), 3);
    });

    test('guest: cart refreshed once; no cashback or favourites', () async {
      auth.loggedIn = false;
      auth.guest = true;
      await switchSplash.switchModule(1, true); // Grocery
      await pumpEventQueue();
      expect(count('cart'), 1);
      expect(count('cashback'), 0);
      expect(count('favourites'), 0);
      expect(count('zoneSync'), 1);
    });

    test('neither logged in nor guest: no cart request (it had no guest id to send)', () async {
      auth.loggedIn = false;
      await switchSplash.switchModule(1, true);
      await pumpEventQueue();
      expect(count('cart'), 0);
      expect(count('cashback'), 0);
      expect(count('zoneSync'), 1);
    });

    test('rental (taxi): cashback once; taxi cart and favourites unchanged', () async {
      await switchSplash.switchModule(4, true);
      await pumpEventQueue();
      expect(switchSplash.module?.id, 14);
      expect(count('cashback'), 1, reason: 'the taxi branch used to request it again');
      expect(count('cart'), 1);
      expect(count('taxiFavourites'), 1);
      expect(count('taxiCart'), 2, reason: 'out of scope: setModule and switchModule each still load the taxi cart');
      expect(count('zoneSync'), 0, reason: 'taxi does not reload Home here, as before');
    });

    test('setModule on its own is unchanged: cart, cashback and favourites', () async {
      await switchSplash.setModule(_allModules[1]);
      await pumpEventQueue();
      expect(count('cart'), 1);
      expect(count('cashback'), 1);
      expect(count('favourites'), 1);
    });

    test('tapping the active module again does nothing, as before', () async {
      await switchSplash.switchModule(0, true);
      await pumpEventQueue();
      _started.clear();
      await switchSplash.switchModule(0, true);
      await pumpEventQueue();
      expect(_started, isEmpty);
    });
  });
}
