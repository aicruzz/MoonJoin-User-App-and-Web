import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Compact vertical card for the Rental Home "Popular …" rows. Shared by BOTH
/// Car Rental (VehicleModel) and Short Apartment Rental (placeholder) so the two
/// business modules use one listing-card layout — only the data source differs.
/// Pure presentation: pass pre-formatted strings + callbacks.
class RentalPopularCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final String price;
  final String unit;
  /// Optional pre-formatted original (pre-flash) price. When supplied it is shown
  /// struck-through next to [price] to communicate the Flash Sale saving. Null on
  /// non-flash cards (Main Rental Home), so their presentation is unchanged.
  final String? originalPrice;
  final double rating;
  final String? ratingCount;
  final bool showBookNow;
  final bool isFavourite;
  final VoidCallback? onFavourite;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  /// Optional Rental Flash Sale (backend-authoritative). When non-null a flash
  /// badge is shown; null → the card is unchanged. Never passed on the Main Rental
  /// Home; only the dedicated Car/Apt "Flash Deals" sections supply it.
  final RentalFlashSale? flashSale;

  const RentalPopularCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.unit,
    required this.rating,
    this.ratingCount,
    this.showBookNow = false,
    this.isFavourite = false,
    this.onFavourite,
    this.onTap,
    this.onBook,
    this.flashSale,
    this.originalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
              child: CustomImage(image: image, height: 96, width: 168, fit: BoxFit.cover),
            ),
            Positioned(
              top: Dimensions.paddingSizeExtraSmall, right: Dimensions.paddingSizeExtraSmall,
              child: InkWell(
                onTap: onFavourite,
                customBorder: const CircleBorder(),
                child: Container(
                  height: 28, width: 28, alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(isFavourite ? Icons.favorite : Icons.favorite_border,
                      size: 16, color: isFavourite ? Theme.of(context).colorScheme.error : Theme.of(context).disabledColor),
                ),
              ),
            ),
            if (flashSale != null)
              Positioned(
                top: Dimensions.paddingSizeExtraSmall, left: Dimensions.paddingSizeExtraSmall,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.flash_on, size: 11, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      (flashSale!.discountType == 'percent' && flashSale!.discount != null)
                          ? '${flashSale!.discount!.toStringAsFixed(0)}% ${'off'.tr}'
                          : 'flash_sale'.tr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverSmall, color: Colors.white),
                    ),
                  ]),
                ),
              ),
          ]),

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Flexible(child: Text(price, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: green), textDirection: TextDirection.ltr)),
                Text(unit, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
                if (originalPrice != null) ...[
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Flexible(child: Text(originalPrice!, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor,
                          decoration: TextDecoration.lineThrough))),
                ],
              ]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Row(children: [
                const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
                if (ratingCount != null) Flexible(child: Text(' ($ratingCount)', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor))),
                const Spacer(),
                if (showBookNow) InkWell(
                  onTap: onBook ?? onTap,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
                    decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                    child: Text('book_now'.tr, style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall)),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
