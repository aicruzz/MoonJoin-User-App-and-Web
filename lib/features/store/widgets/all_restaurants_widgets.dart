import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Circular category chip (Figma ALL RESTAURANTS `1:1777`): a soft-tinted circle
/// with the category image and a label beneath. Pure presentation.
class RestaurantCategoryChip extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final int index;
  final VoidCallback? onTap;
  const RestaurantCategoryChip({super.key, required this.label, this.imageUrl, this.index = 0, this.onTap});

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
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(color: _tints[index % _tints.length], shape: BoxShape.circle),
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? ClipOval(child: CustomImage(image: imageUrl!, fit: BoxFit.contain))
              : Icon(Icons.category, color: Theme.of(context).primaryColor),
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

/// Top-Brands card (Figma `1:1810`): rounded card with the brand logo, name and
/// item count. Pure presentation.
class TopBrandCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int itemCount;
  final VoidCallback? onTap;
  const TopBrandCard({super.key, required this.name, this.imageUrl, this.itemCount = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 46, width: 46,
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? CustomImage(image: imageUrl!, fit: BoxFit.contain)
                : Icon(Icons.storefront, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(height: 2),
          Text('$itemCount+ ${'items'.tr}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
        ]),
      ),
    );
  }
}
