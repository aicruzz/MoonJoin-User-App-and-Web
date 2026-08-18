import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// An inline notice card with a leading icon, title, subtitle and an optional
/// trailing action — e.g. the home "Some items are unavailable · Review Items"
/// banner. Soft amber tint by default. Pure presentation.
class InformationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? leading;

  const InformationCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.info_outline,
    this.accentColor,
    this.actionText,
    this.onAction,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? const Color(0xFFE8A100);
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Row(children: [
        leading ?? Icon(icon, color: accent, size: 28),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
            ],
          ]),
        ),
        if (actionText != null && onAction != null) ...[
          const SizedBox(width: Dimensions.paddingSizeSmall),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(actionText!, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
              const Icon(Icons.chevron_right, color: Colors.white, size: 18),
            ]),
          ),
        ],
      ]),
    );
  }
}
