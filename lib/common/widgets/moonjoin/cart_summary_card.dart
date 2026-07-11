import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/moonjoin/price_row.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// One line in a [CartSummaryCard].
class SummaryLine {
  final String title;
  final String value;
  final bool isDiscount;
  const SummaryLine(this.title, this.value, {this.isDiscount = false});
}

/// The bill-details / order-summary card used on cart & checkout: a titled
/// white card of [SummaryLine]s, a divider, then the grand total. Values are
/// pre-formatted strings (no price logic here). Pure presentation.
class CartSummaryCard extends StatelessWidget {
  final String title;
  final List<SummaryLine> lines;
  final String totalLabel;
  final String totalValue;

  const CartSummaryCard({
    super.key,
    this.title = 'Bill Details',
    required this.lines,
    this.totalLabel = 'Total',
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ...lines.map((l) => PriceRow(title: l.title, value: l.value, isDiscount: l.isDiscount)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
        ),
        PriceRow(title: totalLabel, value: totalValue, isTotal: true),
      ]),
    );
  }
}
