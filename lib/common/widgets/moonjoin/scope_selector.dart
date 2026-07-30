import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin Design System — a reusable "scope" pill: `[leadingText] (icon) label ▾`.
///
/// Deliberately NOT search-specific: it is a platform component reusable by
/// Search, AI Assistant, Notifications, Offers, Coupons, Analytics and a future
/// Global Search. Pure presentation — the caller owns what tapping it does.
class MoonJoinScopeSelector extends StatelessWidget {
  final String label;
  final String? iconUrl;
  final IconData? icon;
  final String? leadingText;
  final VoidCallback? onTap;

  const MoonJoinScopeSelector({
    super.key,
    required this.label,
    this.iconUrl,
    this.icon,
    this.leadingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (leadingText != null) ...[
        Text(
          leadingText!,
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      ],
      Flexible(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              border: Border.all(color: primary.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              (iconUrl != null && iconUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomImage(image: iconUrl!, width: 18, height: 18, fit: BoxFit.cover),
                    )
                  : Icon(icon ?? Icons.category_rounded, size: 16, color: primary),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Flexible(
                child: Text(
                  label,
                  style: robotoMedium.copyWith(color: primary, fontSize: Dimensions.fontSizeSmall),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: primary),
            ]),
          ),
        ),
      ),
    ]);
  }
}
