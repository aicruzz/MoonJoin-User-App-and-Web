// CheckoutRepository.getDmTipMostTapped must survive a null `most_tips_amount`.
//
// /api/v1/most-tips answers 200 with {"most_tips_amount": null} whenever no order
// carries a non-zero dm_tips -- the live production response today. Assigning that
// into the method's `int` threw "Null is not a subtype of int" on every checkout
// open (and every parcel request, which calls the same repository method).
//
// `orders.dm_tips` is double(24,2), so a real value can decode as a double; that
// would have been rejected by the same int assignment.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_connect/connect.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers the next queued response and records the URIs requested.
class _FakeApiClient implements ApiClient {
  _FakeApiClient(this._body, {this.statusCode = 200});
  final dynamic _body;
  final int statusCode;
  final List<String> calls = <String>[];

  @override
  Map<String, String> getHeader() => <String, String>{'moduleId': '3', 'zoneId': '[7]'};

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    calls.add(uri);
    return Response(statusCode: statusCode, body: _body);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<int> _run(dynamic body, {int statusCode = 200, _FakeApiClient? client}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final _FakeApiClient api = client ?? _FakeApiClient(body, statusCode: statusCode);
  return CheckoutRepository(apiClient: api, sharedPreferences: prefs).getDmTipMostTapped();
}

void main() {
  group('getDmTipMostTapped', () {
    test('returns the value for a normal integer response', () async {
      expect(await _run(<String, dynamic>{'most_tips_amount': 100}), 100);
    });

    test('does not throw for the legitimate null response, and defaults to 0', () async {
      // The regression: this threw "Null is not a subtype of int".
      expect(await _run(<String, dynamic>{'most_tips_amount': null}), 0);
    });

    test('null response completes normally rather than raising', () async {
      await expectLater(_run(<String, dynamic>{'most_tips_amount': null}), completion(isA<int>()));
    });

    test('coerces a double to int, matching the double(24,2) column', () async {
      expect(await _run(<String, dynamic>{'most_tips_amount': 100.0}), 100);
      expect(await _run(<String, dynamic>{'most_tips_amount': 150.75}), 150);
    });

    test('coerces a numeric string', () async {
      expect(await _run(<String, dynamic>{'most_tips_amount': '100.00'}), 100);
    });

    test('keeps the existing 0 default for a missing key', () async {
      expect(await _run(<String, dynamic>{}), 0);
    });

    test('keeps the existing 0 default for a non-200 response', () async {
      expect(await _run(<String, dynamic>{'most_tips_amount': 100}, statusCode: 500), 0);
    });

    test('a zero response still returns 0', () async {
      expect(await _run(<String, dynamic>{'most_tips_amount': 0}), 0);
    });

    test('calls the most-tips endpoint exactly once', () async {
      final _FakeApiClient api = _FakeApiClient(<String, dynamic>{'most_tips_amount': null});
      await _run(null, client: api);
      expect(api.calls, <String>[AppConstants.mostTipsUri]);
    });
  });

  group('tip chip semantics: 0 and null are equivalent', () {
    // isSuggested: index != 0 && options[index] == mostTipAmount.toString()
    // options() is ['0', ...amounts, 'custom'], so '0' only ever sits at index 0,
    // which the guard excludes. Defaulting null to 0 therefore badges nothing --
    // identical to the pre-fix null rendering.
    bool badges(List<String> options, int index, int? mostTipAmount) =>
        index != 0 && options[index] == mostTipAmount.toString();

    final List<String> options = <String>['0', '50', '100', 'custom'];

    test('neither null nor 0 badges any chip', () {
      for (int i = 0; i < options.length; i++) {
        expect(badges(options, i, null), isFalse, reason: 'null badged index $i');
        expect(badges(options, i, 0), isFalse, reason: '0 badged index $i');
      }
    });

    test('a real suggestion still badges its chip', () {
      expect(badges(options, 2, 100), isTrue);
      expect(badges(options, 1, 100), isFalse);
    });

    test('an int-coerced double now matches a chip where "100.0" would not', () {
      expect(badges(options, 2, 100), isTrue);
      expect(options[2] == 100.0.toString(), isFalse, reason: '"100.0" never matched "100"');
    });
  });
}
