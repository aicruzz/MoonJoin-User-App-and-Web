// Terminated-state notification tap → Order Details, routed once. getConfigData
// loads the cached config (which routed the startup notification to Order
// Details) and then the network config, which was started without the
// notification: its logged-in user routing (Get.offNamed Home) replaced Order
// Details with Home. The network refresh now skips user routing when the cached
// config already routed the notification, and carries the notification when
// there is no usable cache. Normal cold start (no notification) is unchanged.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/notification/domain/models/notification_body_model.dart';
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

/// Every observable action, in order.
final List<String> _log = <String>[];

final Map<String, dynamic> _config = <String, dynamic>{
  'maintenance_mode': false,
  'app_minimum_version_android': 0,
  'app_minimum_version_ios': 0,
  'module_config': <String, dynamic>{'module_type': <String>['grocery'], 'grocery': <String, dynamic>{'order_place_to_schedule_interval': false}},
};

/// Network config answers; the cached config answers only when [hasCache].
class _SplashService extends _NoSuch implements SplashServiceInterface {
  bool hasCache = true;
  @override
  bool? showIntro() => false;
  @override
  Future<Response> getConfigData({required DataSourceEnum source}) async {
    _log.add('config(${source.name})');
    if(source == DataSourceEnum.local && !hasCache) {
      return Response(statusCode: 0, body: ApiClient.noInternetMessage);
    }
    return Response(statusCode: 200, body: _config);
  }
}

/// Real getConfigData / _handleConfigResponse / route.
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

class _Pushes extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _log.add('push ${route.settings.name}');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _log.add('replace ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
}

List<String> _navigation() => _log.where((String e) => e.startsWith('push') || e.startsWith('replace')).toList();

final NotificationBodyModel _orderNotification = NotificationBodyModel(notificationType: NotificationType.order, orderId: 100012);
final String _orderRoute = RouteHelper.getOrderDetailsRoute(100012, fromNotification: true);

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(GetMaterialApp(
    initialRoute: '/splash-test',
    navigatorObservers: <NavigatorObserver>[_Pushes()],
    getPages: <GetPage<dynamic>>[
      GetPage<dynamic>(name: '/splash-test', page: () => const Scaffold(body: Text('splash'))),
      GetPage<dynamic>(name: RouteHelper.initial, page: () => const Scaffold(body: Text('home'))),
      GetPage<dynamic>(name: RouteHelper.orderDetails, page: () => const Scaffold(body: Text('order details'))),
    ],
  ));
  _log.clear();
}

void main() {
  late _SplashService service;

  setUp(() async {
    Get.testMode = true;
    _log.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.userAddress: jsonEncode(<String, dynamic>{'latitude': '8.16', 'longitude': '4.25', 'zone_id': 7, 'zone_ids': <int>[7]}),
    });
    Get.put<SharedPreferences>(await SharedPreferences.getInstance());
    service = _SplashService();
    Get.put<AuthController>(_Auth());
    Get.put<SplashController>(_Splash(service));
  });

  tearDown(Get.reset);

  testWidgets('cached config routes the notification; the network refresh does not replace Order Details with Home', (WidgetTester tester) async {
    await _pumpApp(tester);
    await Get.find<SplashController>().getConfigData(notificationBody: _orderNotification);
    await tester.pumpAndSettle();

    expect(_log.where((String e) => e.startsWith('config(')), <String>['config(local)', 'config(client)'], reason: 'config still refreshed from the network');
    expect(_navigation(), <String>['push $_orderRoute'], reason: 'Order Details pushed once, never replaced');
    expect(find.text('order details'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('no usable cache: the network pass carries the notification and routes it to Order Details', (WidgetTester tester) async {
    service.hasCache = false;
    await _pumpApp(tester);
    await Get.find<SplashController>().getConfigData(notificationBody: _orderNotification);
    await tester.pumpAndSettle();

    expect(_log.where((String e) => e.startsWith('config(')), <String>['config(local)', 'config(client)']);
    expect(_navigation(), <String>['push $_orderRoute']);
    expect(find.text('order details'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('normal cold start (no notification): Home reached, routing unchanged', (WidgetTester tester) async {
    await _pumpApp(tester);
    await Get.find<SplashController>().getConfigData();
    await tester.pumpAndSettle();

    expect(_navigation().where((String e) => e.contains(RouteHelper.getInitialRoute(fromSplash: true))), isNotEmpty);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('order details'), findsNothing);
    expect(_log.where((String e) => e == 'updateToken').length, 2, reason: 'cached + network config, as before');
  });
}
