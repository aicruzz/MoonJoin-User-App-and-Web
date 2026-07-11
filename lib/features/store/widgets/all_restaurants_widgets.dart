import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/widgets/moonjoin_store_card.dart';
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

/// Featured-store promo carousel (Figma ALL RESTAURANTS hero): the first banner
/// above Top Brands auto-rotates through the featured restaurants with a page
/// indicator. Reuses the app's standard [CarouselSlider] (same package/pattern
/// as `banner_view.dart`) — its `autoPlay` pauses on touch/manual swipe and
/// resumes automatically, so we don't hand-roll carousel logic. Presentation
/// only; data is the existing featured [Store] list (no invented backend).
class FeaturedStoreCarousel extends StatefulWidget {
  final List<Store> stores;
  final void Function(Store store) onTapStore;
  const FeaturedStoreCarousel({super.key, required this.stores, required this.onTapStore});

  @override
  State<FeaturedStoreCarousel> createState() => _FeaturedStoreCarouselState();
}

class _FeaturedStoreCarouselState extends State<FeaturedStoreCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final stores = widget.stores;
    // Match the banner card's 2.55 aspect ratio so the slider height fits the
    // card exactly (no grey gap, no overflow).
    final double cardWidth = MediaQuery.of(context).size.width - (Dimensions.paddingSizeDefault * 2);
    final double sliderHeight = (cardWidth / 2.55) + 8; // +8 for the card shadow

    return Column(children: [
      CarouselSlider.builder(
        itemCount: stores.length,
        options: CarouselOptions(
          height: sliderHeight,
          viewportFraction: 1.0,
          autoPlay: stores.length > 1,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 700),
          autoPlayCurve: Curves.easeInOut,
          // pauseAutoPlayOnTouch / pauseAutoPlayOnManualNavigate default to true.
          onPageChanged: (index, reason) => setState(() => _current = index),
        ),
        itemBuilder: (context, index, _) {
          final store = stores[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: MoonjoinStoreCard(store: store, bannerOnly: true, onTap: () => widget.onTapStore(store)),
          );
        },
      ),
      if (stores.length > 1) ...[
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(stores.length, (i) {
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
