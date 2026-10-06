// MoonJoinNotificationBanner.show() — the in-app notification banner. It used
// Overlay.of(Get.overlayContext ?? Get.context): that context is the Overlay's
// own child (above every overlay entry), so the lookup failed with
// "Null check operator used on a null value" for every foreground push and for
// the unavailable-items banner. It now inserts into the root Navigator's overlay
// (Get.key.currentState.overlay); the banner itself is unchanged.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_motion.dart';
import 'package:moonjoin/common/widgets/moonjoin/notifications/moonjoin_notification_banner.dart';

const Duration _settle = Duration(milliseconds: 600); // > the 400 ms entrance / exit animation

MoonJoinNotificationData _data(String title, {VoidCallback? onTap, Duration? autoDismiss = const Duration(seconds: 5)}) =>
    MoonJoinNotificationData(title: title, message: '$title message', state: MoonJoinMotionState.delivered, onTap: onTap, autoDismiss: autoDismiss);

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Text('home'))));
}

/// Leaves no banner (and no pending auto-dismiss timer) behind.
Future<void> _closeBanner(WidgetTester tester) async {
  MoonJoinNotificationBanner.dismiss();
  await tester.pump(_settle);
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('show() called outside any widget context displays the banner without throwing', (WidgetTester tester) async {
    await _pumpApp(tester);

    MoonJoinNotificationBanner.show(_data('Order confirmed'));
    await tester.pump(_settle);

    expect(tester.takeException(), isNull, reason: 'the old Overlay.of(Get.overlayContext) lookup threw here');
    expect(find.text('Order confirmed'), findsOneWidget);
    expect(find.text('Order confirmed message'), findsOneWidget);
    await _closeBanner(tester);
  });

  testWidgets('banner appears above an open dialog and receives the tap', (WidgetTester tester) async {
    await _pumpApp(tester);
    Get.dialog(const AlertDialog(content: Text('dialog body')));
    await tester.pump(_settle);
    int taps = 0;

    MoonJoinNotificationBanner.show(_data('On its way', onTap: () => taps++));
    await tester.pump(_settle);

    expect(find.text('dialog body'), findsOneWidget);
    expect(find.text('On its way'), findsOneWidget);
    await tester.tap(find.text('On its way'));
    await tester.pump(_settle);
    expect(taps, 1, reason: 'the banner is the top-most layer, above the dialog barrier');
  });

  testWidgets('a second show() replaces the first: exactly one banner visible', (WidgetTester tester) async {
    await _pumpApp(tester);

    MoonJoinNotificationBanner.show(_data('First'));
    await tester.pump(_settle);
    MoonJoinNotificationBanner.show(_data('Second'));
    await tester.pump(_settle);

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    await _closeBanner(tester);
  });

  testWidgets('auto-dismiss removes the banner after its duration', (WidgetTester tester) async {
    await _pumpApp(tester);

    MoonJoinNotificationBanner.show(_data('Auto', autoDismiss: const Duration(seconds: 2)));
    await tester.pump(_settle);
    expect(find.text('Auto'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(_settle);
    expect(find.text('Auto'), findsNothing);
  });

  testWidgets('autoDismiss: null stays until dismiss()', (WidgetTester tester) async {
    await _pumpApp(tester);

    MoonJoinNotificationBanner.show(_data('Persistent', autoDismiss: null));
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Persistent'), findsOneWidget);

    await _closeBanner(tester);
    expect(find.text('Persistent'), findsNothing);
  });

  testWidgets('tapping the banner fires onTap exactly once and closes it', (WidgetTester tester) async {
    await _pumpApp(tester);
    int taps = 0;

    MoonJoinNotificationBanner.show(_data('Tap me', onTap: () => taps++));
    await tester.pump(_settle);
    await tester.tap(find.text('Tap me'));
    await tester.pump(_settle);

    expect(taps, 1);
    expect(find.text('Tap me'), findsNothing);
  });

  testWidgets('show() before the Navigator exists returns without throwing', (WidgetTester tester) async {
    expect(Get.key.currentState, isNull);

    MoonJoinNotificationBanner.show(_data('Too early'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Too early'), findsNothing);
  });
}
