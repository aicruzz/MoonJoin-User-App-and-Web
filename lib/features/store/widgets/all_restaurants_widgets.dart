import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// Circular category chip (Figma ALL RESTAURANTS `1:1777`): a soft-tinted circle
/// with the category image and a label beneath. Pure presentation.
class RestaurantCategoryChip extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final int index;
  final VoidCallback? onTap;

  /// How the category artwork is fitted. Default `BoxFit.contain` — unchanged for
  /// every existing module.
  final BoxFit imageFit;

  /// Inset around the artwork inside the circle. Default `paddingSizeSmall` —
  /// unchanged for every existing module. Modules whose admin artwork is a
  /// transparent icon (rather than a photo) can reduce it so the icon reads at full
  /// size instead of appearing small inside the circle.
  final EdgeInsetsGeometry? imagePadding;

  /// Glyph used when no artwork exists (e.g. a leading "All" entry).
  /// Default `Icons.category` — unchanged for every existing module.
  final IconData fallbackIcon;

  /// Selected affordance for modules whose categories filter in place.
  /// Default `false` — unchanged for every existing module.
  final bool selected;

  const RestaurantCategoryChip({
    super.key,
    required this.label,
    this.imageUrl,
    this.index = 0,
    this.onTap,
    this.imageFit = BoxFit.contain,
    this.imagePadding,
    this.fallbackIcon = Icons.category,
    this.selected = false,
  });

  static const List<Color> _tints = [
    Color(0xFFEAF6EC), Color(0xFFFDF3E4), Color(0xFFFDECEC), Color(0xFFE9F7F2), Color(0xFFF3EEFB),
  ];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 64, width: 64,
          padding: imagePadding ?? const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: _tints[index % _tints.length],
            shape: BoxShape.circle,
            border: selected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
          ),
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? ClipOval(child: CustomImage(image: imageUrl!, fit: imageFit))
              : Icon(fallbackIcon, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        SizedBox(
          width: 74,
          child: Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ),
      ]),
    );
  }
}

/// Outlined filter/sort pill (Figma `1:1793`): optional leading icon + label,
/// green when selected. Pure presentation.
class StoreFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? labelColor;
  final bool selected;
  final bool trailingDropdown;
  final VoidCallback? onTap;
  const StoreFilterChip({super.key, required this.label, this.icon, this.iconColor, this.labelColor, this.selected = false, this.trailingDropdown = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.10) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(color: selected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? (selected ? primary : Theme.of(context).hintColor)),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          ],
          Text(label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: selected ? primary : (labelColor ?? Theme.of(context).textTheme.bodyMedium?.color))),
          if (trailingDropdown) ...[
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 18, color: Theme.of(context).hintColor),
          ],
        ]),
      ),
    );
  }
}

/// Promotional banner carousel (Figma ALL RESTAURANTS hero): the ONE rotating
/// banner section at the top of the store list. Data is the existing **Admin
/// Banner feed** ([BannerController] → the promoted, paid-advertising stores
/// configured in the Admin Panel); only store-target banners are passed in.
/// Reuses the app's standard [CarouselSlider] (same package/pattern as
/// `banner_view.dart`) — `autoPlay` pauses on touch/manual swipe and resumes
/// automatically, and the slider disposes its own timer with the [State] (no
/// leak). Presentation only; no invented backend — tap navigation is handed
/// back via [onTapStore].
class PromotionalBannerCarousel extends StatefulWidget {
  /// Admin banner image URLs, parallel to [stores].
  final List<String?> images;
  /// The promoted store each banner links to, parallel to [images].
  final List<Store> stores;
  final void Function(Store store) onTapStore;
  const PromotionalBannerCarousel({super.key, required this.images, required this.stores, required this.onTapStore});

  @override
  State<PromotionalBannerCarousel> createState() => _PromotionalBannerCarouselState();
}

class _PromotionalBannerCarouselState extends State<PromotionalBannerCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    // Match the banner card's 2.55 aspect ratio so the slider height fits the
    // card exactly (no grey gap, no overflow).
    final double cardWidth = MediaQuery.of(context).size.width - (Dimensions.paddingSizeDefault * 2);
    final double sliderHeight = (cardWidth / 2.55) + 8; // +8 for the card shadow

    return Column(children: [
      CarouselSlider.builder(
        itemCount: images.length,
        options: CarouselOptions(
          height: sliderHeight,
          viewportFraction: 1.0,
          autoPlay: images.length > 1,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 700),
          autoPlayCurve: Curves.easeInOut,
          // pauseAutoPlayOnTouch / pauseAutoPlayOnManualNavigate default to true.
          onPageChanged: (index, reason) => setState(() => _current = index),
        ),
        itemBuilder: (context, index, _) {
          final store = widget.stores[index];
          final String? image = images[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: InkWell(
              onTap: () => widget.onTapStore(store),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 2.55,
                  child: (image != null && image.isNotEmpty)
                      ? CustomImage(image: image, fit: BoxFit.cover)
                      : Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
                ),
              ),
            ),
          );
        },
      ),
      if (images.length > 1) ...[
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) {
          final bool active = i == _current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: active ? 8 : 6, width: active ? 8 : 6,
            decoration: BoxDecoration(
              color: active ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          );
        })),
      ],
    ]);
  }
}

// NOTE: the legacy `TopBrandCard` was removed in Phase 2 — every Top Brands section
// (Food · Ecommerce/Fashion · Rental) now shares the approved MoonJoin presentation
// `MoonjoinTopBrandsSection` (+ `MoonjoinTopBrandCard`) in
// `lib/common/widgets/moonjoin/`. Do not reintroduce a second Top Brands card here.
