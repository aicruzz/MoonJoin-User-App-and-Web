// Wallet balance on Checkout → Choose Payment Method. The balance comes from
// ProfileController.userInfoModel (customer/info). Checkout only fetched it when
// no profile was loaded yet, and the payment sheet's wallet row rebuilt only with
// CheckoutController, so a credit confirmed on the backend after the profile was
// first loaded (e.g. a bank transfer to the 9PSB virtual account) stayed hidden
// behind the old balance. The balance is now re-fetched from the server, through
// one shared request, on checkout entry and resume, when the payment sheet opens,
// and on the backend's add_fund push; the wallet row rebuilds with the profile.
// No balance is ever computed in the app.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/checkout/controllers/checkout_controller.dart';
import 'package:moonjoin/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:moonjoin/features/checkout/widgets/payment_method_bottom_sheet.dart';
import 'package:moonjoin/features/order/controllers/order_controller.dart';
import 'package:moonjoin/features/order/domain/services/order_service_interface.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/profile/domain/models/update_user_model.dart';
import 'package:moonjoin/features/profile/domain/models/userinfo_model.dart';
import 'package:moonjoin/features/profile/domain/services/profile_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/helper/notification_helper.dart';
import 'package:moonjoin/helper/price_converter.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _AuthService extends _NoSuch implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;
  @override
  String getUserCountryCode() => 'NG';
}

class _Auth extends AuthController {
  _Auth() : super(authServiceInterface: _AuthService());
  bool loggedIn = true;
  @override
  bool isLoggedIn() => loggedIn;
  @override
  bool isGuestLoggedIn() => false;
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  @override
  ConfigModel? get configModel => ConfigModel(
    customerWalletStatus: 1, activePaymentMethodList: [], partialPaymentStatus: false, cashOnDelivery: true,
    digitalPayment: false, offlinePaymentStatus: false, currencySymbol: 'NGN', currencySymbolDirection: 'left', digitAfterDecimalPoint: 0,
  );
}

class _CheckoutService extends _NoSuch implements CheckoutServiceInterface {}

class _OrderService extends _NoSuch implements OrderServiceInterface {}

/// customer/info: answers the queued results in order (null = failed request,
/// an Exception = thrown). [hold] keeps requests open to test concurrency.
class _ProfileService implements ProfileServiceInterface {
  final List<Object?> answers = <Object?>[];
  int requests = 0;
  Completer<void>? hold;

  @override
  Future<UserInfoModel?> getUserInfo() async {
    requests++;
    if (hold != null) await hold!.future;
    final Object? next = answers.removeAt(0);
    if (next is Exception) throw next;
    return next as UserInfoModel?;
  }

  @override
  Future<ResponseModel> updateProfile(UpdateUserModel userInfoModel, XFile? data, String token) async => ResponseModel(true, 'ok');
  @override
  Future<ResponseModel> changePassword(UserInfoModel userInfoModel) async => ResponseModel(true, 'ok');
  @override
  Future<Response> deleteUser() async => const Response(statusCode: 200);
  @override
  Future<XFile?> pickImageFromGallery() async => null;
  @override
  Future<Response> generateVirtualAccount() async => const Response(statusCode: 200);
}

/// The server's profile; carries an account number so no config fallback is needed.
UserInfoModel _profile(double walletBalance) => UserInfoModel(
  id: 1, fName: 'Francis', lName: 'A', walletBalance: walletBalance,
  virtualAccountNumber: '1100123456', virtualAccountName: 'MOONJOIN FRANCIS', bankName: '9PSB',
);

void main() {
  late _ProfileService service;
  late ProfileController profile;
  late _Auth auth;

  setUp(() async {
    Get.testMode = true;
    service = _ProfileService();
    profile = ProfileController(profileServiceInterface: service);
    auth = _Auth();
    Get.put<AuthController>(auth);
    Get.put<SplashController>(_Splash());
    Get.put<ProfileController>(profile);
    Get.put<CheckoutController>(CheckoutController(checkoutServiceInterface: _CheckoutService()));
    Get.put<OrderController>(OrderController(orderServiceInterface: _OrderService()));
  });

  tearDown(Get.reset);

  /// The app as it was when the profile was first loaded: ₦170.
  Future<void> loadedAt170() async {
    service.answers.add(_profile(170));
    await profile.getUserInfo();
    expect(profile.userInfoModel!.walletBalance, 170);
  }

  group('ProfileController.refreshUserInfo', () {
    test('stale balance is replaced by the authoritative server balance', () async {
      await loadedAt170();
      service.answers.add(_profile(5170));
      await profile.refreshUserInfo();
      expect(profile.userInfoModel!.walletBalance, 5170);
    });

    test('repeated triggers while a refresh is running share one request', () async {
      await loadedAt170();
      service.requests = 0;
      service.hold = Completer<void>();
      service.answers.add(_profile(5170));
      final List<Future<void>> calls = <Future<void>>[for (int i = 0; i < 5; i++) profile.refreshUserInfo()];
      expect(service.requests, 1);
      service.hold!.complete();
      await Future.wait(calls);
      expect(profile.userInfoModel!.walletBalance, 5170);

      service.hold = null;
      service.answers.add(_profile(6170));
      await profile.refreshUserInfo();
      expect(service.requests, 2, reason: 'a later trigger fetches again');
      expect(profile.userInfoModel!.walletBalance, 6170);
    });

    test('a failed request keeps the displayed balance (never zero or null)', () async {
      await loadedAt170();
      service.answers.add(null);
      await profile.refreshUserInfo();
      expect(profile.userInfoModel!.walletBalance, 170);
    });

    test('a thrown error keeps the balance and does not escape to the caller', () async {
      await loadedAt170();
      service.answers.add(Exception('timeout'));
      await profile.refreshUserInfo();
      expect(profile.userInfoModel!.walletBalance, 170);
      service.answers.add(_profile(5170));
      await profile.refreshUserInfo();
      expect(profile.userInfoModel!.walletBalance, 5170, reason: 'the next trigger is not blocked');
    });
  });

  group('add_fund push', () {
    test('logged in: refreshes from the server; the balance is the server value, not a local sum', () async {
      await loadedAt170();
      service.answers.add(_profile(300));
      NotificationHelper.syncWalletOnFundNotification(<String, dynamic>{'type': 'add_fund', 'amount': '5000'});
      await pumpEventQueue();
      expect(service.requests, 2);
      expect(profile.userInfoModel!.walletBalance, 300, reason: 'whatever the server says, never 170 + 5000');
    });

    test('a push during a running refresh fetches once more after it; the newer balance wins', () async {
      await loadedAt170();
      service.requests = 0;
      service.hold = Completer<void>();
      service.answers.add(_profile(170)); // sent before the credit
      service.answers.add(_profile(270)); // after the credit
      final Future<void> running = profile.refreshUserInfo();
      NotificationHelper.syncWalletOnFundNotification(<String, dynamic>{'type': 'add_fund'});
      NotificationHelper.syncWalletOnFundNotification(<String, dynamic>{'type': 'add_fund'});
      expect(service.requests, 1, reason: 'no parallel request');
      service.hold!.complete();
      await running;
      expect(service.requests, 2, reason: 'exactly one follow-up, however many pushes arrived');
      expect(profile.userInfoModel!.walletBalance, 270);

      await profile.refreshUserInfo();
      expect(service.requests, 3, reason: 'nothing left pending; the next trigger fetches normally');
    });

    test('ordinary triggers during a running refresh still share it (no follow-up)', () async {
      await loadedAt170();
      service.requests = 0;
      service.hold = Completer<void>();
      service.answers.add(_profile(270));
      final Future<void> running = profile.refreshUserInfo();
      profile.refreshUserInfo();
      service.hold!.complete();
      await running;
      expect(service.requests, 1);
    });

    test('other notification types and logged-out users do not request', () async {
      await loadedAt170();
      NotificationHelper.syncWalletOnFundNotification(<String, dynamic>{'type': 'order_status'});
      auth.loggedIn = false;
      NotificationHelper.syncWalletOnFundNotification(<String, dynamic>{'type': 'add_fund'});
      await pumpEventQueue();
      expect(service.requests, 1);
    });
  });

  group('Choose Payment Method sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Center(child: PaymentMethodBottomSheet(
        isCashOnDeliveryActive: true, isDigitalPaymentActive: false, isOfflinePaymentActive: false, totalPrice: 2000,
      )))));
    }

    testWidgets('opening the sheet shows the server balance, not the stale one', (WidgetTester tester) async {
      await loadedAt170();
      service.hold = Completer<void>();
      service.answers.add(_profile(5170));
      await openSheet(tester);
      await tester.pump();
      expect(service.requests, 2, reason: 'opening the sheet refreshes once');
      expect(find.text(PriceConverter.convertPrice(170)), findsWidgets, reason: 'last known balance while the request runs');

      service.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text(PriceConverter.convertPrice(5170)), findsWidgets);
      expect(find.text(PriceConverter.convertPrice(170)), findsNothing);
    });

    testWidgets('a credit confirmed while the sheet is open appears without reopening it', (WidgetTester tester) async {
      await loadedAt170();
      service.answers.add(_profile(170));
      await openSheet(tester);
      await tester.pump();
      await tester.pump();
      expect(find.text(PriceConverter.convertPrice(170)), findsWidgets);

      service.answers.add(_profile(5170));
      NotificationHelper.syncWalletOnFundNotification(<String, dynamic>{'type': 'add_fund'});
      await tester.pump();
      await tester.pump();
      expect(find.text(PriceConverter.convertPrice(5170)), findsWidgets);
    });

    testWidgets('a push that lands while the sheet-open refresh is still running updates the open sheet', (WidgetTester tester) async {
      await loadedAt170();
      service.hold = Completer<void>();
      service.answers.add(_profile(170)); // sheet-open request, sent before the credit
      service.answers.add(_profile(270)); // after the credit
      await openSheet(tester);
      await tester.pump();
      NotificationHelper.syncWalletOnFundNotification(<String, dynamic>{'type': 'add_fund'});
      service.hold!.complete();
      for (int i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(service.requests, 3, reason: 'initial load, sheet open, one follow-up for the push');
      expect(find.text(PriceConverter.convertPrice(270)), findsWidgets);
      expect(find.text(PriceConverter.convertPrice(170)), findsNothing);
    });

    testWidgets('a failed refresh while the sheet is open keeps the balance shown', (WidgetTester tester) async {
      await loadedAt170();
      service.answers.add(null);
      await openSheet(tester);
      await tester.pump();
      await tester.pump();
      expect(find.text(PriceConverter.convertPrice(170)), findsWidgets);
    });
  });
}
