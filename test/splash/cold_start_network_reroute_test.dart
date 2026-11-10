// Rapid tap after a cold start returns to Home. Cold start routes twice: the
// cached config routes the user to Home at once, and the network config, which
// arrives seconds later, ran the same user routing again: Get.offNamed(Home).
// offNamed replaces the TOP route, so a page the customer had already opened in
// that window (e.g. a Food brand's store) was replaced by Home, with the Food
// module still active. Waiting first hid the bug because the network pass had
// already finished. The network pass now skips user routing when the cached pass
// already routed the user; it still applies a maintenance/update redirect, and it
// still routes the user when the cached pass had sent them to the update screen.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _AuthService extends _NoSuch implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;
}

final List<String> _log = <String>[];

Map<String, dynamic> _config({bool maintenance = false}) => <String, dynamic>{
  'maintenance_mode': maintenance,
  'app_minimum_version_android': 0,
  'app_minimum_version_ios': 0,
  'module_config': <String, dynamic>{'module_type': <String>['grocery'], 'grocery': <String, dynamic>{'order_place_to_schedule_interval': false}},
};

/// Cached config answers at once; the network config waits on [network].
class _SplashService extends _NoSuch implements SplashServiceInterface {
  bool hasCache = true;
  bool cachedMaintenance = false;
  bool networkMaintenance = false;
  /// Created inside each test body: a Completer made in setUp completes outside
  /// the test's fake-async zone, so its listeners would only run after the test.
  late Completer<void> network;
  @override
  bool? showIntro() => false;
  @override
  Future<Response> getConfigData({required DataSourceEnum source}) async {
    _log.add('config(${source.name})');
    if (source == DataSourceEnum.local) {
      return hasCache ? Response(statusCode: 200, body: _config(maintenance: cachedMaintenance)) : Response(statusCode: 0, body: ApiClient.noInternetMessage);
    }
    await network.future;
    return Response(statusCode: 200, body: _config(maintenance: networkMaintenance));
  }
}

class _Splash extends SplashController {
  _Splash(_SplashService service) : super(splashServiceInterface: service);
  @override
  Future<void> setModule(ModuleModel? module, {bool notify = true}) async {}
}

class _Auth extends AuthController {
  _Auth() : super(authServiceInterface: _AuthService());
  @override
  bool isLoggedIn() => true;
  @override
  bool isGuestLoggedIn() => false;
  @override
  Future<void> updateToken() async => _log.add('updateToken');
}

const String _store = '/store-test';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(GetMaterialApp(
    initialRoute: '/splash-test',
    getPages: <GetPage<dynamic>>[
      GetPage<dynamic>(name: '/splash-test', page: () => const Scaffold(body: Text('splash'))),
      GetPage<dynamic>(name: RouteHelper.initial, page: () => const Scaffold(body: Text('home'))),
      GetPage<dynamic>(name: _store, page: () => const Scaffold(body: Text('brand store'))),
      GetPage<dynamic>(name: RouteHelper.update, page: () => const Scaffold(body: Text('update'))),
    ],
  ));
}

void main() {
  late _SplashService service;

  setUp(() async {
    Get.testMode = true;
    _log.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userAddress: jsonEncode(<String, dynamic>{'latitude': '8.16', 'longitude': '4.25', 'zone_id': 7, 'zone_ids': <int>[7]}),
    });
    Get.put<SharedPreferences>(await SharedPreferences.getInstance(), permanent: true); // not bound to a route that routing replaces
    service = _SplashService();
    Get.put<AuthController>(_Auth(), permanent: true);
    Get.put<SplashController>(_Splash(service), permanent: true);
  });

  tearDown(Get.reset);

  Future<void> coldStart(WidgetTester tester) async {
    service.network = Completer<void>();
    await _pumpApp(tester);
    unawaited(Get.find<SplashController>().getConfigData());
    await tester.pumpAndSettle();
  }

  Future<void> networkArrives(WidgetTester tester) async {
    service.network.complete();
    await tester.pumpAndSettle();
  }

  testWidgets('rapid tap: a brand store opened before the network config stays open', (WidgetTester tester) async {
    await coldStart(tester);
    expect(find.text('home'), findsOneWidget, reason: 'cached config routed to Home');

    Get.toNamed(_store);
    await tester.pumpAndSettle();
    await networkArrives(tester);

    expect(Get.currentRoute, _store);
    expect(find.text('brand store'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('normal tap after the network config: unchanged', (WidgetTester tester) async {
    await coldStart(tester);
    await networkArrives(tester);
    Get.toNamed(_store);
    await tester.pumpAndSettle();
    expect(Get.currentRoute, _store);
    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget, reason: 'back returns to the Home that the cached pass opened');
  });

  testWidgets('user routing runs once for the cold start', (WidgetTester tester) async {
    await coldStart(tester);
    await networkArrives(tester);
    expect(_log.where((String e) => e.startsWith('config(')), <String>['config(local)', 'config(client)'], reason: 'config still refreshed from the network');
    expect(_log.where((String e) => e == 'updateToken').length, 1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('no usable cache: the network pass still routes the user', (WidgetTester tester) async {
    service.hasCache = false;
    await coldStart(tester);
    expect(find.text('home'), findsNothing);
    await networkArrives(tester);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('cached maintenance, network clear: the network pass still brings the user in', (WidgetTester tester) async {
    service.cachedMaintenance = true;
    await coldStart(tester);
    expect(find.text('update'), findsOneWidget);
    await networkArrives(tester);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('update'), findsNothing);
  });

  testWidgets('network says maintenance: the redirect still applies over the open page', (WidgetTester tester) async {
    service.networkMaintenance = true;
    await coldStart(tester);
    Get.toNamed(_store);
    await tester.pumpAndSettle();
    await networkArrives(tester);
    expect(find.text('update'), findsOneWidget);
  });
}
