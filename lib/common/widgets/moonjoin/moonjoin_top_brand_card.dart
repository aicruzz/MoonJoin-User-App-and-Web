import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Top Brand card (ui-designs/Top_Brands.png) — a compact rounded card
/// whose ENTIRE surface is the vendor's uploaded logo/image, cover-filled and
/// clipped to the rounded rectangle, with the brand name at the bottom. The
/// uploaded image IS the card artwork: its own background (a red logo → red card,
/// a transparent logo → clean light card) defines the appearance. NO colour is
/// extracted or generated. One reusable card (Phase 1: Food).
///
/// PRESENTATION ONLY: consumes the existing stored vendor logo/image asset and
/// the store name; navigation is handled by the caller.
class MoonjoinTopBrandCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;
  /// Compact width so ~4 cards are visible across a phone (matches the reference).
  final double width;
  const MoonjoinTopBrandCard({super.key, required this.name, this.imageUrl, this.onTap, this.width = 84});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // base shows through transparent logos
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Stack(fit: StackFit.expand, children: [

          // The vendor uploaded image IS the card — it fills the whole surface.
          if (hasImage)
            CustomImage(image: imageUrl!, fit: BoxFit.cover)
          else
            Center(child: Icon(Icons.storefront, color: Theme.of(context).primaryColor, size: 30)),

          // Bottom scrim so the brand name is legible over any artwork.
          Positioned(
            left: 0, right: 0, bottom: 0, height: width * 0.62,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.62), Colors.black.withValues(alpha: 0.10), Colors.transparent],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Brand name at the bottom (inside the card).
          Positioned(
            left: 4, right: 4, bottom: 6,
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall)),
          ),
        ]),
      ),
    );
  }
}
