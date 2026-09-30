// Slice D2 — InFlightRequests: concurrent callers share one running request;
// the guard lasts only while the request runs (no TTL, no caching).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/helper/in_flight_requests.dart';

void main() {
  late InFlightRequests inFlight;
  late int started;
  late List<Completer<String>> pending;

  Future<String> request() {
    started++;
    final Completer<String> c = Completer<String>();
    pending.add(c);
    return c.future;
  }

  setUp(() {
    inFlight = InFlightRequests();
    started = 0;
    pending = <Completer<String>>[];
  });

  test('two simultaneous callers create ONE request and both get its result', () async {
    final Future<String> a = inFlight.run('k', request);
    final Future<String> b = inFlight.run('k', request);
    expect(started, 1);
    pending.single.complete('stores');
    expect(await a, 'stores');
    expect(await b, 'stores');
  });

  test('a call after completion starts a fresh request (explicit reload still refreshes)', () async {
    final Future<String> first = inFlight.run('k', request);
    pending.last.complete('v1');
    await first;
    expect(inFlight.isInFlight('k'), isFalse);

    final Future<String> reload = inFlight.run('k', request);
    expect(started, 2);
    pending.last.complete('v2');
    expect(await reload, 'v2');
  });

  test('failure is delivered to every sharing caller and clears the guard', () async {
    final Future<String> a = inFlight.run('k', request);
    final Future<String> b = inFlight.run('k', request);
    pending.single.completeError(StateError('network'));
    await expectLater(a, throwsStateError);
    await expectLater(b, throwsStateError);
    expect(inFlight.isInFlight('k'), isFalse);
  });

  test('a retry after failure works', () async {
    final Future<String> failed = inFlight.run('k', request);
    pending.last.completeError(StateError('network'));
    await expectLater(failed, throwsStateError);

    final Future<String> retry = inFlight.run('k', request);
    expect(started, 2);
    pending.last.complete('ok');
    expect(await retry, 'ok');
  });

  test('different keys are never shared', () async {
    final Future<String> food = inFlight.run('food', request);
    final Future<String> grocery = inFlight.run('grocery', request);
    expect(started, 2);
    pending[0].complete('food-stores');
    pending[1].complete('grocery-stores');
    expect(await food, 'food-stores');
    expect(await grocery, 'grocery-stores');
  });

  group('keyFor', () {
    test('equal headers in any order give the same key', () {
      expect(
        InFlightRequests.keyFor('/api/v1/banners', <String, String>{'moduleId': '3', 'zoneId': '[7]'}),
        InFlightRequests.keyFor('/api/v1/banners', <String, String>{'zoneId': '[7]', 'moduleId': '3'}),
      );
    });

    test('a different module, zone or language gives a different key', () {
      final String base = InFlightRequests.keyFor('/api/v1/banners', <String, String>{'moduleId': '3', 'zoneId': '[7]', 'X-localization': 'en'});
      expect(InFlightRequests.keyFor('/api/v1/banners', <String, String>{'moduleId': '5', 'zoneId': '[7]', 'X-localization': 'en'}), isNot(base));
      expect(InFlightRequests.keyFor('/api/v1/banners', <String, String>{'moduleId': '3', 'zoneId': '[8]', 'X-localization': 'en'}), isNot(base));
      expect(InFlightRequests.keyFor('/api/v1/banners', <String, String>{'moduleId': '3', 'zoneId': '[7]', 'X-localization': 'ar'}), isNot(base));
    });

    test('a different URI gives a different key', () {
      expect(InFlightRequests.keyFor('/api/v1/stores/latest?type=all', null), isNot(InFlightRequests.keyFor('/api/v1/stores/latest?type=veg', null)));
    });
  });
}
