import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/moonjoin/price_row.dart';
import 'package:sixam_mart/common/widgets/moonjoin/status_badge.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin product/item card: image, name, price (with optional old price),
/// optional rating, discount tag, favourite toggle and an add-to-cart button.
/// Purely presentational — prices/ratings are pre-formatted strings and all
/// actions are callbacks. Works in grids and horizontal lists.
class ProductCard extends StatelessWidget {
  final String name;
  final String priceText;
  final String? oldPriceText;
  final String? imageUrl;
  final String? ratingText;
  final String? discountText;
  final bool isAvailable;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onFavorite;
  final double width;

  const ProductCard({
    super.key,
    required this.name,
    required this.priceText,
    this.oldPriceText,
    this.imageUrl,
    this.ratingText,
    this.discountText,
    this.isAvailable = true,
    this.isFavorite = false,
    this.onTap,
    this.onAdd,
    this.onFavorite,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
              child: SizedBox(
                height: width * 0.72, width: width,
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? CustomImage(image: imageUrl!, fit: BoxFit.cover)
                    : Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.1)),
              ),
            ),
            if (discountText != null)
              Positioned(top: Dimensions.paddingSizeExtraSmall, left: Dimensions.paddingSizeExtraSmall, child: StatusBadge(text: discountText!, filled: true)),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(name, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (ratingText != null) ...[
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                  const SizedBox(width: 2),
                  Text(ratingText!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                ]),
              ],
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: PriceView(price: priceText, oldPrice: oldPriceText, fontSize: Dimensions.fontSizeDefault)),
                if (onAdd != null)
                  InkWell(
                    onTap: isAvailable ? onAdd : null,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Container(
                      height: 30, width: 30,
                      decoration: BoxDecoration(
                        color: isAvailable ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
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
