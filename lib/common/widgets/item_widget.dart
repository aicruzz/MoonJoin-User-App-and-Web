import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/corner_banner/banner.dart';
import 'package:sixam_mart/common/widgets/corner_banner/corner_discount_tag.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/common/widgets/organic_tag.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemWidget extends StatelessWidget {
  final Item? item;
  final Store? store;
  final bool isStore;
  final int index;
  final int? length;
  final bool inStore;
  final bool isCampaign;
  final bool isFeatured;
  final bool fromCartSuggestion;
  final double? imageHeight;
  final double? imageWidth;
  final bool? isCornerTag;
  /// When true, the store/restaurant name shown under an item's title is hidden.
  /// Used only on the Item Search/List screen (see item_view_widget) per the
  /// approved MoonJoin design; defaults to false so Home and store cards are unaffected.
  final bool hideItemStoreName;
  /// Premium Store-page dish layout (design `store_or_restaurant.png`): larger
  /// rounded image, bold title, rating, price + old-price + `/unitType`, organic
  /// badge and a "View Details" action — rendered from **real Item data only**.
  /// Opt-in so every existing usage (Cart/Search/Category/Home) is unaffected;
  /// same widget, one shared implementation (no fork). Item items only.
  final bool premiumStoreLayout;
  const ItemWidget({super.key, required this.item, required this.isStore, required this.store, required this.index,
    required this.length, this.inStore = false, this.isCampaign = false, this.isFeatured = false,
    this.fromCartSuggestion = false, this.imageHeight, this.imageWidth, this.isCornerTag = false, this.hideItemStoreName = false,
    this.premiumStoreLayout = false});

  @override
  Widget build(BuildContext context) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    bool desktop = ResponsiveHelper.isDesktop(context);
    double? discount;
    String? discountType;
    bool isAvailable;
    String genericName = '';

    if(!isStore && item!.genericName != null && item!.genericName!.isNotEmpty) {
      for (String name in item!.genericName!) {
        genericName += name;
      }
    }
    if(isStore) {
      discount = store!.discount != null ? store!.discount!.discount : 0;
      discountType = store!.discount != null ? store!.discount!.discountType : 'percent';
      isAvailable = store!.open == 1 && store!.active!;
    }else {
      discount = item!.discount;
      discountType = item!.discountType;
      isAvailable = DateConverter.isAvailable(item!.availableTimeStarts, item!.availableTimeEnds);
    }

    if (premiumStoreLayout && !isStore && item != null) {
      return _premiumStoreDishCard(context, discount, discountType, isAvailable);
    }

    return Stack(
      children: [
        Container(
          margin: ResponsiveHelper.isDesktop(context) ? null : const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          child: CustomInkWell(
            onTap: () {
              if(isStore) {
                if(store != null) {
                  if(isFeatured && Get.find<SplashController>().moduleList != null) {
                    for(ModuleModel module in Get.find<SplashController>().moduleList!) {
                      if(module.id == store!.moduleId) {
                        Get.find<SplashController>().setModule(module);
                        break;
                      }
                    }
                  }
                  Get.toNamed(
                    RouteHelper.getStoreRoute(id: store!.id, page: isFeatured ? 'module' : 'item'),
                    arguments: StoreScreen(store: store, fromModule: isFeatured),
                  );
                }
              }else {
                if(isFeatured && Get.find<SplashController>().moduleList != null) {
                  for(ModuleModel module in Get.find<SplashController>().moduleList!) {
                    if(module.id == item!.moduleId) {
                      Get.find<SplashController>().setModule(module);
                      break;
                    }
                  }
                }
                Get.find<ItemController>().navigateToItemPage(item, context, inStore: inStore, isCampaign: isCampaign);
              }
            },
            radius: Dimensions.radiusDefault,
            padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.all(fromCartSuggestion ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall) : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
            child: TextHover(
              builder: (hovered) {
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                  Expanded(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: desktop ? 0 : Dimensions.paddingSizeExtraSmall),
                    child: Row(children: [

                      Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          child: CustomImage(
                            isHovered: hovered,
                            image: '${isStore ? store != null ? store!.logoFullUrl : '' : item!.imageFullUrl}',
                            height: imageHeight ?? (desktop ? 120 : length == null ? 100 : 90), width: imageWidth ?? (desktop ? 120 : 90), fit: BoxFit.cover,
                          ),
                        ),

                        (isStore || isCornerTag!) ? DiscountTag(
                          discount: discount, discountType: discountType,
                          freeDelivery: isStore ? store!.freeDelivery : false,
                        ) : const SizedBox(),

                        !isStore ? OrganicTag(item: item!, placeInImage: true) : const SizedBox(),

                        isAvailable ? const SizedBox() : NotAvailableWidget(isStore: isStore),

                        Positioned(
                          top: 5, left: 5,
                          child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                            bool isWished = isStore ? favouriteController.wishStoreIdList.contains(store!.id) : favouriteController.wishItemIdList.contains(item!.id);
                            return CustomFavouriteWidget(
                              isWished: isWished,
                              isStore: isStore,
                              store: store,
                              item: item,
                            );
                          }),
                        ),
                      ]),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [

                          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Flexible(
                              child: Text(
                                isStore ? store!.name! : item!.name!,
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            (!isStore && Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg!)
                                ? Image.asset(item != null && item!.veg == 0 ? Images.nonVegImage : Images.vegImage,
                                height: 10, width: 10, fit: BoxFit.contain) : const SizedBox(),

                            (Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! && item != null && item!.unitType != null) ? Text(
                              '(${ item!.unitType ?? ''})',
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                            ) : const SizedBox(),

                            SizedBox(width: item!.isStoreHalalActive! && item!.isHalalItem! ? Dimensions.paddingSizeExtraSmall : 0),

                            !isStore && item!.isStoreHalalActive! && item!.isHalalItem! ? const CustomAssetImageWidget(
                                Images.halalTag, height: 13, width: 13) : const SizedBox(),

                            SizedBox(width: ResponsiveHelper.isDesktop(context) ? 20 : 0),
                          ]),
                          const SizedBox(height: 3),

                          inStore ? const SizedBox() : (isStore ? store!.address != null : (item!.storeName != null && !hideItemStoreName)) ? Text(
                            isStore ? store!.address ?? '' : item!.storeName ?? '',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).disabledColor,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ) : const SizedBox(),

                          (genericName.isNotEmpty) ? Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                genericName,
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).disabledColor,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ) : const SizedBox(),
                          SizedBox(height: ((desktop || isStore) && (isStore ? store!.address != null : item!.storeName != null)) ? 3 : 3),

                          !isStore && (item!.ratingCount! > 0) ? Row(children: [

                            Icon(Icons.star, size: 16, color: Theme.of(context).primaryColor),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Text(
                              item!.avgRating!.toStringAsFixed(1),
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Text(
                              '(${item!.ratingCount})',
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                            ),

                          ]) : const SizedBox(),

                          SizedBox(height: (!isStore && desktop) || (!isStore && (item!.ratingCount! > 0)) ? 3 : 0),

                          isStore && (store != null && store!.ratingCount! > 0) ? Row(children: [

                            Icon(Icons.star, size: 16, color: Theme.of(context).primaryColor),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Text(
                              store!.avgRating!.toStringAsFixed(1),
                              style: robotoMedium,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Text(
                              '(${store!.ratingCount})',
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                            ),

                          ]) : Row(children: [
                            Text(
                              PriceConverter.convertPrice(item!.price, discount: discount, discountType: discountType),
                              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall), textDirection: TextDirection.ltr,
                            ),
                            SizedBox(width: discount! > 0 ? Dimensions.paddingSizeExtraSmall : 0),

                            discount > 0 ? Text(
                              PriceConverter.convertPrice(item!.price),
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).disabledColor,
                                decoration: TextDecoration.lineThrough,
                              ), textDirection: TextDirection.ltr,
                            ) : const SizedBox(),
                          ]),

                        ]),
                      ),

                      Column(mainAxisAlignment: isStore ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween, children: [

                        const SizedBox(),

                        CartCountView(
                          item: item!,
                          index: index,
                        ),

                      ]),

                    ]),
                  )),

                ]);
              }
            ),
          ),
        ),

        (!isStore && isCornerTag! == false) ? Positioned(
          right: ltr ? 0 : null, left: ltr ? null : 0,
          child: CornerDiscountTag(
            bannerPosition: ltr ? CornerBannerPosition.topRight : CornerBannerPosition.topLeft,
            elevation: 0,
            discount: discount, discountType: discountType,
            freeDelivery: isStore ? store!.freeDelivery : false,
        )) : const SizedBox(),

      ],
    );
  }

  /// Premium Store-page dish card (design `store_or_restaurant.png`) — real Item
  /// data only, no fabricated badges/chips. Reuses the existing image, discount,
  /// organic and favourite treatments and the existing item navigation.
  Widget _premiumStoreDishCard(BuildContext context, double? discount, String? discountType, bool isAvailable) {
    final bool showVeg = Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg!;
    final bool showUnit = Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! && item!.unitType != null && item!.unitType!.isNotEmpty;
    final Color primary = Theme.of(context).primaryColor;

    return Container(
      height: 122,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomInkWell(
        onTap: () => Get.find<ItemController>().navigateToItemPage(item, context, inStore: inStore, isCampaign: isCampaign),
        radius: Dimensions.radiusLarge,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // Uniform image: fills the fixed 122×122 area (cover-cropped, centered,
          // never stretched) so every dish image is exactly the same size
          // regardless of the original portrait/landscape aspect ratio.
          SizedBox(
            width: 122,
            child: Stack(fit: StackFit.expand, children: [
              CustomImage(image: '${item!.imageFullUrl}', fit: BoxFit.cover),
              DiscountTag(discount: discount, discountType: discountType, freeDelivery: false),
              OrganicTag(item: item!, placeInImage: true),
              isAvailable ? const SizedBox() : NotAvailableWidget(isStore: false, isAllSideRound: false),
            ]),
          ),

          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(item!.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault))),
                if (showVeg) ...[
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Image.asset(item!.veg == 0 ? Images.nonVegImage : Images.vegImage, height: 12, width: 12, fit: BoxFit.contain),
                ],
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                GetBuilder<FavouriteController>(builder: (favouriteController) {
                  final bool isWished = favouriteController.wishItemIdList.contains(item!.id);
                  return CustomFavouriteWidget(isWished: isWished, isStore: false, store: null, item: item);
                }),
              ]),

              if ((item!.ratingCount ?? 0) > 0)
                Row(children: [
                  Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                  const SizedBox(width: 3),
                  Text(item!.avgRating!.toStringAsFixed(1), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                  const SizedBox(width: 3),
                  Text('(${item!.ratingCount})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                ]),

              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Text(PriceConverter.convertPrice(item!.price, discount: discount, discountType: discountType),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: primary))),
                  if ((discount ?? 0) > 0) ...[
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(PriceConverter.convertPrice(item!.price), textDirection: TextDirection.ltr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough)),
                  ],
                  if (showUnit) Flexible(child: Text(' /${item!.unitType}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor))),
                ])),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: primary),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('view_details'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: primary)),
                    Icon(Icons.chevron_right, size: 14, color: primary),
                  ]),
                ),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}
