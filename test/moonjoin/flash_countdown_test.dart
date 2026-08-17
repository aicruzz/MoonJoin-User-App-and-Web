import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_flash_deal_card.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_flash_deals_section.dart';

// Proves the home Flash Deals countdown (A) always shows a ticking seconds block
// (so it can never LOOK static, the real device bug), rolls units correctly,
// reaches 00, and (B) actually advances on rebuild from an absolute end time —
// i.e. it does not reset to the original duration every second.
void main() {
  group('moonjoinFlashCountdownDigits — DAYS:HRS:MINS:SECS', () {
    test('short campaign keeps a 00 days block', () {
      expect(moonjoinFlashCountdownDigits(const Duration(hours: 1, minutes: 32, seconds: 18)), ['00', '01', '32', '18']);
    });

    test('days stay a SEPARATE block (never folded into total hours), seconds always present', () {
      final digits = moonjoinFlashCountdownDigits(const Duration(days: 5, hours: 2, seconds: 7));
      expect(digits, ['05', '02', '00', '07']);
      expect(digits.length, 4);
      expect(digits[0], '05'); // days separate, NOT 122 hours
      expect(digits[3], '07'); // seconds block present
    });

    test('units roll correctly', () {
      expect(moonjoinFlashCountdownDigits(const Duration(seconds: 90)), ['00', '00', '01', '30']);
      expect(moonjoinFlashCountdownDigits(const Duration(seconds: 61)), ['00', '00', '01', '01']);
      expect(moonjoinFlashCountdownDigits(const Duration(hours: 25)), ['01', '01', '00', '00']);
    });

    test('reaches and clamps at 00:00:00:00', () {
      expect(moonjoinFlashCountdownDigits(Duration.zero), ['00', '00', '00', '00']);
      expect(moonjoinFlashCountdownDigits(const Duration(seconds: -5)), ['00', '00', '00', '00']);
    });
  });

  testWidgets('home countdown visibly advances (ticks, does not reset)', (tester) async {
    final DateTime end = DateTime.now().add(const Duration(minutes: 2, seconds: 5));

    List<String> numericTexts() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => RegExp(r'^\d{2,3}$').hasMatch(s))
        .toList()
      ..sort();

    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeData(primaryColor: const Color(0xFF13A452), disabledColor: Colors.grey),
      home: Scaffold(
        body: MoonjoinFlashDealsSection(
          title: 'Flash Deals', subtitle: 'x', endTime: end, itemCount: 1,
          itemBuilder: (c, i) => const MoonjoinFlashDealCard(image: '', badgeText: 'X', title: 'T', flashPrice: 'N1'),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final before = numericTexts().join(',');

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final after = numericTexts().join(',');

    expect(after, isNot(equals(before)), reason: 'countdown did not tick (before=$before after=$after)');

    await tester.pumpWidget(const SizedBox()); // dispose → cancel timers
  });
}
