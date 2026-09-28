// Focused tests for the 9PSB gateway-visibility regression.
//
// Root cause: in the Checkout payment sheet, the 9PSB virtual-account card was
// nested inside walletView(), which early-returned when walletBalance <= 0 and
// whose Column additionally required walletBalance > 0. So a customer with an
// empty wallet never saw the card, even with the 9PSB gateway enabled — even
// though the virtual account is precisely what FUNDS an empty wallet.
//
// Secondary defect: profile_screen and web_profile_widget rendered the card on
// `isLoggedIn` alone, ignoring the gateway configuration that Menu, Wallet Add
// Fund and Checkout already honour.
//
// Test layering: the gateway rule is pure and is tested directly. The rendered
// card is tested through the EXISTING VirtualAccountDetailsWidget. A full
// PaymentMethodBottomSheet widget test is NOT attempted: that sheet resolves
// SplashController, ProfileController, CheckoutController and OrderController,
// and SplashController exposes no setter for configModel (it is only populated
// by the full config-response pipeline, which also drives modules and caching).
// Faking all four would be brittle and would not test the real wiring, so the
// balance-independence of the 9PSB gate is covered by a structural guard below.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/features/checkout/widgets/virtual_account_details_widget.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/profile/domain/models/update_user_model.dart';
import 'package:moonjoin/features/profile/domain/models/userinfo_model.dart';
import 'package:moonjoin/features/profile/domain/services/profile_service_interface.dart';
import 'package:moonjoin/helper/payment_gateway_helper.dart';

/// Mirrors the live production payload: {"gateway": "9psb"|"flutterwave"|"paystack"}
List<PaymentBody> methods(List<String> gateways) =>
    gateways.map((String g) => PaymentBody(getWay: g, getWayTitle: g)).toList();

class StubProfileService implements ProfileServiceInterface {
  StubProfileService(this.profile);
  final UserInfoModel? profile;

  @override
  Future<UserInfoModel?> getUserInfo() async => profile;

  @override
  Future<Response> generateVirtualAccount() async => const Response(statusCode: 200);

  @override
  Future<ResponseModel> updateProfile(UpdateUserModel userInfoModel, XFile? data, String token) async =>
      ResponseModel(true, 'ok');

  @override
  Future<ResponseModel> changePassword(UserInfoModel userInfoModel) async => ResponseModel(true, 'ok');

  @override
  Future<Response> deleteUser() async => const Response(statusCode: 200);

  @override
  Future<XFile?> pickImageFromGallery() async => null;
}

/// Holds generation open so the loading state can be observed.
class SlowProfileService extends StubProfileService {
  SlowProfileService() : super(UserInfoModel(id: 1, walletBalance: 0));
  final Completer<void> _gate = Completer<void>();
  void release() => _gate.complete();

  @override
  Future<Response> generateVirtualAccount() async {
    await _gate.future;
    return const Response(statusCode: 500, statusText: 'unavailable', body: <String, dynamic>{});
  }
}

void main() {
  tearDown(Get.reset);

  group('gateway configuration rule (shared helper)', () {
    test('9PSB active when the backend lists it — alongside Flutterwave/Paystack', () {
      final List<PaymentBody> live = methods(<String>['9psb', 'flutterwave', 'paystack']);
      expect(is9PSBActive(methods: live), isTrue);
      // Paystack and Flutterwave are unaffected by the 9PSB rule.
      expect(isPaymentGatewayActive('paystack', methods: live), isTrue);
      expect(isPaymentGatewayActive('flutterwave', methods: live), isTrue);
    });

    test('9PSB inactive when Admin disables it — others keep working', () {
      final List<PaymentBody> off = methods(<String>['flutterwave', 'paystack']);
      expect(is9PSBActive(methods: off), isFalse);
      expect(isPaymentGatewayActive('paystack', methods: off), isTrue);
      expect(isPaymentGatewayActive('flutterwave', methods: off), isTrue);
    });

    test('matching is case-insensitive and tolerant of null/empty configuration', () {
      expect(is9PSBActive(methods: methods(<String>['9PSB'])), isTrue);
      expect(is9PSBActive(methods: <PaymentBody>[]), isFalse);
      expect(is9PSBActive(methods: <PaymentBody>[PaymentBody()]), isFalse);
    });

    test('no SplashController registered -> inactive, never a crash', () {
      expect(is9PSBActive(), isFalse);
      expect(isPaymentGatewayActive('paystack'), isFalse);
    });
  });

  group('existing VirtualAccountDetailsWidget renders the stored account', () {
    testWidgets('real account number/name/bank appear, never N/A', (WidgetTester tester) async {
      Get.reset();
      Get.put(ProfileController(
        profileServiceInterface: StubProfileService(UserInfoModel(
          id: 1, fName: 'Francis', walletBalance: 0,
          virtualAccountNumber: '1100123456', virtualAccountName: 'MOONJOIN FRANCIS', bankName: '9PSB',
        )),
      ));
      await Get.find<ProfileController>().getUserInfo();

      await tester.pumpWidget(const GetMaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: VirtualAccountDetailsWidget(detailsOnly: true))),
      ));
      await tester.pump();
      while (tester.takeException() != null) {}

      expect(find.text('1100123456'), findsOneWidget);
      expect(find.text('MOONJOIN FRANCIS'), findsOneWidget);
      expect(find.text('N/A'), findsNothing);
    });

    testWidgets('a zero wallet balance does not affect the card itself', (WidgetTester tester) async {
      Get.reset();
      Get.put(ProfileController(
        profileServiceInterface: StubProfileService(UserInfoModel(
          id: 1, walletBalance: 0,
          virtualAccountNumber: '1100999888', virtualAccountName: 'ZERO BALANCE', bankName: '9PSB',
        )),
      ));
      await Get.find<ProfileController>().getUserInfo();

      await tester.pumpWidget(const GetMaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: VirtualAccountDetailsWidget(detailsOnly: true))),
      ));
      await tester.pump();
      while (tester.takeException() != null) {}

      expect(find.text('1100999888'), findsOneWidget);
    });
  });

  group('Checkout entry point: generate without leaving Checkout', () {
    Future<void> pumpCard(WidgetTester tester, UserInfoModel? profile, {required bool allowGenerate}) async {
      Get.reset();
      Get.put(ProfileController(profileServiceInterface: StubProfileService(profile)));
      if (profile?.virtualAccountNumber != null) {
        await Get.find<ProfileController>().getUserInfo();
      }
      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VirtualAccountDetailsWidget(detailsOnly: true, allowGenerate: allowGenerate),
          ),
        ),
      ));
      await tester.pump();
      while (tester.takeException() != null) {}
    }

    testWidgets('no account + allowGenerate -> the EXISTING generate affordance is offered',
        (WidgetTester tester) async {
      await pumpCard(tester, UserInfoModel(id: 1, walletBalance: 0), allowGenerate: true);
      expect(find.text('generate_virtual_account'), findsOneWidget);
      // The funding placeholder is replaced, not shown alongside.
      expect(find.text('transfer_to_virtual_account_to_top_up_wallet'), findsNothing);
    });

    testWidgets('no account WITHOUT allowGenerate keeps the existing placeholder (Wallet "+")',
        (WidgetTester tester) async {
      await pumpCard(tester, UserInfoModel(id: 1, walletBalance: 0), allowGenerate: false);
      expect(find.text('transfer_to_virtual_account_to_top_up_wallet'), findsOneWidget);
      expect(find.text('generate_virtual_account'), findsNothing);
    });

    testWidgets('an existing account shows the details card, never a redundant generate action',
        (WidgetTester tester) async {
      await pumpCard(
        tester,
        UserInfoModel(id: 1, walletBalance: 0,
            virtualAccountNumber: '1100123456', virtualAccountName: 'MOONJOIN FRANCIS', bankName: '9PSB'),
        allowGenerate: true,
      );
      expect(find.text('1100123456'), findsOneWidget);
      expect(find.text('generate_virtual_account'), findsNothing);
      expect(find.text('N/A'), findsNothing);
    });

    testWidgets('while generating, the loading shell replaces the button so a second tap is impossible',
        (WidgetTester tester) async {
      Get.reset();
      final SlowProfileService slow = SlowProfileService();
      Get.put(ProfileController(profileServiceInterface: slow));
      await tester.pumpWidget(const GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VirtualAccountDetailsWidget(detailsOnly: true, allowGenerate: true),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('generate_virtual_account'), findsOneWidget);

      unawaited(Get.find<ProfileController>().generateVirtualAccount());
      await tester.pump();
      while (tester.takeException() != null) {}

      // Button gone, spinner shown -> the affordance cannot be tapped twice.
      expect(find.text('generate_virtual_account'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      slow.release();
      await tester.pumpAndSettle();
      while (tester.takeException() != null) {}
    });
  });

  group('structural guards for the regression (see header note)', () {
    String source(String path) => File(path).readAsStringSync();

    test('Checkout: the 9PSB gate is independent of wallet balance', () {
      final String s = source('lib/features/checkout/widgets/payment_method_bottom_sheet.dart');

      // The 9PSB visibility flag must not consider the balance.
      final RegExp flag = RegExp(r'final bool showVirtualAccount = ([^;]+);');
      final RegExpMatch? m = flag.firstMatch(s);
      expect(m, isNotNull, reason: 'showVirtualAccount flag missing');
      expect(m!.group(1), contains('_is9PSBActive'));
      expect(m.group(1), isNot(contains('walletBalance')));
      expect(m.group(1), isNot(contains('totalPrice')));

      // walletView must no longer bail out before the 9PSB card is considered.
      expect(
        s.contains('if(walletBalance <= 0 || (widget.paymentModel != null && walletBalance < widget.totalPrice)) {\n      return const SizedBox();'),
        isFalse,
        reason: 'the balance early-return still short-circuits the 9PSB card',
      );

      // The card is rendered by the shared widget under the 9PSB flag.
      expect(s.contains('if(showVirtualAccount) ...['), isTrue);
      expect(s.contains('VirtualAccountDetailsWidget(detailsOnly: true'), isTrue);
    });

    test('Checkout: 9PSB is still excluded from the normal selectable gateway rows', () {
      final String s = source('lib/features/checkout/widgets/payment_method_bottom_sheet.dart');
      expect(s.contains("allMethods.where((m) => m.getWay?.toLowerCase() != '9psb')"), isTrue,
          reason: 'nonPSBMethods filtering must stay exactly as designed');
    });

    test('every 9PSB surface reads the one shared gateway helper', () {
      for (final String path in <String>[
        'lib/features/checkout/widgets/payment_method_bottom_sheet.dart',
        'lib/features/menu/screens/menu_screen.dart',
        'lib/features/profile/screens/profile_screen.dart',
        'lib/features/profile/widgets/web_profile_widget.dart',
      ]) {
        final String s = source(path);
        expect(s.contains('payment_gateway_helper.dart'), isTrue, reason: '$path must use the shared helper');
        expect(s.contains('is9PSBActive'), isTrue, reason: '$path must consult the gateway config');
        // No surface may re-derive the gateway list itself.
        expect(s.contains("m.getWay?.toLowerCase() == '9psb'"), isFalse,
            reason: '$path duplicates the gateway rule instead of reusing the helper');
      }
    });

    test('Profile surfaces gate the card on the gateway, not just sign-in', () {
      for (final String path in <String>[
        'lib/features/profile/screens/profile_screen.dart',
        'lib/features/profile/widgets/web_profile_widget.dart',
      ]) {
        final String s = source(path);
        expect(s.contains('(isLoggedIn && is9PSBActive()) ? const VirtualAccountDetailsWidget'), isTrue,
            reason: '$path must hide the card when the gateway is off');
      }
    });
  });
}
