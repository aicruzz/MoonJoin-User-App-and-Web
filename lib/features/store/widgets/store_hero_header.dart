import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/widgets/all_restaurants_widgets.dart';
import 'package:sixam_mart/features/store/widgets/filter_widget.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Store/Restaurant page hero header (design `store_or_restaurant.png`): a green
/// hero (name, cuisines, rating · location · delivery, "N Dishes Available",
/// food image, back · favourite · share · notification · cart), an in-store
/// search pill, and the filter-chip row. Shared by every storefront module
/// (Food/Grocery/Pharmacy/E-commerce). Presentation only — every action reuses
/// the existing controllers/routes (favourite, share, search, filter, cart,
/// notifications); no new business logic.
class StoreHeroHeader extends StatelessWidget {
  final Store store;
  const StoreHeroHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    final storeController = Get.find<StoreController>();
    final bool showRestaurant = Get.find<SplashController>().configModel?.moduleConfig?.module?.showRestaurantText ?? false;

    final cats = storeController.categoryList ?? [];
    final String cuisines = cats.isEmpty
        ? ''
        : cats.take(3).map((c) => c.name ?? '').where((n) => n.isNotEmpty).join(', ') + (cats.length > 3 ? ' & ${'more'.tr}' : '');
    final int total = storeController.storeItemModel?.totalSize ?? 0;
    final bool isOpen = storeController.isStoreOpenNow(store.active ?? false, store.schedules);

    return Column(children: [
      // Green hero with a rounded bottom (premium curve into the content); the
      // search pill straddles the green -> content transition (per the design).
      Stack(clipBehavior: Clip.none, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Container(
            decoration: BoxDecoration(color: green, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusExtraLarge))),
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraLarge),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Actions row
            Row(children: [
              _circle(context, Icons.arrow_back, () => Get.back()),
              const Spacer(),
              // Favourite + Share kept but visually subtle (translucent) so the
              // prominent actions match the design; no feature removed.
              _favourite(context),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _circle(context, Icons.share, () => storeController.shareStore(), subtle: true),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _badgeCircle(context, Icons.notifications_none, Get.find<NotificationController>().notificationList?.length ?? 0,
                  () => Get.toNamed(RouteHelper.getNotificationRoute())),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _badgeCircle(context, Icons.shopping_cart_outlined, Get.find<CartController>().cartList.length,
                  () => Get.toNamed(RouteHelper.getCartRoute())),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Name + info + hero image
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text((store.name ?? '').toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(color: Colors.white, fontSize: 28)),
                if (cuisines.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(cuisines, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.star, size: 15, color: Colors.amber.shade400),
                  const SizedBox(width: 3),
                  Text('${store.avgRating?.toStringAsFixed(1) ?? '0.0'} (${store.ratingCount ?? 0}+)',
                      style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
                  if ((store.deliveryTime ?? '').isNotEmpty) ...[
                    _dot(),
                    const Icon(Icons.access_time, size: 14, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(store.deliveryTime!, style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
                  ],
                ]),
                const SizedBox(height: 6),
                if ((store.address ?? '').isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on, size: 15, color: Colors.white),
                    const SizedBox(width: 3),
                    Flexible(child: Text(store.address!, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall))),
                  ]),
                const SizedBox(height: 6),
                Row(children: [
                  Text('$total ${showRestaurant ? 'dishes'.tr : 'items'.tr} ${'available'.tr}',
                      style: robotoBold.copyWith(color: const Color(0xFFFFC107), fontSize: Dimensions.fontSizeSmall)),
                  if (!isOpen) ...[
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                      child: Text('closed_now'.tr, style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraSmall)),
                    ),
                  ],
                ]),
              ])),
              if ((store.coverPhotoFullUrl ?? '').isNotEmpty) Padding(
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: CustomImage(image: store.coverPhotoFullUrl!, width: 104, height: 104, fit: BoxFit.cover),
                ),
              ),
            ]),
              ]),
            )),
          ),
        ),
        // Search pill straddling the green -> content transition.
        Positioned(
          left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: 0,
          child: _searchPill(context, green, showRestaurant),
        ),
      ]),

      // Filter chips row (on the page background)
      Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(children: [
            StoreFilterChip(label: 'filters'.tr, icon: Icons.tune, iconColor: green, labelColor: green, onTap: () => _openFilter(storeController)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            StoreFilterChip(label: 'sort'.tr, trailingDropdown: true, onTap: () => _openFilter(storeController)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            StoreFilterChip(label: 'cuisine'.tr, icon: Icons.restaurant_menu, onTap: () => _openFilter(storeController)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            StoreFilterChip(label: 'price'.tr, icon: Icons.sell_outlined, onTap: () => _openFilter(storeController)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            StoreFilterChip(label: 'delivery_time'.tr, icon: Icons.access_time, onTap: () => _openFilter(storeController)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            StoreFilterChip(label: 'more'.tr, icon: Icons.more_horiz, onTap: () => _openFilter(storeController)),
          ]),
        ),
      ),
    ]);
  }

  void _openFilter(StoreController storeController) {
    List<double?> prices = [];
    for (var product in storeController.storeItemModel?.items ?? []) {
      prices.add(product.price);
    }
    prices.sort();
    final double? maxValue = prices.isNotEmpty ? prices[prices.length - 1] : 1000;
    Get.dialog(FilterWidget(maxValue: maxValue));
  }

  /// In-store search pill (opens the existing store item search).
  Widget _searchPill(BuildContext context, Color green, bool showRestaurant) {
    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.getSearchStoreItemRoute(store.id)),
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
            '${'search_for'.tr} ${showRestaurant ? 'food'.tr : 'items'.tr} ${'in'.tr} ${store.name ?? ''}...',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
          )),
          Container(
            height: 36, width: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
            child: Icon(Icons.tune, color: green, size: 20),
          ),
        ]),
      ),
    );
  }

  Widget _favourite(BuildContext context) {
    return GetBuilder<FavouriteController>(builder: (favouriteController) {
      final bool isWished = favouriteController.wishStoreIdList.contains(store.id);
      return _circle(context, isWished ? Icons.favorite : Icons.favorite_border, () {
        if (AuthHelper.isLoggedIn()) {
          isWished ? favouriteController.removeFromFavouriteList(store.id, true)
              : favouriteController.addToFavouriteList(null, store.id, true);
        } else {
          showCustomSnackBar('you_are_not_logged_in'.tr);
        }
      }, subtle: true, iconColor: isWished ? Colors.white : null);
    });
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

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
    child: CircleAvatar(radius: 2, backgroundColor: Colors.white),
  );
}
