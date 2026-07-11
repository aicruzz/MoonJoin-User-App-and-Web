import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A small pill used for statuses and tags (e.g. "In Stock", "Non-Veg",
/// order status, rating chips). [filled] draws a solid [color] background with
/// light text; otherwise it tints [color] at low opacity with coloured text.
class StatusBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final bool filled;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.text,
    this.color,
    this.filled = false,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
  });

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? Theme.of(context).primaryColor;
    final Color fg = filled ? Colors.white : base;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: filled ? base : base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
        ],
        Text(text, style: robotoMedium.copyWith(color: fg, fontSize: Dimensions.fontSizeExtraSmall)),
      ]),
    );
  }
}
