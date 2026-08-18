import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin category tile — the single visual implementation of a category entry
/// (circular backend image + label), matching the approved Food Home category row.
///
/// Pure presentation: it renders whatever category the caller passes, so every module
/// (storefront and Rental) shares ONE category look instead of each defining its own.
/// Category data always comes from the backend — never hardcode names or images here.
///
/// [image] is the backend image URL. When it is empty, [icon] is drawn instead (used by
/// the leading "All" tile, which has no backend image). [selected] paints the MoonJoin
/// green ring for modules whose categories filter in place (e.g. Rental).
class MoonjoinCategoryTile extends StatelessWidget {
  final String label;
  final String image;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const MoonjoinCategoryTile({
    super.key,
    required this.label,
    this.image = '',
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: SizedBox(
        width: 60,
        child: Column(children: [

          // Structurally IDENTICAL to the Food Home category tile: a bare
          // Stack > ClipRRect(radius 100) > CustomImage(60, cover). No extra container,
          // no background fill, no border — so the unselected state renders exactly as
          // it does on Food/Grocery/Pharmacy/Fashion/Parcel Home. The selection ring is
          // an overlay drawn ONLY when selected, so it cannot alter the default look.
          Stack(children: [
            // Circular tile surface. Category artwork is commonly a TRANSPARENT icon
            // (not a photo); without a surface behind it the glyph floats with no
            // circle and the row loses the MoonJoin category look. The tinted circle
            // guarantees the tile reads correctly for BOTH icon art and photos, and
            // `contain` keeps artwork undistorted and uncropped inside it.
            Container(
              height: 60, width: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: green.withValues(alpha: 0.08)),
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              child: ClipOval(
                child: image.isNotEmpty
                    ? CustomImage(image: image, height: 60, width: double.infinity, fit: BoxFit.contain)
                    : Icon(icon ?? Icons.grid_view_rounded, size: 26, color: green),
              ),
            ),
            if (selected) Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: green, width: 2),
                ),
              ),
            ),
          ]),
          // Matches the Food Home category component exactly. Do NOT tune this (or any
          // other value here) for a single module — one shared component, one shared
          // appearance, so future improvements propagate everywhere automatically.
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Expanded(child: Text(
            label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          )),
        ]),
      ),
    );
  }
}
