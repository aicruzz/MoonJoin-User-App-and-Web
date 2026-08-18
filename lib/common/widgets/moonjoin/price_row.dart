import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// A label + value row for bill breakdowns (subtotal, discount, delivery,
/// total). Values are passed as already-formatted strings so this widget stays
/// free of any currency/price business logic. Use [isTotal] to emphasise the
/// grand-total row and [isDiscount] to colour a deduction.
class PriceRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isTotal;
  final bool isDiscount;
  final EdgeInsetsGeometry padding;

  const PriceRow({
    super.key,
    required this.title,
    required this.value,
    this.isTotal = false,
    this.isDiscount = false,
    this.padding = const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle style = isTotal
        ? robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)
        : robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault);
    final Color valueColor = isTotal
        ? Theme.of(context).primaryColor
        : isDiscount
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return Padding(
      padding: padding,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(title, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text('${isDiscount ? '- ' : ''}$value', style: style.copyWith(color: valueColor)),
      ]),
    );
  }
}

/// Inline price display: current [price] with an optional struck-through
/// [oldPrice]. Both are pre-formatted strings.
class PriceView extends StatelessWidget {
  final String price;
  final String? oldPrice;
  final double? fontSize;
  final Color? color;

  const PriceView({super.key, required this.price, this.oldPrice, this.fontSize, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(price, style: robotoBold.copyWith(color: color ?? Theme.of(context).primaryColor, fontSize: fontSize ?? Dimensions.fontSizeLarge)),
      if (oldPrice != null && oldPrice!.isNotEmpty) ...[
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text(
          oldPrice!,
          style: robotoRegular.copyWith(
            color: Theme.of(context).hintColor,
            fontSize: (fontSize ?? Dimensions.fontSizeLarge) - 3,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
    ]);
  }
}
