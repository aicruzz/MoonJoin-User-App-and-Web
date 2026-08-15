// Focused test for null-safe timestamp parsing in the shared wallet/loyalty
// Transaction model. Production 9PSB `add_fund` rows can arrive with
// created_at and/or updated_at = null; the model must parse them without
// throwing (previously `DateTime.parse(null)` threw a TypeError and left
// Wallet History stuck on the loading shimmer).

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';

Map<String, dynamic> _row({dynamic created, dynamic updated}) => {
      "user_id": 14,
      "transaction_id": "100033260814191630531720822577",
      "credit": 100,
      "debit": 0,
      "admin_bonus": 0,
      "balance": 22956,
      "transaction_type": "add_fund",
      "reference": "CUST-VA-ededfee6",
      "created_at": created,
      "updated_at": updated,
    };

void main() {
  group('Transaction.fromJson — null-safe timestamps', () {
    test('A: created_at set, updated_at null → createdAt non-null, updatedAt null', () {
      final t = Transaction.fromJson(_row(created: "2026-08-15 00:35:58", updated: null));
      expect(t.createdAt, isNotNull);
      expect(t.updatedAt, isNull);
    });

    test('B: both null → both null, must NOT throw', () {
      final t = Transaction.fromJson(_row(created: null, updated: null));
      expect(t.createdAt, isNull);
      expect(t.updatedAt, isNull);
    });

    test('C: both valid → both parsed', () {
      final t = Transaction.fromJson(_row(created: "2026-08-15 00:35:58", updated: "2026-08-15 00:35:58"));
      expect(t.createdAt, isNotNull);
      expect(t.updatedAt, isNotNull);
    });
  });

  test('Wallet History page containing the production row (updated_at null) parses without throwing', () {
    final page = {
      "total_size": 1,
      "limit": "10",
      "offset": "1",
      "data": [_row(created: "2026-08-15 00:35:58", updated: null)],
    };
    final model = TransactionModel.fromJson(page);
    expect(model.data, isNotNull);
    expect(model.data!.length, 1);
    expect(model.data!.first.createdAt, isNotNull);
    expect(model.data!.first.updatedAt, isNull);
  });

  test('toJson with null timestamps does not throw and emits null', () {
    final j = Transaction.fromJson(_row(created: null, updated: null)).toJson();
    expect(j["created_at"], isNull);
    expect(j["updated_at"], isNull);
  });
}
