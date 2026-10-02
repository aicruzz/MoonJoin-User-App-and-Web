// customer/info startup waterfall. HomeScreen.loadData used to await
// getUserInfo() before starting Home requests that never read the profile.
// They now start alongside customer/info; getModules() still waits for it
// (module tiles → switchModule → _showInterestPage reads userInfoModel!), and
// loadData still completes only after customer/info and the pharmacy chain.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_checker.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/features/address/controllers/address_controller.dart';
import 'package:moonjoin/features/address/domain/services/address_service_interface.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/category/controllers/category_controller.dart';
import 'package:moonjoin/features/category/domain/services/category_service_interface.dart';
import 'package:moonjoin/features/coupon/controllers/coupon_controller.dart';
import 'package:moonjoin/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:moonjoin/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:moonjoin/features/flash_sale/domain/services/flash_sale_service_interface.dart';
import 'package:moonjoin/features/home/controllers/advertisement_controller.dart';
import 'package:moonjoin/features/home/domain/services/advertisement_service_interface.dart';
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
import 'package:moonjoin/features/profile/domain/services/profile_service_interface.dart';
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
  int clears = 0;
  int guestLogins = 0;
  @override
  bool isLoggedIn() => loggedIn;
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
}

class _Profile extends ProfileController {
  _Profile() : super(profileServiceInterface: _ProfileService());
  @override
  Future<void> getUserInfo() async {
    _started.add('customer/info');
    await _gate('customer/info');
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
  Future<void> getCategoryList(bool reload, {bool allCategory = false, dynamic dataSource, bool fromRecall = false}) async => _started.add('categories');
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

final ModuleModel _pharmacy = ModuleModel(id: 6, moduleType: AppConstants.pharmacy);
final ModuleModel _parcelModule = ModuleModel(id: 9, moduleType: AppConstants.parcel);

void main() {
  late _Splash splash;
  late _Auth auth;
  late _Favourite favourite;

  setUp(() {
    Get.testMode = true;
    _started.clear();
    _gates.clear();
    _unauthorized.clear();
    splash = _Splash();
    auth = _Auth();
    favourite = _Favourite();
    Get.put<SplashController>(splash);
    Get.put<AuthController>(auth);
    Get.put<FavouriteController>(favourite);
    Get.put<ProfileController>(_Profile());
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

  test('All Module landing, logged in: independent requests start while customer/info is pending; modules waits for it', () async {
    final load = start();
    await pumpEventQueue();

    expect(_started, containsAll(<String>['customer/info', 'notifications', 'coupons', 'featuredBanner', 'featuredStores', 'addressList']));
    expect(_started, isNot(contains('modules')), reason: 'getModules waits for customer/info (_showInterestPage reads userInfoModel!)');
    expect(load.done(), isFalse, reason: 'loadData waits for customer/info');
    expect(_started.where((String s) => s == 'customer/info'), hasLength(1), reason: 'one customer/info');

    _gates['customer/info']!.complete();
    await load.future;
    expect(_started.last, 'modules');
    expect(_started.where((String s) => s == 'customer/info'), hasLength(1));
  });

  test('Pharmacy, logged in: pharmacy chain starts with customer/info; loadData waits for both', () async {
    splash.active = _pharmacy;
    final load = start();
    await pumpEventQueue();

    expect(_started, containsAll(<String>['customer/info', 'notifications', 'coupons', 'basicMedicine', 'featuredStores', 'commonConditions']));
    expect(_started, isNot(contains('modules')));

    _gates['customer/info']!.complete();
    await pumpEventQueue();
    expect(_started, contains('modules'), reason: 'modules starts right after customer/info');
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
    expect(_started, isNot(contains('modules')));
    expect(load.done(), isFalse, reason: 'loadData waits for customer/info');

    _gates['customer/info']!.complete();
    await load.future;
    expect(_started.last, 'modules');
  });

  test('Parcel, logged in: parcel categories start while customer/info is pending', () async {
    splash.active = _parcelModule;
    splash.parcel = true;
    final load = start();
    await pumpEventQueue();
    expect(_started, containsAll(<String>['customer/info', 'parcelCategories']));
    expect(_started, isNot(contains('modules')));
    _gates['customer/info']!.complete();
    await load.future;
    expect(_started.last, 'modules');
  });

  test('guest: no customer/info, no notifications/coupons/address; modules started in its original place', () async {
    auth.loggedIn = false;
    await HomeScreen.loadData(false);
    expect(_started, isNot(contains('customer/info')));
    expect(_started, isNot(contains('notifications')));
    expect(_started, isNot(contains('coupons')));
    expect(_started, isNot(contains('addressList')));
    expect(_started, containsAllInOrder(<String>['modules', 'featuredBanner', 'featuredStores']));
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
}
