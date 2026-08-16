import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_flash_deal_card.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_flash_deals_section.dart';

// Layout guard for the MoonJoin Flash Deals presentation. Renders the section +
// cards at a phone width and fails if the header, countdown, card, pricing, sold
// row or pagination cause any RenderFlex overflow. Machine-independent (no golden
// image); unavoidable test-env image-load errors are drained and ignored.
void main() {
  testWidgets('MoonJoin Flash Deals section renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 760 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final List<Map<String, dynamic>> cards = [
      {'t': 'Large Chicken Pizza', 'p': 'Chruzz Pizza', 'fp': 'N4,500', 'op': 'N6,800', 'b': '35% OFF', 's': '82% Sold', 'sf': 0.82},
      {'t': 'Classic Beef Burger', 'p': 'Chruzz Burgers', 'fp': 'N3,200', 'op': 'N4,200', 'b': '25% OFF', 's': '74% Sold', 'sf': 0.74},
      {'t': 'Jollof Rice Special', 'p': 'Mama Put Kitchen', 'fp': 'N2,000', 'op': 'N2,600', 'b': '23% OFF', 's': '40% Sold', 'sf': 0.40},
    ];

    await tester.pumpWidget(GetMaterialApp(
      theme: ThemeData(primaryColor: const Color(0xFF13A452), disabledColor: Colors.grey),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: MoonjoinFlashDealsSection(
            title: 'Flash Deals',
            subtitle: 'Limited time offers on amazing meals!',
            endTime: DateTime.now().add(const Duration(hours: 1, minutes: 32, seconds: 18)),
            onViewAll: () {},
            itemCount: cards.length,
            itemBuilder: (context, i) => MoonjoinFlashDealCard(
              image: '',
              badgeText: cards[i]['b'] as String,
              title: cards[i]['t'] as String,
              provider: cards[i]['p'] as String,
              isVerified: true,
              flashPrice: cards[i]['fp'] as String,
              originalPrice: cards[i]['op'] as String,
              soldLabel: cards[i]['s'] as String,
              soldFraction: cards[i]['sf'] as double,
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));

    // Drain any exceptions and fail only on layout overflow — image-load errors
    // are unavoidable in the test environment (no network) and are not defects.
    final List<Object> exceptions = [];
    Object? ex;
    while ((ex = tester.takeException()) != null) {
      exceptions.add(ex!);
    }
    final bool overflowed = exceptions.any((e) => e.toString().toLowerCase().contains('overflow'));
    expect(overflowed, isFalse, reason: 'Flash Deals layout overflowed:\n${exceptions.join('\n')}');

    await tester.pumpWidget(const SizedBox()); // dispose → cancels the countdown timer
  });
}
