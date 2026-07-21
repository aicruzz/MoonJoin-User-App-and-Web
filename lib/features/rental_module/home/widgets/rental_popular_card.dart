import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
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
  final double rating;
  final String? ratingCount;
  final bool showBookNow;
  final bool isFavourite;
  final VoidCallback? onFavourite;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

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
                Text(price, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: green), textDirection: TextDirection.ltr),
                Text(unit, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
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
