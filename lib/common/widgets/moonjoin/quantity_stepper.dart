import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin −  n  + quantity control. Pure presentation: the parent owns the
/// [quantity] value and mutates it in [onIncrement] / [onDecrement]. Disable a
/// side with [decrementEnabled] / [incrementEnabled].
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool incrementEnabled;
  final bool decrementEnabled;
  final double size;

  const QuantityStepper({
    super.key,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.incrementEnabled = true,
    this.decrementEnabled = true,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _StepButton(icon: Icons.remove, size: size, enabled: decrementEnabled, onTap: onDecrement),
        Container(
          constraints: BoxConstraints(minWidth: size),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          child: Text('$quantity', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ),
        _StepButton(icon: Icons.add, size: size, enabled: incrementEnabled, onTap: onIncrement),
      ]),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.size, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color color = enabled ? Theme.of(context).primaryColor : Theme.of(context).disabledColor;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Container(
        height: size, width: size,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
