// Slice E1.1 — Set Location must not show "No internet connection" on a phone
// that is online. On iOS the first connectivity read after the splash screen's
// listener is cancelled comes from a freshly created NWPathMonitor that has not
// evaluated the network yet, and can report `none`. A negative first answer is
// therefore confirmed once (after a short delay) before redirecting; a positive
// first answer is trusted immediately, and a genuinely offline phone still gets
// the No Internet screen.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/no_internet_screen.dart';
import 'package:moonjoin/features/address/controllers/address_controller.dart';
import 'package:moonjoin/features/address/domain/services/address_service_interface.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/location/helpers/access_location_connectivity.dart';
import 'package:moonjoin/features/location/screens/access_location_screen.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';

const Duration _recheck = Duration(milliseconds: 300);

/// Answers each connectivity check with the next scripted result.
class _ScriptedConnectivity {
  _ScriptedConnectivity(this._answers);
  final List<List<ConnectivityResult>> _answers;
  int calls = 0;

  Future<List<ConnectivityResult>> check() async {
    calls++;
    return _answers.removeAt(0);
  }
}

class _FakeAuthService implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAddressService implements AddressServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Guest user: the screen shows its guest layout and skips the address request.
class _GuestAuth extends AuthController {
  _GuestAuth() : super(authServiceInterface: _FakeAuthService());
  @override
  bool isLoggedIn() => false;
  @override
  bool isGuestLoggedIn() => true;
}

void main() {
  group('isOnlineForAddressSelection', () {
    testWidgets('first read none, second Wi-Fi → online (the iOS first-open false negative)', (WidgetTester tester) async {
      final _ScriptedConnectivity c = _ScriptedConnectivity(<List<ConnectivityResult>>[
        <ConnectivityResult>[ConnectivityResult.none], <ConnectivityResult>[ConnectivityResult.wifi],
      ]);
      bool? online;
      isOnlineForAddressSelection(c.check).then((bool v) => online = v);
      await tester.pump();
      expect(online, isNull, reason: 'waits before trusting a negative first read');
      await tester.pump(_recheck);
      expect(online, isTrue);
      expect(c.calls, 2);
    });

    testWidgets('first read none, second mobile → online', (WidgetTester tester) async {
      final _ScriptedConnectivity c = _ScriptedConnectivity(<List<ConnectivityResult>>[
        <ConnectivityResult>[ConnectivityResult.none], <ConnectivityResult>[ConnectivityResult.mobile],
      ]);
      bool? online;
      isOnlineForAddressSelection(c.check).then((bool v) => online = v);
      await tester.pump(_recheck);
      await tester.pump();
      expect(online, isTrue);
      expect(c.calls, 2);
    });

    testWidgets('first read none, second none → offline (genuine offline still detected)', (WidgetTester tester) async {
      final _ScriptedConnectivity c = _ScriptedConnectivity(<List<ConnectivityResult>>[
        <ConnectivityResult>[ConnectivityResult.none], <ConnectivityResult>[ConnectivityResult.none],
      ]);
      bool? online;
      isOnlineForAddressSelection(c.check).then((bool v) => online = v);
      await tester.pump(_recheck);
      await tester.pump();
      expect(online, isFalse);
      expect(c.calls, 2);
    });

    testWidgets('first read Wi-Fi → online immediately, no second check, no delay', (WidgetTester tester) async {
      final _ScriptedConnectivity c = _ScriptedConnectivity(<List<ConnectivityResult>>[<ConnectivityResult>[ConnectivityResult.wifi]]);
      bool? online;
      isOnlineForAddressSelection(c.check).then((bool v) => online = v);
      await tester.pump();
      expect(online, isTrue);
      expect(c.calls, 1);
    });

    testWidgets('first read mobile → online immediately, no second check, no delay', (WidgetTester tester) async {
      final _ScriptedConnectivity c = _ScriptedConnectivity(<List<ConnectivityResult>>[<ConnectivityResult>[ConnectivityResult.mobile]]);
      bool? online;
      isOnlineForAddressSelection(c.check).then((bool v) => online = v);
      await tester.pump();
      expect(online, isTrue);
      expect(c.calls, 1);
    });
  });

  group('AccessLocationScreen', () {
    late List<List<String>> channelAnswers;
    late int channelCalls;

    setUp(() {
      Get.testMode = true;
      channelAnswers = <List<String>>[];
      channelCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (MethodCall call) async {
          channelCalls++;
          return channelAnswers.isNotEmpty ? channelAnswers.removeAt(0) : <String>['none'];
        },
      );
      Get.put<AuthController>(_GuestAuth());
      Get.put<SplashController>(SplashController(splashServiceInterface: _FakeSplashService()));
      Get.put<AddressController>(AddressController(addressServiceInterface: _FakeAddressService()));
    });

    tearDown(Get.reset);

    Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(GetMaterialApp(
      home: const Scaffold(body: Text('HOME')),
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/set-location', page: () => const AccessLocationScreen(fromSignUp: false, fromHome: true, route: null)),
      ],
    ));

    testWidgets('online first open with a false-negative first read stays on Set Location', (WidgetTester tester) async {
      channelAnswers = <List<String>>[<String>['none'], <String>['wifi']];
      await pumpScreen(tester);
      Get.toNamed('/set-location');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(NoInternetScreen), findsNothing);
      expect(find.byType(AccessLocationScreen), findsOneWidget);
      expect(channelCalls, 2);
    });

    testWidgets('genuinely offline still shows the existing No Internet screen, exactly once', (WidgetTester tester) async {
      channelAnswers = <List<String>>[<String>['none'], <String>['none']];
      await pumpScreen(tester);
      Get.toNamed('/set-location');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      // NoInternetScreen itself (unchanged, out of scope) trips debug-only layout
      // and Material assertions in the test window; only the redirect is asserted.
      while (tester.takeException() != null) {}
      expect(find.byType(NoInternetScreen), findsOneWidget);
      expect(find.byType(AccessLocationScreen), findsNothing);
      expect(channelCalls, 2);
    });

    testWidgets('online first read (Wi-Fi) opens normally with a single check', (WidgetTester tester) async {
      channelAnswers = <List<String>>[<String>['wifi']];
      await pumpScreen(tester);
      Get.toNamed('/set-location');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(NoInternetScreen), findsNothing);
      expect(find.byType(AccessLocationScreen), findsOneWidget);
      expect(channelCalls, 1);
    });

    testWidgets('leaving the screen before the delayed recheck never navigates to No Internet', (WidgetTester tester) async {
      channelAnswers = <List<String>>[<String>['none'], <String>['none']];
      await pumpScreen(tester);
      Get.toNamed('/set-location');
      await tester.pump(); // first read: none → recheck scheduled
      Get.back();          // user leaves before it runs
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(NoInternetScreen), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
      // The screen's own back handling (unchanged) starts a 2 s "press again" timer.
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
