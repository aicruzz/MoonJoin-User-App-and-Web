// Slice E1 — LocationController.syncZoneData must not destroy a valid saved
// address when the zone lookup gets no definitive answer (offline / timeout /
// 5xx). A real answer keeps the existing behaviour: a successful lookup updates
// the zone, and the backend's "Service not available in this area" (HTTP 404)
// or a successful lookup with no zones still clears the address and opens Set
// Location.
//
// Physical-device bug this guards: iOS checkInternet() lets offline requests
// through, the failed lookup returned no zone ids, and the saved address was
// overwritten with an empty AddressModel() on every offline launch.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/location/domain/models/zone_response_model.dart';
import 'package:moonjoin/features/location/domain/services/location_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSplash extends SplashController {
  _TestSplash() : super(splashServiceInterface: _FakeSplashService());
  @override
  ModuleModel? get module => ModuleModel(id: 3, moduleType: 'food');
}

/// Records header updates — a wipe shows up as an update with no zone/coordinates.
class _FakeApiClient extends GetxService implements ApiClient {
  final List<Map<String, Object?>> headerUpdates = <Map<String, Object?>>[];

  @override
  Map<String, String> updateHeader(String? token, List<int>? zoneIDs, List<int>? operationIds, String? languageCode, int? moduleID, String? latitude, String? longitude, {bool setHeader = true}) {
    headerUpdates.add(<String, Object?>{'zoneIds': zoneIDs, 'latitude': latitude, 'longitude': longitude});
    return <String, String>{};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers each getZone with the next queued result.
class _FakeLocationService implements LocationServiceInterface {
  final List<ZoneResponseModel> answers = <ZoneResponseModel>[];
  final List<String> calls = <String>[];

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng, {bool handleError = false}) async {
    calls.add('$lat,$lng');
    return answers.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final AddressModel _savedAddress = AddressModel(
  id: 12, addressType: 'home', address: 'Ogbomoso, Oyo, Nigeria',
  latitude: '8.1335', longitude: '4.2402', zoneId: 7, zoneIds: <int>[7], areaIds: <int>[],
  zoneData: <ZoneData>[ZoneData(id: 7, status: 1)],
);

ZoneResponseModel _inZone(List<int> ids) => ZoneResponseModel(true, '', ids, <ZoneData>[for (final int id in ids) ZoneData(id: id, status: 1)], <int>[], 200);
ZoneResponseModel _failure(int? status, [String message = 'connection_to_api_server_failed']) => ZoneResponseModel(false, message, <int>[], <ZoneData>[], <int>[], status);
final ZoneResponseModel _notInThisArea = ZoneResponseModel(false, 'Service not available in this area', <int>[], <ZoneData>[], <int>[], 404);

void main() {
  late _FakeApiClient api;
  late _FakeLocationService service;
  late LocationController controller;
  late SharedPreferences prefs;

  String savedAddressJson() => prefs.getString(AppConstants.userAddress)!;
  AddressModel savedAddress() => AddressModel.fromJson(jsonDecode(savedAddressJson()));

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/',
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/', page: () => const Scaffold(body: Text('HOME'))),
        GetPage<dynamic>(name: RouteHelper.accessLocation, page: () => const Scaffold(body: Text('SET_LOCATION'))),
      ],
    ));
  }

  setUp(() async {
    Get.testMode = true;
    // syncZoneData asks connectivity_plus first; report Wi-Fi so the request path
    // is exercised exactly as on an iPhone, where checkInternet() lets it through.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'), (MethodCall call) async => <String>['wifi'],
    );
    SharedPreferences.setMockInitialValues(<String, Object>{AppConstants.userAddress: jsonEncode(_savedAddress.toJson())});
    prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs);
    api = _FakeApiClient();
    Get.put<ApiClient>(api);
    Get.put<SplashController>(_TestSplash());
    service = _FakeLocationService();
    controller = LocationController(locationServiceInterface: service);
  });

  tearDown(Get.reset);

  group('zone lookup got no definitive answer → saved address is preserved', () {
    for (final (String label, ZoneResponseModel answer) in <(String, ZoneResponseModel)>[
      ('offline / timeout / exception (status 1)', _failure(1)),
      ('no response body (status 0)', _failure(0)),
      ('HTTP 500 Internal Server Error', _failure(500, 'Internal Server Error')),
      ('HTTP 503', _failure(503, 'Service Unavailable')),
      ('HTTP 408 timeout', _failure(408, 'Request Timeout')),
      ('no status at all', _failure(null)),
    ]) {
      testWidgets(label, (WidgetTester tester) async {
        await pumpApp(tester);
        final String before = savedAddressJson();
        service.answers.add(answer);

        await controller.syncZoneData();
        await tester.pumpAndSettle();

        expect(savedAddressJson(), before, reason: 'the saved address must be untouched');
        expect(savedAddress().latitude, '8.1335');
        expect(savedAddress().longitude, '4.2402');
        expect(savedAddress().zoneIds, <int>[7]);
        expect(api.headerUpdates, isEmpty, reason: 'zone/coordinate headers must not be rewritten');
        expect(find.text('SET_LOCATION'), findsNothing, reason: 'no Set Location redirect just because the lookup failed');
        expect(find.text('HOME'), findsOneWidget);
      });
    }
  });

  testWidgets('REGRESSION: valid saved address + failed zone lookup must NOT become an empty AddressModel()', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_failure(1));

    await controller.syncZoneData();
    await tester.pumpAndSettle();

    expect(savedAddressJson(), isNot(jsonEncode(AddressModel().toJson())));
    expect(savedAddress().address, 'Ogbomoso, Oyo, Nigeria');
    expect(find.text('SET_LOCATION'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('successful lookup with zones: address and headers are updated exactly as before', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_inZone(<int>[7, 8]));

    await controller.syncZoneData();
    await tester.pumpAndSettle();

    final AddressModel address = savedAddress();
    expect(address.zoneId, 7);
    expect(address.zoneIds, <int>[7, 8]);
    expect(address.zoneData!.map((z) => z.id), <int>[7, 8]);
    expect(address.latitude, '8.1335');
    expect(api.headerUpdates.last['zoneIds'], <int>[7, 8]);
    expect(find.text('SET_LOCATION'), findsNothing);
  });

  testWidgets('backend says "Service not available in this area" (404): existing out-of-zone behaviour is kept', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_notInThisArea);

    await controller.syncZoneData();
    await tester.pumpAndSettle();

    expect(savedAddressJson(), jsonEncode(AddressModel().toJson()), reason: 'address cleared as before');
    expect(api.headerUpdates.last['zoneIds'], isNull);
    expect(find.text('SET_LOCATION'), findsOneWidget);
  });

  testWidgets('successful lookup that returns no zones: existing out-of-zone behaviour is kept', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers.add(_inZone(<int>[]));

    await controller.syncZoneData();
    await tester.pumpAndSettle();

    expect(savedAddressJson(), jsonEncode(AddressModel().toJson()));
    expect(find.text('SET_LOCATION'), findsOneWidget);
  });

  testWidgets('a failed lookup does not poison the next one: a later success updates normally', (WidgetTester tester) async {
    await pumpApp(tester);
    service.answers..add(_failure(1))..add(_inZone(<int>[8]));

    await controller.syncZoneData();
    await tester.pumpAndSettle();
    expect(savedAddress().zoneIds, <int>[7]);

    await controller.syncZoneData();
    await tester.pumpAndSettle();
    expect(savedAddress().zoneIds, <int>[8]);
    expect(savedAddress().zoneId, 8);
    expect(service.calls, <String>['8.1335,4.2402', '8.1335,4.2402'], reason: 'the retry used the preserved coordinates');
    expect(find.text('SET_LOCATION'), findsNothing);
  });
}
