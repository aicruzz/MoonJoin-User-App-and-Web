// 401 session-clear coordination.
// Concurrent 401s used to each run clearSharedData -> guestLogin -> navigation.
// They now share one recovery; the guard is released when it finishes (also on
// error), so a later 401 is handled again exactly as before.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_checker.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/favourite/domain/services/favourite_service_interface.dart';

class _AuthService implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// clearSharedData mirrors the repository order (clear, then await guestLogin);
/// each guest login is held on a Completer so the test controls when it ends.
class _Auth extends AuthController {
  _Auth() : super(authServiceInterface: _AuthService());
  int clears = 0;
  int guestLogins = 0;
  bool clearThrows = false;
  final List<Completer<ResponseModel>> pendingGuestLogins = <Completer<ResponseModel>>[];

  @override
  Future<bool> clearSharedData({bool removeToken = true}) async {
    clears++;
    expect(removeToken, isFalse, reason: 'a 401 keeps removeToken: false');
    if (clearThrows) {
      throw StateError('clear failed');
    }
    await guestLogin();
    return true;
  }

  @override
  Future<ResponseModel> guestLogin() {
    guestLogins++;
    final Completer<ResponseModel> c = Completer<ResponseModel>();
    pendingGuestLogins.add(c);
    return c.future;
  }
}

class _FavouriteService implements FavouriteServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Favourite extends FavouriteController {
  _Favourite() : super(favouriteServiceInterface: _FavouriteService());
  int removes = 0;
  @override
  void removeFavourite() => removes++;
}

class _PushCounter extends NavigatorObserver {
  final List<String?> pushed = <String?>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushed.add(route.settings.name);
}

const Response _unauthorized = Response(statusCode: 401, statusText: 'Unauthenticated.');

void main() {
  late _Auth auth;
  late _Favourite favourite;
  late _PushCounter nav;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/start',
      navigatorObservers: <NavigatorObserver>[nav],
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: '/start', page: () => const Scaffold(body: Text('start'))),
        GetPage<dynamic>(name: '/', page: () => const Scaffold(body: Text('initial'))),
      ],
    ));
    nav.pushed.clear();
  }

  /// Navigations to the initial route ('/?from-splash=false').
  int initialNavigations() => nav.pushed.where((String? n) => n != null && n.startsWith('/?')).length;

  setUp(() {
    Get.testMode = true;
    auth = _Auth();
    favourite = _Favourite();
    nav = _PushCounter();
    Get.put<AuthController>(auth);
    Get.put<FavouriteController>(favourite);
  });

  tearDown(Get.reset);

  testWidgets('single 401: one clear, one guest login, favourites cleared, one navigation to initial', (WidgetTester tester) async {
    await pumpApp(tester);
    ApiChecker.checkApi(_unauthorized);
    expect(ApiChecker.sessionRecovery, isNotNull);
    await tester.pump();
    expect(auth.clears, 1);
    expect(auth.guestLogins, 1);
    expect(favourite.removes, 0, reason: 'favourites cleared only after the guest login');
    expect(initialNavigations(), 0, reason: 'navigation only after the guest login');

    auth.pendingGuestLogins.single.complete(ResponseModel(true, '1'));
    await tester.pumpAndSettle();
    expect(favourite.removes, 1);
    expect(initialNavigations(), 1);
    expect(find.text('initial'), findsOneWidget);
    expect(ApiChecker.sessionRecovery, isNull, reason: 'guard released');
  });

  testWidgets('three concurrent 401s, then a fourth while recovering: exactly one clear/guest login/navigation', (WidgetTester tester) async {
    await pumpApp(tester);
    ApiChecker.checkApi(_unauthorized);
    final Future<void>? first = ApiChecker.sessionRecovery;
    ApiChecker.checkApi(_unauthorized);
    ApiChecker.checkApi(_unauthorized);
    await tester.pump();
    expect(identical(ApiChecker.sessionRecovery, first), isTrue);

    ApiChecker.checkApi(_unauthorized);                          // arrives while the guest login is pending
    await tester.pump();
    expect(identical(ApiChecker.sessionRecovery, first), isTrue, reason: 'the 4th joins the same recovery');
    expect(auth.clears, 1);
    expect(auth.guestLogins, 1);

    auth.pendingGuestLogins.single.complete(ResponseModel(true, '1'));
    await tester.pumpAndSettle();
    expect(auth.clears, 1);
    expect(auth.guestLogins, 1);
    expect(favourite.removes, 1);
    expect(initialNavigations(), 1);
    expect(ApiChecker.sessionRecovery, isNull);
  });

  testWidgets('a 401 after the recovery has finished is handled again (existing semantics)', (WidgetTester tester) async {
    await pumpApp(tester);
    ApiChecker.checkApi(_unauthorized);
    await tester.pump();
    auth.pendingGuestLogins.last.complete(ResponseModel(true, '1'));
    await tester.pumpAndSettle();

    ApiChecker.checkApi(_unauthorized);
    await tester.pump();
    expect(auth.clears, 2);
    expect(auth.guestLogins, 2);
    auth.pendingGuestLogins.last.complete(ResponseModel(true, '2'));
    await tester.pumpAndSettle();
    expect(favourite.removes, 2);
    expect(initialNavigations(), 2);
    expect(ApiChecker.sessionRecovery, isNull);
  });

  testWidgets('recovery failure releases the guard; a later 401 can recover', (WidgetTester tester) async {
    await pumpApp(tester);
    auth.clearThrows = true;
    ApiChecker.checkApi(_unauthorized);
    ApiChecker.checkApi(_unauthorized);                          // joins the failing recovery
    final Future<void> failing = ApiChecker.sessionRecovery!;
    await expectLater(failing, throwsA(isA<StateError>()));      // error still surfaces, as before
    await tester.pump();
    expect(auth.clears, 1);
    expect(favourite.removes, 0, reason: 'nothing after a failed clear, as before');
    expect(initialNavigations(), 0);
    expect(ApiChecker.sessionRecovery, isNull, reason: 'no stuck guard');

    auth.clearThrows = false;
    ApiChecker.checkApi(_unauthorized);
    await tester.pump();
    expect(auth.clears, 2);
    auth.pendingGuestLogins.single.complete(ResponseModel(true, '1'));
    await tester.pumpAndSettle();
    expect(favourite.removes, 1);
    expect(initialNavigations(), 1);
    expect(ApiChecker.sessionRecovery, isNull);
  });

  testWidgets('non-401 errors: snackbar as before, no session recovery', (WidgetTester tester) async {
    await pumpApp(tester);
    ApiChecker.checkApi(const Response(statusCode: 500, statusText: 'Server error'));
    expect(ApiChecker.sessionRecovery, isNull);
    await tester.pump();
    expect(auth.clears, 0);
    expect(find.text('Server error'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    ApiChecker.checkApi(const Response(statusCode: 403, statusText: 'The guest id field is required.'));
    await tester.pump();
    expect(find.text('The guest id field is required.'), findsNothing, reason: 'suppressed message unchanged');
    expect(auth.clears, 0);
  });
}
