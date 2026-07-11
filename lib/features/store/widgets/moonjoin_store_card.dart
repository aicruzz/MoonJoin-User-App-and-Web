import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin store / restaurant card (Figma ALL RESTAURANTS `1:1716`): a rounded
/// card with a cover image (discount badge, logo, delivery-time pill overlaid)
/// and an info row (name, rating · time · free-delivery, bookmark).
///
/// Presentation only — data comes from the existing [Store] model and the
/// bookmark reuses the existing [FavouriteController]. No business logic added.
class MoonjoinStoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;
  /// When true, render only the cover banner (no name/rating row). Used by the
  /// featured-store carousel, which mirrors the Figma promo banner.
  final bool bannerOnly;
  const MoonjoinStoreCard({super.key, required this.store, this.onTap, this.bannerOnly = false});

  static const Color _nameColor = Color(0xFF3F4044);
  static const Color _metaColor = Color(0xFFA9A9AC);
  static const Color _freeDeliveryColor = Color(0xFF2C9C44);

  /// "ON ORDERS OVER ₦X" — shown only when the store's active discount carries a
  /// real `min_purchase` threshold (existing backend field, no invented data).
  String? _minPurchaseText() {
    final mp = store.discount?.minPurchase;
    if (mp == null || mp <= 0) return null;
    return '${'on_orders_over'.tr} ${PriceConverter.convertPrice(mp)}';
  }

  /// The delivery-time value can arrive as "20-40", "20-40 min" or "20-40 mins".
  /// Strip any trailing unit so the card can append its own ("MINS" / "mins")
  /// without duplicating it (Figma pill reads "20-30 MINS").
  String get _timeRange => (store.deliveryTime ?? '')
      .replaceAll(RegExp(r'\s*mins?\s*$', caseSensitive: false), '')
      .trim();

  String? _discountText() {
    final d = store.discount;
    if (d == null || (d.discount ?? 0) <= 0) return null;
    if (d.discountType == 'percent') return '-${d.discount!.toStringAsFixed(0)}% OFF';
    return '-${d.discount!.toStringAsFixed(0)} OFF';
  }

  @override
  Widget build(BuildContext context) {
    final String? discount = _discountText();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

          /// Cover image + overlays
          AspectRatio(
            aspectRatio: 2.55,
            child: Stack(fit: StackFit.expand, children: [
              (store.coverPhotoFullUrl != null && store.coverPhotoFullUrl!.isNotEmpty)
                  ? CustomImage(image: store.coverPhotoFullUrl!, fit: BoxFit.cover)
                  : Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),

              // Discount + "orders over" badges (top-left)
              if (discount != null || _minPurchaseText() != null)
                Positioned(
                  top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall,
                  right: 56,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (discount != null) _badge(discount, const Color(0xFF038840), Colors.white),
                    if (discount != null && _minPurchaseText() != null) const SizedBox(width: 6),
                    if (_minPurchaseText() != null)
                      Flexible(child: _badge(_minPurchaseText()!, const Color(0xFFFBEBC8), const Color(0xFF8A6D1B))),
                  ]),
                ),

              // Logo (top-right)
              if (store.logoFullUrl != null && store.logoFullUrl!.isNotEmpty)
                Positioned(
                  top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                  child: Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(child: CustomImage(image: store.logoFullUrl!, fit: BoxFit.cover)),
                  ),
                ),

              // Delivery-time pill (bottom-left)
              if (_timeRange.isNotEmpty)
                Positioned(
                  bottom: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFCFB),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: const Color(0xFFEADACC)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time, size: 15, color: Color(0xFF636365)),
                      const SizedBox(width: 4),
                      Text('$_timeRange MINS', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF636365))),
                    ]),
                  ),
                ),
            ]),
          ),

          /// Info row (hidden in banner-only / featured-carousel mode)
          if (!bannerOnly) Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(store.name ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: _nameColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Row(children: [
                    Icon(Icons.star, size: 15, color: Colors.amber.shade600),
                    const SizedBox(width: 3),
                    Text('${store.avgRating?.toStringAsFixed(1) ?? '0.0'}(${store.ratingCount ?? 0}+)', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _metaColor)),
                    if (_timeRange.isNotEmpty) ...[
                      _dot(),
                      Text('$_timeRange mins', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _metaColor)),
                    ],
                    if (store.freeDelivery == true) ...[
                      _dot(),
                      Icon(Icons.favorite, size: 14, color: _freeDeliveryColor),
                      const SizedBox(width: 3),
                      Text('free_delivery'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: _freeDeliveryColor)),
                    ],
                  ]),
                ]),
              ),
              _BookmarkButton(storeId: store.id),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusMedium)),
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(color: textColor, fontSize: Dimensions.fontSizeSmall)),
  );

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
    child: CircleAvatar(radius: 2, backgroundColor: Color(0xFFC9C9CC)),
  );
}

/// Bookmark toggle reusing the existing favourite (wish-list) logic.
class _BookmarkButton extends StatelessWidget {
  final int? storeId;
  const _BookmarkButton({this.storeId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FavouriteController>(builder: (favouriteController) {
      final bool isWished = favouriteController.wishStoreIdList.contains(storeId);
      return InkWell(
        onTap: () {
          if (isWished) {
            favouriteController.removeFromFavouriteList(storeId, true);
          } else {
            favouriteController.addToFavouriteList(null, storeId, true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            isWished ? Icons.bookmark : Icons.bookmark_border,
            color: isWished ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
            size: 24,
          ),
        ),
      );
    });
  }
}
