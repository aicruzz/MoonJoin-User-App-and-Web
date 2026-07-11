import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/moonjoin/bottom_action_bar.dart';
import 'package:sixam_mart/common/widgets/moonjoin/quantity_stepper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// The product-details footer: a "Total Amount" label + amount, an optional
/// [QuantityStepper], and a full-width primary action button ("Add To Cart").
/// Matches both product-details reference designs. Prices are pre-formatted
/// strings; all actions are callbacks. Pure presentation.
class FloatingCheckoutBar extends StatelessWidget {
  final String totalLabel;
  final String totalText;
  final String buttonText;
  final VoidCallback? onButtonTap;
  final bool showQuantity;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool incrementEnabled;
  final bool decrementEnabled;
  final bool enabled;

  const FloatingCheckoutBar({
    super.key,
    this.totalLabel = 'Total Amount',
    required this.totalText,
    this.buttonText = 'Add To Cart',
    this.onButtonTap,
    this.showQuantity = true,
    this.quantity = 1,
    this.onIncrement,
    this.onDecrement,
    this.incrementEnabled = true,
    this.decrementEnabled = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(totalLabel, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(height: 2),
          Text(totalText, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
        ]),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        if (showQuantity) ...[
          QuantityStepper(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            incrementEnabled: incrementEnabled,
            decrementEnabled: decrementEnabled,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
        ],
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: enabled ? onButtonTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                disabledBackgroundColor: Theme.of(context).disabledColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text(buttonText, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
            ),
          ),
        ),
      ]),
    );
  }
}
