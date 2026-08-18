import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

enum MoonjoinButtonType { primary, secondary, outline }

/// The MoonJoin action button in three variants (filled primary, tinted
/// secondary, outline). Supports a leading [icon] and a [isLoading] spinner.
/// Pure presentation — action via [onPressed]; a null [onPressed] disables it.
class MoonjoinButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final MoonjoinButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const MoonjoinButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = MoonjoinButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.height = 50,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final bool filled = type == MoonjoinButtonType.primary;
    final bool outline = type == MoonjoinButtonType.outline;

    final Color bg = filled
        ? primary
        : type == MoonjoinButtonType.secondary
            ? primary.withValues(alpha: 0.12)
            : Colors.transparent;
    final Color fg = filled ? Colors.white : primary;

    final Widget child = isLoading
        ? SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(fg)),
          )
        : Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: Dimensions.paddingSizeSmall)],
            Text(text, style: robotoBold.copyWith(color: fg, fontSize: Dimensions.fontSizeLarge)),
          ]);

    return Container(
      margin: margin,
      width: expanded ? double.infinity : width,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: outline ? Border.all(color: primary) : null,
              color: onPressed == null && !isLoading ? Theme.of(context).disabledColor.withValues(alpha: filled ? 1 : 0.1) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
