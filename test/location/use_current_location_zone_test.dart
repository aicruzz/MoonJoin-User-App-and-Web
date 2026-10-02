// "Use current location" zone lookups. getCurrentLocation looks up the zone of
// the device position; the address sheet then looked the same coordinates up
// again, and saveAddressAndNavigate a third time. A successful first answer is
// now reused for both. A failed first lookup is still retried and handled
// exactly as before, and every other saveAddressAndNavigate caller (saved
// address, Pick Map, first address, web landing, deliver-to) keeps its lookup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/dashboard/widgets/address_bottom_sheet_widget.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/location/domain/models/zone_response_model.dart';
import 'package:moonjoin/features/location/domain/services/location_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/helper/route_helper.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}
class _CartService extends _NoSuch implements CartServiceInterface {}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  @override
  ModuleModel? get module => ModuleModel(id: 3, moduleType: 'food');
  @override
  ConfigModel? get configModel => ConfigModel(defaultLocation: DefaultLocation(lat: '0', lng: '0'));
}

/// GPS and geocode answer at once; each zone lookup answers with the next queued result.
class _LocationService extends _NoSuch implements LocationServiceInterface {
  final List<ZoneResponseModel> answers = <ZoneResponseModel>[];
  final List<String> zoneCalls = <String>[];
  double lat = 8.1612, lng = 4.2514;

  @override
  Future<Position> getPosition(LatLng? defaultLatLng, LatLng configLatLng) async => Position(
        latitude: lat, longitude: lng, timestamp: DateTime(2026), accuracy: 1, altitude: 1,
        heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1,
      );
  @override
  void handleMapAnimation(GoogleMapController? mapController, Position myPosition) {}
  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async => 'Ogbomoso';
  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng, {bool handleError = false}) async {
    zoneCalls.add('$lat,$lng');
    return answers.removeAt(0);
  }
}

/// Real lookup / save decisions; connectivity and the post-save navigation are recorded.
class _Location extends LocationController {
  _Location(_LocationService service) : super(locationServiceInterface: service);
  bool online = true;
  int internetChecks = 0;
  final List<AddressModel> navigated = <AddressModel>[];
  @override
  Future<bool> checkInternet() async {
    internetChecks++;
    return online;
  }
  @override
  void autoNavigate(AddressModel? address, bool fromSignUp, String? route, bool canRoute, bool isDesktop) => navigated.add(address!);
}

class _Cart extends CartController {
  _Cart() : super(cartServiceInterface: _CartService());
  int refreshes = 0;
  @override
  Future<void> getCartDataOnline() async => refreshes++;
}

ZoneResponseModel _inZone(List<int> ids) => ZoneResponseModel(true, '', ids, <ZoneData>[for (final int id in ids) ZoneData(id: id, status: 1)], <int>[], 200);
ZoneResponseModel _failure(int? status) => ZoneResponseModel(false, 'connection_to_api_server_failed', <int>[], <ZoneData>[], <int>[], status);
final ZoneResponseModel _notInThisArea = ZoneResponseModel(false, 'Service not available in this area', <int>[], <ZoneData>[], <int>[], 404);

void main() {
  late _LocationService service;
  late _Location location;
  late _Cart cart;
  late List<String> pushed;

  Future<void> pumpApp(WidgetTester tester) async {
    pushed = <String>[];
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/home',
      navigatorObservers: <NavigatorObserver>[_Pushes(pushed)],
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/home', page: () => const Scaffold(body: Text('home'))),
        GetPage<dynamic>(name: RouteHelper.pickMap, page: () => const Scaffold(body: Text('pick map'))),
      ],
    ));
    pushed.clear();
  }

  setUp(() {
    Get.testMode = true;
    service = _LocationService();
    location = _Location(service);
    cart = _Cart();
    Get.put<SplashController>(_Splash());
    Get.put<LocationController>(location);
    Get.put<CartController>(cart);
  });

  tearDown(Get.reset);

  testWidgets('in zone: one zone lookup; #1 zone fields saved; connectivity checked; cart refreshed; navigates', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_inZone(<int>[7, 8]));

    await AddressBottomSheetWidget.useCurrentLocation();
    await tester.pump();

    expect(service.zoneCalls, <String>['8.1612,4.2514'], reason: 'was 3 lookups of the same position');
    expect(location.internetChecks, 1, reason: 'checkInternet still runs before saving');
    expect(cart.refreshes, 1);
    final AddressModel saved = location.navigated.single;
    expect(saved.zoneId, 7);
    expect(saved.zoneIds, <int>[7, 8]);
    expect(saved.zoneData!.map((ZoneData z) => z.id), <int?>[7, 8]);
    expect(saved.areaIds, isEmpty);
    expect(saved.latitude, '8.1612');
    expect(location.inZone, isTrue);
    expect(location.zoneID, 7);
    expect(pushed.where((String r) => r.startsWith(RouteHelper.pickMap)), isEmpty);
  });

  testWidgets('out of zone (404 at #1): retried as before → Pick Map + snackbar, nothing saved', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.addAll(<ZoneResponseModel>[_notInThisArea, _notInThisArea]);

    await AddressBottomSheetWidget.useCurrentLocation();
    await tester.pump();

    expect(service.zoneCalls, hasLength(2), reason: 'lookup #2 kept when #1 failed');
    expect(pushed.where((String r) => r.startsWith(RouteHelper.pickMap)), hasLength(1));
    expect(find.text('service_not_available_in_current_location'), findsOneWidget);
    expect(location.navigated, isEmpty);
    expect(cart.refreshes, 0);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('5xx/timeout at #1, retry succeeds: saved through the original lookups', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.addAll(<ZoneResponseModel>[_failure(500), _inZone(<int>[9]), _inZone(<int>[9])]);

    await AddressBottomSheetWidget.useCurrentLocation();
    await tester.pump();

    expect(service.zoneCalls, hasLength(3), reason: 'failed first lookup → retry (#2) and #3, exactly as before');
    expect(location.navigated.single.zoneId, 9);
    expect(cart.refreshes, 1);
  });

  testWidgets('offline: checkInternet still blocks saving on the reused path', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_inZone(<int>[7]));
    location.online = false;

    await AddressBottomSheetWidget.useCurrentLocation();
    await tester.pump();

    expect(location.internetChecks, 1);
    expect(location.navigated, isEmpty);
    expect(cart.refreshes, 0);
    expect(service.zoneCalls, hasLength(1));
  });

  testWidgets('other callers (no verifiedZone): saveAddressAndNavigate still looks the zone up', (WidgetTester tester) async {
    await pumpApp(tester);
    final AddressModel saved = AddressModel(id: 12, latitude: '8.1335', longitude: '4.2402', addressType: 'home');
    service.answers.add(_inZone(<int>[7]));

    location.saveAddressAndNavigate(saved, false, null, false, false);
    await tester.pump();

    expect(service.zoneCalls, <String>['8.1335,4.2402']);
    expect(location.internetChecks, 1);
    expect(location.navigated.single.zoneId, 7);
  });

  testWidgets('other callers: 404 still opens Pick Map, no save', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_notInThisArea);

    location.saveAddressAndNavigate(AddressModel(latitude: '1', longitude: '2'), false, 'home', false, false);
    await tester.pump();

    expect(service.zoneCalls, hasLength(1));
    expect(pushed.where((String r) => r.startsWith(RouteHelper.pickMap)), hasLength(1));
    expect(location.navigated, isEmpty);
  });

  testWidgets('a failed verifiedZone is never reused: the lookup runs', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_inZone(<int>[5]));

    location.saveAddressAndNavigate(AddressModel(latitude: '1', longitude: '2'), false, '', false, false, verifiedZone: _failure(500));
    await tester.pump();

    expect(service.zoneCalls, hasLength(1));
    expect(location.navigated.single.zoneId, 5);
  });

  testWidgets('repeated Use current location: each uses its own first lookup, never the previous one', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_inZone(<int>[7]));
    await AddressBottomSheetWidget.useCurrentLocation();
    await tester.pump();
    expect(location.navigated.last.zoneId, 7);

    // Second selection, elsewhere: its first lookup fails → the previous zone 7 must not be used.
    service.lat = 9.0;
    service.lng = 5.0;
    service.answers.addAll(<ZoneResponseModel>[_failure(500), _inZone(<int>[9]), _inZone(<int>[9])]);
    await AddressBottomSheetWidget.useCurrentLocation();
    await tester.pump();

    expect(location.currentLocationZone!.isSuccess, isFalse, reason: 'replaced by the new first lookup');
    expect(service.zoneCalls.skip(1), <String>['9.0,5.0', '9.0,5.0', '9.0,5.0']);
    expect(location.navigated.last.zoneId, 9);
    expect(location.navigated.last.latitude, '9.0');
  });
}

class _Pushes extends NavigatorObserver {
  _Pushes(this.names);
  final List<String> names;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String? name = route.settings.name;
    if (name != null) names.add(name);
  }
}
