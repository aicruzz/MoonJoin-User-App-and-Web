// Address save → one Home navigation. For a logged-in user with no module
// selected, _saveDataAndFirebaseConfig refreshed the config with getConfigData(),
// whose splash routing (cached and network config) navigated to Home a second
// time ('/?from-splash=true', a new Dashboard/Home + Home load) and posted the
// FCM token twice — on top of the flow's own handleRoute navigation. The address
// save now refreshes the config with routeAfterLoad: false: config still parsed
// and applied (single-module setModule, update/maintenance redirect), no splash
// user routing. Every other getConfigData caller keeps the default routing.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/address/controllers/address_controller.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/features/address/domain/services/address_service_interface.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/checkout/controllers/checkout_controller.dart';
import 'package:moonjoin/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:moonjoin/features/coupon/controllers/coupon_controller.dart';
import 'package:moonjoin/features/coupon/domain/services/coupon_service_interface.dart';
import 'package:moonjoin/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:moonjoin/features/flash_sale/domain/services/flash_sale_service_interface.dart';
import 'package:moonjoin/features/language/controllers/language_controller.dart';
import 'package:moonjoin/features/language/domain/service/language_service_interface.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/location/domain/models/zone_response_model.dart';
import 'package:moonjoin/features/location/domain/services/location_service_interface.dart';
import 'package:moonjoin/features/notification/controllers/notification_controller.dart';
import 'package:moonjoin/features/notification/domain/service/notification_service_interface.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/profile/domain/services/profile_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _CartService extends _NoSuch implements CartServiceInterface {}
class _CheckoutService extends _NoSuch implements CheckoutServiceInterface {}
class _LanguageService extends _NoSuch implements LanguageServiceInterface {}
class _FlashService extends _NoSuch implements FlashSaleServiceInterface {}
class _StoreService extends _NoSuch implements StoreServiceInterface {}
class _BannerService extends _NoSuch implements BannerServiceInterface {}
class _ProfileService extends _NoSuch implements ProfileServiceInterface {}
class _NotificationService extends _NoSuch implements NotificationServiceInterface {}
class _CouponService extends _NoSuch implements CouponServiceInterface {}
class _AddressService extends _NoSuch implements AddressServiceInterface {}
class _AuthService extends _NoSuch implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;
}

/// Every observable action, in order.
final List<String> _log = <String>[];

Map<String, dynamic> _config({bool maintenance = false, Map<String, dynamic>? singleModule}) => <String, dynamic>{
      'maintenance_mode': maintenance,
      'app_minimum_version_android': 0,
      'app_minimum_version_ios': 0,
      'module_config': <String, dynamic>{'module_type': <String>['grocery'], 'grocery': <String, dynamic>{'order_place_to_schedule_interval': false}},
      'module': ?singleModule,
    };

/// Cached and network config both answer with [config].
class _SplashService extends _NoSuch implements SplashServiceInterface {
  Map<String, dynamic> config = _config();
  @override
  bool? showIntro() => false;
  @override
  Future<Response> getConfigData({required DataSourceEnum source}) async {
    _log.add('config(${source.name})');
    return Response(statusCode: 200, body: config);
  }
}

/// Real getConfigData / _handleConfigResponse / route; setModule recorded.
class _Splash extends SplashController {
  _Splash(_SplashService service) : super(splashServiceInterface: service);
  @override
  Future<void> setModule(ModuleModel? module, {bool notify = true}) async => _log.add('setModule(${module?.id})');
}

class _Auth extends AuthController {
  _Auth() : super(authServiceInterface: _AuthService());
  bool loggedIn = true;
  @override
  bool isLoggedIn() => loggedIn;
  @override
  bool isGuestLoggedIn() => !loggedIn;
  @override
  Future<void> updateToken() async => _log.add('updateToken');
  @override
  Future<void> updateZone() async => _log.add('updateZone');
  @override
  String getUserCountryCode() => '+234';
}

class _Pushes extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _log.add('push ${route.settings.name}');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _log.add('push ${newRoute?.settings.name}');
}

int _count(String prefix) => _log.where((String e) => e.startsWith(prefix)).length;

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(GetMaterialApp(
    initialRoute: '/start',
    navigatorObservers: <NavigatorObserver>[_Pushes()],
    getPages: <GetPage<dynamic>>[
      GetPage<dynamic>(name: '/start', page: () => const Scaffold(body: Text('address sheet'))),
      GetPage<dynamic>(name: RouteHelper.initial, page: () => const Scaffold(body: Text('home'))),
      GetPage<dynamic>(name: RouteHelper.update, page: () => const Scaffold(body: Text('update'))),
    ],
  ));
  _log.clear();
}

Future<void> _prefsWithAddress() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    AppConstants.userAddress: jsonEncode(<String, dynamic>{'latitude': '8.16', 'longitude': '4.25', 'zone_id': 7, 'zone_ids': <int>[7]}),
  });
  Get.put<SharedPreferences>(await SharedPreferences.getInstance());
}

// ── address-save flow doubles ───────────────────────────────────────────────

/// Saving the address updates the request headers.
class _ApiClient extends GetxService implements ApiClient {
  @override
  Map<String, String> updateHeader(String? token, List<int>? zoneIDs, List<int>? operationIds, String? languageCode, int? moduleID, String? latitude, String? longitude, {bool setHeader = true}) => <String, String>{};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records the getConfigData call the address save makes.
class _FlowSplash extends SplashController {
  _FlowSplash() : super(splashServiceInterface: _SplashService());
  ModuleModel? active;
  final List<bool> configRefreshes = <bool>[];
  @override
  ModuleModel? get module => active;
  @override
  ConfigModel? get configModel => ConfigModel(moduleConfig: ModuleConfig(module: Module(isParcel: false, isTaxi: false)));
  @override
  Future<void> getConfigData({dynamic notificationBody, bool loadModuleData = false, bool loadLandingData = false, dynamic source, bool fromMainFunction = false, bool fromDemoReset = false, bool routeAfterLoad = true}) async {
    configRefreshes.add(routeAfterLoad);
    _log.add('getConfigData(routeAfterLoad: $routeAfterLoad)');
  }
  @override
  Future<void> getModules({Map<String, String>? headers, dynamic dataSource}) async => _log.add('home:modules');
}

class _FlowLocationService extends _NoSuch implements LocationServiceInterface {
  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng, {bool handleError = false}) async =>
      ZoneResponseModel(true, '', <int>[7], <ZoneData>[ZoneData(id: 7, status: 1)], <int>[], 200);
  @override
  void configureFirebaseMessaging(AddressModel address) => _log.add('configureFirebaseMessaging');
  @override
  void handleRoute(bool fromSignUp, String? route, bool canRoute) => _log.add('handleRoute');
}

class _FlowLocation extends LocationController {
  _FlowLocation() : super(locationServiceInterface: _FlowLocationService());
  @override
  Future<bool> checkInternet() async => true;
  @override
  Future<void> syncZoneData() async => _log.add('home:loadData'); // first thing HomeScreen.loadData does
}

class _Cart extends CartController {
  _Cart() : super(cartServiceInterface: _CartService());
  @override
  Future<void> getCartDataOnline() async {}
}

class _Checkout extends CheckoutController {
  _Checkout() : super(checkoutServiceInterface: _CheckoutService());
  @override
  void clearPrevData() => _log.add('clearPrevData');
}

class _Localization extends LocalizationController {
  _Localization() : super(languageServiceInterface: _LanguageService());
  @override
  void loadCurrentLanguage() {}
}

class _Flash extends FlashSaleController {
  _Flash() : super(flashSaleServiceInterface: _FlashService());
  @override
  void setEmptyFlashSale({bool fromModule = false}) {}
}

class _Store extends StoreController {
  _Store() : super(storeServiceInterface: _StoreService());
  @override
  Future<void> getVisitAgainStoreList({bool fromModule = false, dynamic dataSource, bool fromRecall = false}) async {}
  @override
  Future<void> getFeaturedStoreList({dynamic dataSource}) async {}
}

class _Banner extends BannerController {
  _Banner() : super(bannerServiceInterface: _BannerService());
  @override
  Future<void> getFeaturedBanner() async {}
}

class _Profile extends ProfileController {
  _Profile() : super(profileServiceInterface: _ProfileService());
  @override
  Future<void> getUserInfo() async {}
}

class _Notification extends NotificationController {
  _Notification() : super(notificationServiceInterface: _NotificationService());
  @override
  Future<int> getNotificationList(bool reload) async => 0;
}

class _Coupon extends CouponController {
  _Coupon() : super(couponServiceInterface: _CouponService());
  @override
  Future<void> getCouponList() async {}
}

class _Address extends AddressController {
  _Address() : super(addressServiceInterface: _AddressService());
  @override
  Future<void> getAddressList() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    _log.clear();
  });

  tearDown(Get.reset);

  group('getConfigData routing', () {
    late _SplashService service;
    late _Auth auth;

    setUp(() async {
      await _prefsWithAddress();
      service = _SplashService();
      auth = _Auth();
      Get.put<AuthController>(auth);
      Get.put<SplashController>(_Splash(service));
    });

    testWidgets('routeAfterLoad: false — cached and network config applied, no navigation, no token update', (WidgetTester tester) async {
      await _pumpApp(tester);
      await Get.find<SplashController>().getConfigData(routeAfterLoad: false);
      await tester.pumpAndSettle();

      expect(_log.where((String e) => e.startsWith('config(')), <String>['config(local)', 'config(client)']);
      expect(Get.find<SplashController>().configModel?.maintenanceMode, isFalse, reason: 'config parsed and applied');
      expect(_count('push'), 0, reason: 'no splash navigation');
      expect(_count('updateToken'), 0);
      expect(find.text('address sheet'), findsOneWidget);
    });

    testWidgets('default (splash, notification screen): routing unchanged — navigates to Home and updates the token', (WidgetTester tester) async {
      await _pumpApp(tester);
      await Get.find<SplashController>().getConfigData();
      await tester.pumpAndSettle();

      expect(_log.where((String e) => e.startsWith('push')), <String>['push ${RouteHelper.getInitialRoute(fromSplash: true)}'],
          reason: 'cached config routes; the network config route is a GetX duplicate');
      expect(_count('updateToken'), 2, reason: 'cached + network config, as before');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('routeAfterLoad: false still redirects to the update screen in maintenance mode', (WidgetTester tester) async {
      service.config = _config(maintenance: true);
      await _pumpApp(tester);
      await Get.find<SplashController>().getConfigData(routeAfterLoad: false);
      await tester.pumpAndSettle();

      expect(_log, contains('push ${RouteHelper.getUpdateRoute(false)}'));
      expect(find.text('update'), findsOneWidget);
      expect(_count('updateToken'), 0);
    });

    testWidgets('routeAfterLoad: false still applies a single-module config (setModule)', (WidgetTester tester) async {
      service.config = _config(singleModule: <String, dynamic>{'id': 3, 'module_name': 'Food', 'module_type': 'food'});
      await _pumpApp(tester);
      await Get.find<SplashController>().getConfigData(routeAfterLoad: false);
      await tester.pumpAndSettle();

      expect(_log, contains('setModule(3)'));
      expect(_count('push'), 0);
      expect(_count('updateToken'), 0);
    });

    testWidgets('guest default routing: unchanged (no token update for guests)', (WidgetTester tester) async {
      auth.loggedIn = false;
      await _pumpApp(tester);
      await Get.find<SplashController>().getConfigData();
      await tester.pumpAndSettle();
      expect(_count('updateToken'), 0);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('address save (_saveDataAndFirebaseConfig)', () {
    late _FlowSplash splash;
    late _Auth auth;
    late _FlowLocation location;

    setUp(() async {
      await _prefsWithAddress();
      splash = _FlowSplash();
      auth = _Auth();
      location = _FlowLocation();
      Get.put<SplashController>(splash);
      Get.put<AuthController>(auth);
      Get.put<ApiClient>(_ApiClient());
      Get.put<LocalizationController>(_Localization());
      Get.put<LocationController>(location);
      Get.put<CartController>(_Cart());
      Get.put<CheckoutController>(_Checkout());
      Get.put<FlashSaleController>(_Flash());
      Get.put<StoreController>(_Store());
      Get.put<BannerController>(_Banner());
      Get.put<ProfileController>(_Profile());
      Get.put<NotificationController>(_Notification());
      Get.put<CouponController>(_Coupon());
      Get.put<AddressController>(_Address());
    });

    Future<void> saveAddress(WidgetTester tester) async {
      location.saveAddressAndNavigate(AddressModel(latitude: '8.16', longitude: '4.25', addressType: 'others', address: 'Ogbomoso'), false, '', false, false);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('logged in, no module: config refreshed WITHOUT routing; Home refreshed; one navigation', (WidgetTester tester) async {
      await _pumpApp(tester);
      await saveAddress(tester);

      expect(splash.configRefreshes, <bool>[false], reason: 'getConfigData(routeAfterLoad: false)');
      expect(_count('home:loadData'), 1, reason: 'explicit HomeScreen.loadData(true) still runs');
      expect(_count('handleRoute'), 1, reason: "the flow's one navigation");
      expect(_count('updateZone'), 1);
      expect(_count('configureFirebaseMessaging'), 1);
      expect(_log.indexOf('home:loadData'), lessThan(_log.indexOf('handleRoute')));
    });

    testWidgets('guest: no config refresh, Home refreshed, one navigation — unchanged', (WidgetTester tester) async {
      auth.loggedIn = false;
      await _pumpApp(tester);
      await saveAddress(tester);

      expect(splash.configRefreshes, isEmpty);
      expect(_count('updateZone'), 0);
      expect(_count('home:loadData'), 1);
      expect(_count('handleRoute'), 1);
    });
  });
}
