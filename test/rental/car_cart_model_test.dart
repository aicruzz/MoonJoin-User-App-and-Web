import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';

/// Regression test for the Checkout "read error": the backend echoes
/// `pickup_time` as ISO-8601 UTC on add-to-cart but as `yyyy-MM-dd HH:mm:ss`
/// elsewhere; the strict checkout parser threw a FormatException on the ISO form.
/// `UserData.fromJson` now normalises both to canonical local `yyyy-MM-dd HH:mm:ss`.
void main() {
  group('UserData.pickup_time normalisation', () {
    test('ISO-8601 UTC (add-to-cart echo) becomes canonical local form', () {
      final u = UserData.fromJson({'id': 1, 'pickup_time': '2026-07-22T21:48:55.000000Z'});
      expect(u.pickupTime, isNotNull);
      expect(u.pickupTime!.contains('T'), isFalse);
      // Canonical shape parses with the strict checkout parser format.
      expect(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(u.pickupTime!), isTrue);
    });

    test('canonical form passes through untouched', () {
      final u = UserData.fromJson({'id': 1, 'pickup_time': '2026-07-22 22:48:55'});
      expect(u.pickupTime, '2026-07-22 22:48:55');
    });

    test('null stays null — nothing fabricated', () {
      final u = UserData.fromJson({'id': 1});
      expect(u.pickupTime, isNull);
    });
  });
}
