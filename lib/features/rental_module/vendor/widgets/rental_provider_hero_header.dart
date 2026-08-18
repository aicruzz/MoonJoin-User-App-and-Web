import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/features/notification/controllers/notification_controller.dart';
import 'package:moonjoin/features/rental_module/common/widgets/taxi_add_favourite_view.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/taxi_cart_screen.dart';
import 'package:moonjoin/features/rental_module/vendor/domain/models/taxi_vendor_model.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// Rental **Provider page** hero header (design
/// `ui-designs/Car_Rental/car_rental_provider_item_list.png`).
///
/// Visual clone of the frozen [StoreHeroHeader] (`features/store/widgets/store_hero_header.dart`):
/// identical green hero with the rounded bottom curve, identical action circles and
/// badges, identical name/rating/address/amber-count typography, identical 104px hero
/// image, and the identical search pill straddling the green → content transition.
///
/// **Why a clone rather than literal reuse:** `StoreHeroHeader` is **frozen** and typed
/// to `Store`, reading store/delivery-only fields (`deliveryTime`, cuisines from
/// `StoreController`, `FavouriteController`, `CartController`, store search route). A
/// rental provider has none of those. Feeding it rental data would require modifying a
/// frozen component used by four approved modules. This is the same resolution already
/// recorded for `RentalProviderCard` vs the frozen `MoonjoinStoreCard` and for
/// `MoonjoinCategoryTile`: **adapt the data, clone the visual, never fork the design.**
///
/// Presentation only — every action reuses existing rental logic: the existing
/// `TaxiAddFavouriteView` provider favourite, the existing `TaxiCartController` cart and
/// `TaxiCartScreen`, the existing notification route. No new business logic.
class RentalProviderHeroHeader extends StatelessWidget {
  final TaxiVendorModel vendor;

  /// Total vehicles this provider has, from the real backend
  /// `get-provider-vehicles` response (`totalSize`).
  final int vehicleCount;

  /// Opens the existing rental vehicle search (`SearchVehicleScreen`) — wired by the
  /// screen so the existing search callback/business logic stays in one place.
  final VoidCallback? onSearchTap;

  /// Opens the existing rental `VehicleFilterWidget` bottom sheet (real backend filters).
  final VoidCallback? onFilterTap;

  /// Additive: label after the count (default null → 'vehicles_available', i.e.
  /// every existing call site renders exactly as before). The Provider page passes
  /// 'apartments_available' when the provider's REAL inventory is apartments.
  final String? countLabel;

  /// Opens the existing `ReviewDetailsScreen`. The approved design has no standalone
  /// rating block, so the hero's ★rating carries the reviews entry — the feature is
  /// preserved without adding UI the design does not have.
  final VoidCallback? onRatingTap;

  const RentalProviderHeroHeader({
    super.key,
    required this.vendor,
    required this.vehicleCount,
    this.onSearchTap,
    this.onFilterTap,
    this.onRatingTap,
    this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;

    return Stack(clipBehavior: Clip.none, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Container(
          decoration: BoxDecoration(
            color: green,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusExtraLarge)),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall,
              Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraLarge,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Actions row — back · favourite · notifications · cart
              Row(children: [
                _circle(context, Icons.arrow_back, () => Get.back()),
                const Spacer(),
                _favourite(context),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _badgeCircle(context, Icons.notifications_none,
                    Get.find<NotificationController>().notificationList?.length ?? 0,
                    () => Get.toNamed(RouteHelper.getNotificationRoute())),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                GetBuilder<TaxiCartController>(builder: (taxiCartController) {
                  return _badgeCircle(context, Icons.shopping_cart_outlined, taxiCartController.cartList.length,
                      () => Get.to(() => const TaxiCartScreen()));
                }),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Provider identity + hero image
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

                  Text(vendor.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(color: Colors.white, fontSize: 28)),
                  const SizedBox(height: 6),

                  InkWell(
                    onTap: onRatingTap,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star, size: 15, color: Colors.amber.shade400),
                      const SizedBox(width: 3),
                      Text('${vendor.avgRating?.toStringAsFixed(1) ?? '0.0'} (${vendor.ratingCount ?? 0}+)',
                          style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
                      if (onRatingTap != null) ...[
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 6),

                  if ((vendor.address ?? '').isNotEmpty)
                    Row(children: [
                      const Icon(Icons.location_on, size: 15, color: Colors.white),
                      const SizedBox(width: 3),
                      Flexible(child: Text(vendor.address!, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall))),
                    ]),
                  const SizedBox(height: 6),

                  Text('$vehicleCount ${countLabel ?? 'vehicles_available'.tr}',
                      style: robotoBold.copyWith(color: const Color(0xFFFFC107), fontSize: Dimensions.fontSizeSmall)),
                ])),

                if ((vendor.coverPhotoFullUrl ?? '').isNotEmpty) Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    child: CustomImage(image: vendor.coverPhotoFullUrl!, width: 104, height: 104, fit: BoxFit.cover),
                  ),
                ),
              ]),
            ]),
          )),
        ),
      ),

      // Search pill straddling the green → content transition.
      Positioned(
        left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: 0,
        child: _searchPill(context, green),
      ),
    ]);
  }

  Widget _searchPill(BuildContext context, Color green) {
    return InkWell(
      onTap: onSearchTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Icon(Icons.search, color: Theme.of(context).hintColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(
            '${'search_for'.tr} ${'vehicles'.tr} ${'in'.tr} ${vendor.name ?? ''}...',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
          )),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Container(
              height: 36, width: 36, alignment: Alignment.center,
              decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              child: Icon(Icons.tune, color: green, size: 20),
            ),
          ),
        ]),
      ),
    );
  }

  /// Existing rental provider favourite logic — no new favourite implementation.
  Widget _favourite(BuildContext context) {
    return Container(
      height: 38, width: 38, alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
      child: TaxiAddFavouriteView(favIconSize: 20, providerId: vendor.id, iconColor: Colors.white),
    );
  }

  Widget _circle(BuildContext context, IconData icon, VoidCallback onTap, {Color? iconColor, bool subtle = false}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(30),
      child: Container(
        height: subtle ? 38 : 42, width: subtle ? 38 : 42, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: subtle ? Colors.white.withValues(alpha: 0.18) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? (subtle ? Colors.white : Theme.of(context).primaryColor), size: subtle ? 20 : 22),
      ),
    );
  }

  Widget _badgeCircle(BuildContext context, IconData icon, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(30),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 42, width: 42, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        ),
        if (count > 0) Positioned(
          right: -2, top: -2,
          child: Container(
            height: 18, width: 18, alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
            child: Text(count > 9 ? '9+' : '$count', style: robotoBold.copyWith(color: Colors.white, fontSize: 9)),
          ),
        ),
      ]),
    );
  }
}
