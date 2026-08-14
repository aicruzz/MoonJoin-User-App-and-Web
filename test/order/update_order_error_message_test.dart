// Focused unit test for the Update Cart (order update) failure messaging.
//
// The backend financial guard returns HTTP 403 with an error whose
// `code == 'wallet'` when the edited order total exceeds the customer's wallet
// balance. The User App must surface a specific, user-understandable message for
// that case only, while every other failure keeps the existing generic wording.
//
// These assert the pure resolver `OrderEditController.updateFailureMessage` /
// `isWalletInsufficient`; no backend, network, or widget is involved.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/controllers/order_edit_controller.dart';

void main() {
  const String walletMsg =
      'Insufficient wallet balance. Your wallet balance is not enough to cover the updated order total.';
  const String genericMsg = 'Could not update your order. Please try again.';

  group('OrderEditController update-failure messaging', () {
    test('403 with code "wallet" → specific insufficient-wallet message', () {
      final Response response = Response(statusCode: 403, body: {
        'errors': [
          {'code': 'wallet', 'message': 'Customer has insufficient wallet balance'}
        ]
      });
      expect(OrderEditController.isWalletInsufficient(response), isTrue);
      expect(OrderEditController.updateFailureMessage(response), walletMsg);
    });

    test('unrelated 500 failure → existing generic message', () {
      final Response response = Response(statusCode: 500, body: {
        'errors': [
          {'code': 'server', 'message': 'Internal error'}
        ]
      });
      expect(OrderEditController.isWalletInsufficient(response), isFalse);
      expect(OrderEditController.updateFailureMessage(response), genericMsg);
    });

    test('403 with a non-wallet code → generic message (not broadened)', () {
      final Response response = Response(statusCode: 403, body: {
        'errors': [
          {'code': 'coupon', 'message': 'Coupon invalid'}
        ]
      });
      expect(OrderEditController.isWalletInsufficient(response), isFalse);
      expect(OrderEditController.updateFailureMessage(response), genericMsg);
    });

    test('malformed / non-error body → generic message, no crash', () {
      final Response bad = Response(statusCode: 403, body: 'not-json');
      final Response empty = Response(statusCode: 403, body: {'message': 'nope'});
      expect(OrderEditController.updateFailureMessage(bad), genericMsg);
      expect(OrderEditController.updateFailureMessage(empty), genericMsg);
    });
  });
}
