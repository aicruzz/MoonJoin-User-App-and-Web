// Focused tests for the pre-existing 9PSB virtual-account defects in the EXISTING
// ProfileController.generateVirtualAccount() flow.
//
// The backend has always answered 201 when it creates the account and 200 when one
// already exists, returning {message, data:{account_number, account_name, bank_name,
// end_user_id}}. The controller previously accepted only 200 and stored the outer
// envelope, so a freshly created account was rejected outright and an existing one
// rendered as 'N/A' in the approved details card.
//
// These are widget tests rather than plain unit tests because the existing controller
// calls showCustomSnackBar, which resolves ScaffoldMessenger.of(Get.context!) — there
// is no Get.context outside a pumped GetMaterialApp, so a unit test would throw before
// reaching the assertions. No new test framework is introduced; this follows the
// widget-test pattern already used in test/moonjoin/.
//
// The tests drive the EXISTING VirtualAccountDetailsWidget. No new UI or workflow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/features/checkout/widgets/virtual_account_details_widget.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/profile/domain/models/update_user_model.dart';
import 'package:moonjoin/features/profile/domain/models/userinfo_model.dart';
import 'package:moonjoin/features/profile/domain/services/profile_service_interface.dart';

/// Exactly the production envelope shape.
Map<String, dynamic> envelope({
  String accountNumber = '1100123456',
  String accountName = 'MOONJOIN FRANCIS',
  String bankName = '9PSB',
}) =>
    <String, dynamic>{
      'message': 'Virtual account created successfully',
      'data': <String, dynamic>{
        'account_number': accountNumber,
        'account_name': accountName,
        'bank_name': bankName,
        'end_user_id': 'EU-001',
      },
    };

class FakeProfileService implements ProfileServiceInterface {
  FakeProfileService({required this.response, this.profile});

  final Response response;

  /// What the existing profile refresh returns after generation.
  final UserInfoModel? profile;

  int getUserInfoCalls = 0;

  @override
  Future<Response> generateVirtualAccount() async => response;

  @override
  Future<UserInfoModel?> getUserInfo() async {
    getUserInfoCalls++;
    return profile;
  }

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

/// A profile carrying an account number, so the existing refresh path runs without
/// needing the SplashController config fallback.
UserInfoModel profileWithAccount(String number) => UserInfoModel(
      id: 1, fName: 'Francis', lName: 'A', email: 'a@b.c', phone: '+2348000000000',
      virtualAccountNumber: number, virtualAccountName: 'PROFILE NAME', bankName: '9PSB',
    );

Future<ProfileController> pumpExistingWidget(WidgetTester tester, FakeProfileService service) async {
  Get.reset();
  final ProfileController controller = Get.put(ProfileController(profileServiceInterface: service));
  await tester.pumpWidget(const GetMaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: VirtualAccountDetailsWidget())),
  ));
  await tester.pump();
  return controller;
}

/// Drains non-fatal framework exceptions (snackbar/asset noise) exactly as the
/// existing widget tests in test/moonjoin/ do.
void drain(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

void main() {
  tearDown(Get.reset);

  testWidgets('HTTP 201 (created) is a success, the data envelope is unwrapped, and the '
      'account number reaches the existing UI state', (WidgetTester tester) async {
    final FakeProfileService service = FakeProfileService(
      response: Response(statusCode: 201, body: envelope()),
      // Profile deliberately reports a different number, so this also proves the
      // freshly returned account is what the existing state ends up holding.
      profile: profileWithAccount('9999999999'),
    );
    final ProfileController controller = await pumpExistingWidget(tester, service);

    await controller.generateVirtualAccount();
    await tester.pump();
    drain(tester);

    expect(controller.virtualAccountData, isNotNull);
    expect(controller.virtualAccountData!['account_number'], '1100123456');
    expect(controller.virtualAccountData!['account_name'], 'MOONJOIN FRANCIS');
    expect(controller.virtualAccountData!['bank_name'], '9PSB');
    // The outer envelope must never be stored.
    expect(controller.virtualAccountData!.containsKey('message'), isFalse);
    expect(controller.virtualAccountData!.containsKey('data'), isFalse);
    expect(controller.isGeneratingAccount, isFalse);

    // The existing details card now shows the real account instead of 'N/A'.
    expect(find.text('1100123456'), findsOneWidget);
    expect(find.text('MOONJOIN FRANCIS'), findsOneWidget);
    expect(find.text('N/A'), findsNothing);
  });

  testWidgets('HTTP 200 (already exists) is a success and the existing account data is available',
      (WidgetTester tester) async {
    final FakeProfileService service = FakeProfileService(
      response: Response(
          statusCode: 200, body: envelope(accountNumber: '1100999888', accountName: 'EXISTING NAME')),
      profile: profileWithAccount('1100999888'),
    );
    final ProfileController controller = await pumpExistingWidget(tester, service);

    await controller.generateVirtualAccount();
    await tester.pump();
    drain(tester);

    expect(controller.virtualAccountData, isNotNull);
    expect(controller.virtualAccountData!['account_number'], '1100999888');
    expect(controller.virtualAccountData!['account_name'], 'EXISTING NAME');
    expect(controller.virtualAccountData!.containsKey('message'), isFalse);
    expect(find.text('1100999888'), findsOneWidget);
  });

  testWidgets('successful generation invokes the existing profile refresh mechanism',
      (WidgetTester tester) async {
    final FakeProfileService service = FakeProfileService(
      response: Response(statusCode: 201, body: envelope()),
      profile: profileWithAccount('1100123456'),
    );
    final ProfileController controller = await pumpExistingWidget(tester, service);
    expect(service.getUserInfoCalls, 0);

    await controller.generateVirtualAccount();
    await tester.pump();
    drain(tester);

    expect(service.getUserInfoCalls, 1);
    expect(controller.userInfoModel, isNotNull);
    expect(controller.userInfoModel!.virtualAccountNumber, '1100123456');
  });

  testWidgets('4xx is a failure: no account state is populated and the refresh is not run',
      (WidgetTester tester) async {
    final FakeProfileService service = FakeProfileService(
      response: const Response(statusCode: 422, statusText: 'Unprocessable', body: <String, dynamic>{}),
    );
    final ProfileController controller = await pumpExistingWidget(tester, service);

    await controller.generateVirtualAccount();
    await tester.pump();
    drain(tester);

    expect(controller.virtualAccountData, isNull);
    expect(service.getUserInfoCalls, 0);
    expect(controller.isGeneratingAccount, isFalse);
    expect(find.text('N/A'), findsNothing);
  });

  testWidgets('5xx is a failure: no fake account state is invented', (WidgetTester tester) async {
    final FakeProfileService service = FakeProfileService(
      response: const Response(statusCode: 500, statusText: 'Server error', body: <String, dynamic>{}),
    );
    final ProfileController controller = await pumpExistingWidget(tester, service);

    await controller.generateVirtualAccount();
    await tester.pump();
    drain(tester);

    expect(controller.virtualAccountData, isNull);
    expect(service.getUserInfoCalls, 0);
  });

  testWidgets('a 2xx response without a usable data envelope does not invent account state',
      (WidgetTester tester) async {
    final FakeProfileService service = FakeProfileService(
      response: const Response(statusCode: 201, body: <String, dynamic>{'message': 'created'}),
      profile: null,
    );
    final ProfileController controller = await pumpExistingWidget(tester, service);

    await controller.generateVirtualAccount();
    await tester.pump();
    drain(tester);

    // No data key -> nothing stored; the existing generate affordance stays.
    expect(controller.virtualAccountData, isNull);
    expect(service.getUserInfoCalls, 1);
  });
}
