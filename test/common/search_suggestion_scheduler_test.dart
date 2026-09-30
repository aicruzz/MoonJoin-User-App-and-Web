// Slice B — live autocomplete gating for the customer SearchScreen.
//
// SearchScreen's dependency surface (GetX controllers, splash config, scope
// sheet) makes a full widget test impractical, so these tests drive the exact
// scheduler instance type the screen uses. testWidgets supplies fake timers, so
// the 300 ms debounce is exercised deterministically with tester.pump.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/common/widgets/custom_debounce_widget.dart';
import 'package:moonjoin/helper/search_suggestion_scheduler.dart';

class _Harness {
  _Harness() {
    scheduler = SearchSuggestionScheduler(
      fetch: (query) {
        requests.add(query);
        final Completer<List<String>> c = Completer<List<String>>();
        pending[query] = c;
        return c.future;
      },
      currentText: () => text,
      onResult: (s) => shown = s,
      onClear: () {
        clears++;
        shown = null;
      },
    );
  }

  late final SearchSuggestionScheduler scheduler;
  final List<String> requests = <String>[];
  final Map<String, Completer<List<String>>> pending = <String, Completer<List<String>>>{};
  String text = '';
  List<String>? shown;
  int clears = 0;

  /// Mimics a user keystroke: the field changes, then onChanged fires.
  void type(String value) {
    text = value;
    scheduler.onTextChanged(value);
  }
}

const Duration _settle = Duration(milliseconds: 300);

void main() {
  group('threshold', () {
    testWidgets('empty, 1 and 2 characters never request', (tester) async {
      final h = _Harness();
      for (final String q in <String>['', 'c', 'ch']) {
        h.type(q);
        await tester.pump(_settle);
      }
      expect(h.requests, isEmpty);
    });

    testWidgets('exactly 3 characters is eligible after the debounce', (tester) async {
      final h = _Harness();
      h.type('chi');
      await tester.pump(const Duration(milliseconds: 299));
      expect(h.requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(h.requests, <String>['chi']);
    });

    testWidgets('dropping below 3 clears stale suggestions and drops the pending request', (tester) async {
      final h = _Harness();
      h.type('chi');
      await tester.pump(_settle);
      h.pending['chi']!.complete(<String>['Chicken Pie']);
      await tester.pump();
      expect(h.shown, <String>['Chicken Pie']);

      h.type('chic');
      h.type('ch'); // below threshold before the timer fires
      expect(h.shown, isNull);
      expect(h.clears, 1);
      await tester.pump(_settle);
      expect(h.requests, <String>['chi']);
    });
  });

  group('debounce', () {
    testWidgets('rapid typing requests only the final query', (tester) async {
      final h = _Harness();
      for (final String q in <String>['c', 'ch', 'chi', 'chic', 'chick']) {
        h.type(q);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(_settle);
      expect(h.requests, <String>['chick']);
    });

    testWidgets('a pause longer than 300 ms yields a separate request', (tester) async {
      final h = _Harness();
      h.type('chi');
      await tester.pump(const Duration(milliseconds: 350));
      h.type('chic');
      await tester.pump(const Duration(milliseconds: 350));
      expect(h.requests, <String>['chi', 'chic']);
    });
  });

  group('duplicate suppression', () {
    testWidgets('an unchanged query is not requested twice', (tester) async {
      final h = _Harness();
      h.type('chicken');
      await tester.pump(_settle);
      h.pending['chicken']!.complete(<String>['Chicken Burger']);
      await tester.pump();
      h.type('chicken');
      await tester.pump(_settle);
      expect(h.requests, <String>['chicken']);
    });

    testWidgets('clearing then re-entering the same query requests again', (tester) async {
      final h = _Harness();
      h.type('chicken');
      await tester.pump(_settle);
      h.pending['chicken']!.complete(<String>['Chicken Burger']);
      await tester.pump();
      h.type('');
      h.type('chicken');
      await tester.pump(_settle);
      expect(h.requests, <String>['chicken', 'chicken']);
    });

    testWidgets('an empty (failed or no-match) answer keeps the query retryable', (tester) async {
      final h = _Harness();
      h.type('chicken');
      await tester.pump(_settle);
      h.pending['chicken']!.complete(<String>[]);
      await tester.pump();
      h.type('chicken');
      await tester.pump(_settle);
      expect(h.requests, <String>['chicken', 'chicken']);
    });

    testWidgets('a thrown error keeps the query retryable and shows nothing', (tester) async {
      final h = _Harness();
      h.type('chicken');
      await tester.pump(_settle);
      h.pending['chicken']!.completeError(Exception('network'));
      await tester.pump();
      expect(h.shown, isNull);
      h.type('chicken');
      await tester.pump(_settle);
      expect(h.requests, <String>['chicken', 'chicken']);
    });
  });

  group('stale responses', () {
    testWidgets('a late "chi" answer cannot overwrite "chic"', (tester) async {
      final h = _Harness();
      h.type('chi');
      await tester.pump(_settle);
      h.type('chic');
      await tester.pump(_settle);
      expect(h.requests, <String>['chi', 'chic']);

      h.pending['chic']!.complete(<String>['Chicken & Chips']);
      await tester.pump();
      h.pending['chi']!.complete(<String>['Chilli Sauce']);
      await tester.pump();
      expect(h.shown, <String>['Chicken & Chips']);
    });

    testWidgets('an answer for text no longer in the field is dropped and the query released', (tester) async {
      final h = _Harness();
      h.type('chi');
      await tester.pump(_settle);
      h.type('chic'); // debounce pending, no newer request yet
      h.pending['chi']!.complete(<String>['Chilli Sauce']);
      await tester.pump();
      expect(h.shown, isNull);

      h.type('chi'); // back to the released query before the timer fired
      await tester.pump(_settle);
      expect(h.requests, <String>['chi', 'chi']);
    });

    testWidgets('a field cleared programmatically (clear icon) skips the armed request', (tester) async {
      final h = _Harness();
      h.type('chicken');
      h.text = ''; // clear icon sets controller.text, no onChanged
      await tester.pump(_settle);
      expect(h.requests, isEmpty);
    });
  });

  group('disposal', () {
    testWidgets('dispose cancels the pending debounce', (tester) async {
      final h = _Harness();
      h.type('chicken');
      h.scheduler.dispose();
      await tester.pump(_settle);
      expect(h.requests, isEmpty);
    });

    testWidgets('an answer arriving after dispose is ignored', (tester) async {
      final h = _Harness();
      h.type('chicken');
      await tester.pump(_settle);
      h.scheduler.dispose();
      h.pending['chicken']!.complete(<String>['Chicken Pie']);
      await tester.pump();
      expect(h.shown, isNull);
      h.type('chickens');
      await tester.pump(_settle);
      expect(h.requests, <String>['chicken']);
    });
  });

  testWidgets('partial autocomplete still works: "chi" shows chicken suggestions', (tester) async {
    final h = _Harness();
    h.type('chi');
    await tester.pump(_settle);
    h.pending['chi']!.complete(<String>['Chicken Pie', 'Chicken Burger', 'Chicken & Chips']);
    await tester.pump();
    expect(h.shown, <String>['Chicken Pie', 'Chicken Burger', 'Chicken & Chips']);
  });

  group('CustomDebounceWidget.cancel', () {
    testWidgets('drops the pending action and is safe when idle', (tester) async {
      final CustomDebounceWidget d = CustomDebounceWidget(milliseconds: 300);
      int runs = 0;
      d.cancel();
      d.run(() => runs++);
      d.cancel();
      await tester.pump(_settle);
      expect(runs, 0);
      d.run(() => runs++);
      await tester.pump(_settle);
      expect(runs, 1);
    });
  });
}
