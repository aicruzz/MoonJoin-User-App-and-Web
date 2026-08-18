import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Flash Deals — the approved premium flash card (ui-designs/flashcard.PNG).
///
/// PURE PRESENTATION: it takes pre-formatted display values only and owns no
/// business logic, so every module (Food/Grocery/Fashion/Rental "Flash Rent" …)
/// maps its own already-working data onto these props without a second card
/// implementation. Missing fields degrade gracefully while the hierarchy holds:
/// hero content on the left (badge → title → provider → price → sold), premium
/// bleeding product image on the right.
class MoonjoinFlashDealCard extends StatelessWidget {
  final String image;
  final String badgeText;            // e.g. "35% OFF" — caller-formatted
  final Color? badgeColor;           // defaults to brand green
  final String title;
  final String? provider;
  final bool isVerified;
  final String flashPrice;           // caller-formatted (PriceConverter)
  final String? originalPrice;       // caller-formatted; null → no strikethrough
  final String? soldLabel;           // e.g. "82% Sold"; null → hidden
  final double? soldFraction;        // 0..1 progress; null → no bar
  final VoidCallback? onTap;

  const MoonjoinFlashDealCard({
    super.key,
    required this.image,
    required this.badgeText,
    required this.title,
    required this.flashPrice,
    this.badgeColor,
    this.provider,
    this.isVerified = false,
    this.originalPrice,
    this.soldLabel,
    this.soldFraction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    final Color badge = badgeColor ?? green;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Content column ──
          Expanded(
            flex: 48,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                // Badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
                    decoration: BoxDecoration(color: badge, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                    child: Text(badgeText, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall)),
                  ),
                ),

                // Title + provider
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, height: 1.1)),
                  if (provider != null && provider!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      Flexible(child: Text(provider!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
                      if (isVerified) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.verified, size: 14, color: green),
                      ],
                    ]),
                  ],
                ]),

                // Price — the flash price stays fully readable: FittedBox scales it
                // down only for genuinely long values (never an "…" truncation),
                // while the struck original ellipsises first if space runs out.
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(flashPrice, maxLines: 1, textDirection: TextDirection.ltr,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: green)),
                    ),
                  ),
                  if (originalPrice != null) ...[
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Flexible(child: Text(originalPrice!, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                            decoration: TextDecoration.lineThrough))),
                  ],
                ]),

                // Sold indicator + progress (only when the data exists)
                if (soldLabel != null || soldFraction != null)
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    if (soldLabel != null)
                      Row(children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFFF6B00)),
                        const SizedBox(width: 3),
                        Flexible(child: Text(soldLabel!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall))),
                      ]),
                    if (soldFraction != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: soldFraction!.clamp(0.0, 1.0),
                          valueColor: AlwaysStoppedAnimation<Color>(green),
                          backgroundColor: green.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ]),
              ]),
            ),
          ),

          // ── Product image — the full hero product, never cropped: BoxFit.contain
          // preserves the whole silhouette and aspect ratio (no bottom cut, no
          // distortion) on a clean white surface. ──
          Expanded(
            flex: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: 4),
              child: CustomImage(image: image, fit: BoxFit.contain, height: double.infinity, width: double.infinity),
            ),
          ),
        ]),
      ),
    );
  }
}
