import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_flash_deal_card.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_flash_deals_section.dart';
import 'package:intl/intl.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:moonjoin/features/flash_sale/domain/models/flash_sale_model.dart';
import 'package:moonjoin/features/flash_sale/domain/services/flash_sale_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';

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

    // The countdown reads the real clock (endTime - DateTime.now()), which pump()
    // does not advance. Let real time pass first (sleep blocks without running timers), so the result no longer depends
    // on a real second boundary happening to fall inside the test.
    sleep(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(seconds: 1));
    final after = numericTexts().join(',');

    expect(after, isNot(equals(before)), reason: 'countdown did not tick (before=$before after=$after)');

    await tester.pumpWidget(const SizedBox()); // dispose → cancel timers
  });

  testWidgets('a countdown that reached 00 restarts for a new end time (next campaign)', (tester) async {
    String shown() => tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '')
        .where((s) => RegExp(r'^\d{2}$').hasMatch(s)).join(':');

    Future<void> pumpCountdown(DateTime end) => tester.pumpWidget(GetMaterialApp(
      theme: ThemeData(primaryColor: const Color(0xFF13A452), disabledColor: Colors.grey),
      home: Scaffold(body: MoonjoinFlashCountdown(endTime: end)),
    ));

    await pumpCountdown(DateTime.now().subtract(const Duration(seconds: 5)));
    await tester.pump(const Duration(seconds: 1)); // reaches zero, timer stops
    expect(shown(), '00:00:00:00');

    await pumpCountdown(DateTime.now().add(const Duration(minutes: 2, seconds: 5)));
    final String started = shown();
    expect(started, isNot('00:00:00:00'));

    sleep(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(seconds: 1));
    expect(shown(), isNot(started), reason: 'the new campaign countdown must tick, not freeze');

    await tester.pumpWidget(const SizedBox());
  });

  group('FlashSaleController countdown (home section visibility, web home timer)', () {
    late _FlashService service;
    late FlashSaleController controller;

    setUp(() {
      Get.testMode = true;
      Get.put<SplashController>(SplashController(splashServiceInterface: _SplashService()));
      service = _FlashService();
      controller = FlashSaleController(flashSaleServiceInterface: service);
    });

    tearDown(Get.reset);

    Future<void> load(WidgetTester tester, DateTime end) async {
      service.endDate = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(end.toUtc());
      await controller.getFlashSale(true, false, dataSource: DataSourceEnum.client);
    }

    testWidgets('stays correct when ticks were missed (app in background / throttled tab)', (tester) async {
      await load(tester, DateTime.now().add(const Duration(hours: 1)));
      expect(controller.duration!.inSeconds, inInclusiveRange(3598, 3600));

      // 2.5 s of real time with no tick (timers paused), then one tick.
      sleep(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(seconds: 1));
      expect(controller.duration!.inSeconds, inInclusiveRange(3590, 3597),
          reason: 'end - now; counting ticks would still say about 3599 s');

      await load(tester, DateTime.now().subtract(const Duration(minutes: 1))); // replace and stop the timer
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('reaches zero, never goes negative, and stops ticking', (tester) async {
      await load(tester, DateTime.now().add(const Duration(milliseconds: 900)));
      sleep(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(seconds: 1));
      expect(controller.duration, Duration.zero);

      int updates = 0;
      controller.addListener(() => updates++);
      await tester.pump(const Duration(seconds: 3));
      expect(updates, 0, reason: 'no ticking after the end');
      expect(controller.duration, Duration.zero);
    });

    testWidgets('an already-ended campaign shows zero (hidden on home), not a negative time', (tester) async {
      await load(tester, DateTime.now().subtract(const Duration(minutes: 10)));
      expect(controller.duration, Duration.zero);
      await tester.pump(const Duration(seconds: 1));
      expect(controller.duration, Duration.zero);
    });
  });
}

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}

class _FlashService extends _NoSuch implements FlashSaleServiceInterface {
  String? endDate;

  @override
  Future<FlashSaleModel?> getFlashSale(DataSourceEnum source) async => FlashSaleModel(id: 1, endDate: endDate);
}
