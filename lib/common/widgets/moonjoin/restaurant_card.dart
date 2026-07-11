import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/moonjoin/status_badge.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin store / restaurant card: banner image, name, cuisine/category
/// line, rating, delivery time and distance. Also usable for rental providers.
/// Pure presentation — all values are strings and [onTap] carries the action.
class RestaurantCard extends StatelessWidget {
  final String name;
  final String? bannerUrl;
  final String? logoUrl;
  final String? subtitle;
  final String? ratingText;
  final String? deliveryTimeText;
  final String? distanceText;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool horizontal;

  const RestaurantCard({
    super.key,
    required this.name,
    this.bannerUrl,
    this.logoUrl,
    this.subtitle,
    this.ratingText,
    this.deliveryTimeText,
    this.distanceText,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            SizedBox(
              height: 110, width: double.infinity,
              child: (bannerUrl != null && bannerUrl!.isNotEmpty)
                  ? CustomImage(image: bannerUrl!, fit: BoxFit.cover)
                  : Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
            ),
            if (onFavorite != null)
              Positioned(
                top: Dimensions.paddingSizeExtraSmall, right: Dimensions.paddingSizeExtraSmall,
                child: InkWell(
                  onTap: onFavorite,
                  child: CircleAvatar(
                    radius: 15, backgroundColor: Theme.of(context).cardColor,
                    child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, size: 16, color: isFavorite ? Theme.of(context).colorScheme.error : Theme.of(context).hintColor),
                  ),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(children: [
              if (logoUrl != null && logoUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: CustomImage(image: logoUrl!, height: 40, width: 40, fit: BoxFit.cover),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
              ],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(name, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Row(children: [
                    if (ratingText != null) ...[
                      StatusBadge(text: ratingText!, icon: Icons.star, color: Colors.amber.shade700),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    ],
                    if (deliveryTimeText != null) ...[
                      Icon(Icons.access_time, size: 13, color: Theme.of(context).hintColor),
                      const SizedBox(width: 2),
                      Text(deliveryTimeText!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    ],
                    if (distanceText != null) ...[
                      Icon(Icons.location_on_outlined, size: 13, color: Theme.of(context).hintColor),
                      const SizedBox(width: 2),
                      Flexible(child: Text(distanceText!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
