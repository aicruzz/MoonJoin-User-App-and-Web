import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Resolves the owning store/vendor's REAL logo for a campaign item, from existing
/// data only (no request, no name match, no placeholder, no generated/hardcoded logo):
///
///   1. [directLogo] — the item-campaign endpoint's `with('store')` relation
///      (`campaign.store.logo_full_url`); primary/forward-looking source.
///   2. Fallback — the store already loaded for this module home whose `id` equals the
///      item's real [storeId], reusing its `logoFullUrl`.
///
/// Returns null when neither yields a logo, so the badge is simply omitted.
String? resolveCampaignStoreLogo({
  required String? directLogo,
  required int? storeId,
  required List<List<Store>?> loadedStores,
}) {
  if (directLogo != null && directLogo.isNotEmpty) return directLogo;
  if (storeId == null) return null;
  for (final List<Store>? list in loadedStores) {
    if (list == null) continue;
    for (final Store s in list) {
      if (s.id == storeId) {
        final String? logo = s.logoFullUrl;
        if (logo != null && logo.isNotEmpty) return logo;
      }
    }
  }
  return null;
}

/// MoonJoin Campaign card — a premium, editorial food-commerce presentation of an
/// existing item-campaign `Item` (ui-designs/campaign.png): a large dominant
/// product image with the store/brand logo overlaid and the campaign discount
/// badge, then store name, item name and the campaign price + struck original.
///
/// PRESENTATION ONLY: image, name, store, and the discounted price come from the
/// existing `Item`/campaign data via the existing `ItemController.getStartingPrice`
/// + `PriceConverter` (unchanged); availability uses `ItemController.isAvailable`;
/// tapping runs the existing `navigateToItemPage(..., isCampaign: true)`.
class MoonjoinCampaignCard extends StatelessWidget {
  final Item item;
  final double width;
  const MoonjoinCampaignCard({super.key, required this.item, this.width = 160});

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    final double? startPrice = Get.find<ItemController>().getStartingPrice(item);
    final bool hasDiscount = item.discount != null && item.discount! > 0;
    final bool available = Get.find<ItemController>().isAvailable(item);
    final String badge = _badge();
    final String? storeLogo = _resolveStoreLogo();

    return InkWell(
      onTap: () => Get.find<ItemController>().navigateToItemPage(item, context, isCampaign: true),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: SizedBox(
        width: width,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Large dominant product image (square) with overlays ──
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(fit: StackFit.expand, children: [
                CustomImage(image: item.imageFullUrl ?? '', fit: BoxFit.cover),

                if (badge.isNotEmpty)
                  Positioned(
                    top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                      child: Text(badge, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall)),
                    ),
                  ),

                if (storeLogo != null && storeLogo.isNotEmpty)
                  Positioned(
                    bottom: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall,
                    child: Container(
                      height: 40, width: 40, padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        child: CustomImage(image: storeLogo, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                if (!available)
                  Positioned.fill(child: Container(
                    alignment: Alignment.center,
                    color: Colors.black.withValues(alpha: 0.04),
                    child: const NotAvailableWidget(),
                  )),
              ]),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          if ((item.storeName ?? '').isNotEmpty)
            Text(item.storeName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
          const SizedBox(height: 2),

          Text(item.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, height: 1.15)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: Text(
              PriceConverter.convertPrice(startPrice, discount: item.discount, discountType: item.discountType),
              maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: green),
            )),
            if (hasDiscount) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Flexible(child: Text(
                PriceConverter.convertPrice(startPrice),
                maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                    decoration: TextDecoration.lineThrough),
              )),
            ],
          ]),
        ]),
      ),
    );
  }

  /// The owning restaurant/vendor's REAL logo for the badge overlay, gathering the
  /// already-loaded stores for this module home and delegating to the pure
  /// [resolveCampaignStoreLogo] (Campaign item → owning store → that store's logo).
  String? _resolveStoreLogo() {
    List<List<Store>?> loaded = const [];
    if (Get.isRegistered<StoreController>()) {
      final StoreController sc = Get.find<StoreController>();
      loaded = [
        sc.storeModel?.stores, sc.popularStoreList, sc.latestStoreList,
        sc.featuredStoreList, sc.topOfferStoreList, sc.recommendedStoreList, sc.visitAgainStoreList,
      ];
    }
    return resolveCampaignStoreLogo(directLogo: item.store?.logoFullUrl, storeId: item.storeId, loadedStores: loaded);
  }

  /// Discount badge from the existing campaign data (never hardcoded).
  String _badge() {
    final double discount = item.discount ?? 0;
    if (discount <= 0) return '';
    if ((item.discountType ?? 'percent') == 'percent') {
      return '${discount.toStringAsFixed(0)}% ${'off'.tr}';
    }
    return '${PriceConverter.convertPrice(discount)} ${'off'.tr}';
  }
}
