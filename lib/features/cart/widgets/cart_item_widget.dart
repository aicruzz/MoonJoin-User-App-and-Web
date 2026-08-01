import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet.dart';
import 'package:sixam_mart/common/widgets/quantity_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';

class CartItemWidget extends StatefulWidget {
  final CartModel cart;
  final int cartIndex;
  final List<AddOns> addOns;
  final bool isAvailable;
  final bool showDivider;
  const CartItemWidget({super.key, required this.cart, required this.cartIndex, required this.isAvailable, required this.addOns, required this.showDivider});

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {

  @override
  Widget build(BuildContext context) {

    double? startingPrice = _calculatePrice(item: widget.cart.item);
    double? endingPrice = _calculatePrice(item: widget.cart.item, isStartingPrice: false);

    double? discount = widget.cart.item!.discount;
    String? discountType = widget.cart.item!.discountType;
    String genericName = '';

    if(widget.cart.item!.genericName != null && widget.cart.item!.genericName!.isNotEmpty) {
      for (String name in widget.cart.item!.genericName!) {
        genericName += name;
      }
    }

    final SplashController splash = Get.find<SplashController>();
    final bool isRestaurant = splash.getModuleConfig(widget.cart.item!.moduleType).showRestaurantText ?? false;
    final bool showStore = isRestaurant && (widget.cart.item!.storeName ?? '').isNotEmpty;
    final String subtitle = genericName.isNotEmpty ? genericName : (widget.cart.item!.unitType ?? '');
    final List<(String, String)> changeRows = _variationChangeRows();

    // MoonJoin cart card (Figma YOUR CART) — self-contained white card; the top
    // row shows image · info · favourite/quantity, with an optional variation
    // "Change" panel for items that have variations. Slidable-delete, tap-to-edit
    // and all pricing/variation/add-on logic are preserved unchanged.
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Slidable(
        key: UniqueKey(),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) {
                Get.find<CartController>().removeFromCart(widget.cartIndex, item: widget.cart.item);
              },
              backgroundColor: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              foregroundColor: Colors.white,
              icon: CupertinoIcons.delete,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomInkWell(
            onTap: () {
              // MoonJoin Cart Item Edit: mobile opens the approved full-page Product
              // Details in edit mode (updates the existing line, no duplicate). Desktop
              // keeps the ItemBottomSheet dialog (already-consistent desktop journey).
              if (ResponsiveHelper.isMobile(context)) {
                Get.find<ItemController>().navigateToCartItemEdit(widget.cart.item, cart: widget.cart);
              } else {
                showDialog(context: context, builder: (con) => Dialog(
                  child: ItemBottomSheet(itemId: widget.cart.item!.id!, cartIndex: widget.cartIndex, cart: widget.cart),
                ));
              }
            },
            radius: Dimensions.radiusLarge,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: CustomImage(
                      image: '${widget.cart.item!.imageFullUrl}',
                      height: ResponsiveHelper.isDesktop(context) ? 90 : 64, width: ResponsiveHelper.isDesktop(context) ? 90 : 64, fit: BoxFit.cover,
                    ),
                  ),
                  widget.isAvailable ? const SizedBox() : Positioned.fill(child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), color: Colors.black.withValues(alpha: 0.6)),
                    child: Text('not_available_now_break'.tr, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Colors.white, fontSize: 8)),
                  )),
                ]),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Flexible(child: Text(widget.cart.item!.name!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      SizedBox(width: widget.cart.item!.isStoreHalalActive! && widget.cart.item!.isHalalItem! ? Dimensions.paddingSizeExtraSmall : 0),
                      widget.cart.item!.isStoreHalalActive! && widget.cart.item!.isHalalItem!
                          ? const CustomAssetImageWidget(Images.halalTag, height: 13, width: 13) : const SizedBox(),
                    ]),

                    if (showStore) Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(widget.cart.item!.storeName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                    ) else if (subtitle.isNotEmpty) Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
                    ),

                    if (isRestaurant && (widget.cart.item!.avgRating ?? 0) > 0) Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(children: [
                        RatingBar(rating: widget.cart.item!.avgRating ?? 0, size: 13, ratingCount: null),
                        const SizedBox(width: 3),
                        Text('${(widget.cart.item!.avgRating ?? 0).toStringAsFixed(1)} (${widget.cart.item!.ratingCount ?? 0})',
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
                      ]),
                    ),

                    const SizedBox(height: 3),
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(
                        '${PriceConverter.convertPrice(startingPrice, discount: discount, discountType: discountType)}'
                            '${endingPrice != null ? ' - ${PriceConverter.convertPrice(endingPrice, discount: discount, discountType: discountType)}' : ''}',
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault), textDirection: TextDirection.ltr,
                      ),
                      SizedBox(width: discount! > 0 ? Dimensions.paddingSizeExtraSmall : 0),
                      discount > 0 ? Text(
                        '${PriceConverter.convertPrice(startingPrice)}${endingPrice != null ? ' - ${PriceConverter.convertPrice(endingPrice)}' : ''}',
                        textDirection: TextDirection.ltr,
                        style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough, fontSize: Dimensions.fontSizeExtraSmall),
                      ) : const SizedBox(),
                    ]),

                    widget.cart.item!.isPrescriptionRequired! ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('* ${'prescription_required'.tr}',
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).colorScheme.error)),
                    ) : const SizedBox(),
                  ]),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _FavouriteButton(item: widget.cart.item!),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  GetBuilder<CartController>(builder: (cartController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        QuantityButton(
                          // Always active: quantity updates instantly and syncs in
                          // the background (debounced), matching the shared behaviour.
                          onTap: () {
                            if (widget.cart.quantity! > 1) {
                              Get.find<CartController>().setQuantity(false, widget.cartIndex, widget.cart.stock, widget.cart.quantityLimit);
                            } else {
                              Get.find<CartController>().removeFromCart(widget.cartIndex, item: widget.cart.item);
                            }
                          },
                          isIncrement: false,
                          showRemoveIcon: widget.cart.quantity! == 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(widget.cart.quantity.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        ),
                        QuantityButton(
                          // Always active: quantity updates instantly and syncs in
                          // the background (debounced), matching the shared behaviour.
                          onTap: () {
                            Get.find<CartController>().forcefullySetModule(Get.find<CartController>().cartList[0].item!.moduleId!);
                            Get.find<CartController>().setQuantity(true, widget.cartIndex, widget.cart.stock, widget.cart.quantityLimit);
                          },
                          isIncrement: true,
                        ),
                      ]),
                    );
                  }),
                ]),
              ]),

              // Variation "Change" panel (items with variations)
              if (changeRows.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Column(children: List.generate(changeRows.length, (i) => Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : Dimensions.paddingSizeExtraSmall),
                    child: Row(children: [
                      Text(changeRows[i].$1, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                      Text('  ·  ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                      Expanded(child: Text(changeRows[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
                      InkWell(
                        onTap: () {
                          // Same MoonJoin Cart Item Edit journey as the card tap.
                          if (ResponsiveHelper.isMobile(context)) {
                            Get.find<ItemController>().navigateToCartItemEdit(widget.cart.item, cart: widget.cart);
                          } else {
                            showDialog(context: context, builder: (con) => Dialog(
                              child: ItemBottomSheet(itemId: widget.cart.item!.id!, cartIndex: widget.cartIndex, cart: widget.cart),
                            ));
                          }
                        },
                        child: Text('change'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
                      ),
                    ]),
                  ))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// Per-group "GroupName · selected values" rows for the variation Change panel.
  /// Reuses the same selection data as the (preserved) variation/add-on logic.
  List<(String, String)> _variationChangeRows() {
    final List<(String, String)> rows = [];
    final CartModel cart = widget.cart;
    if (Get.find<SplashController>().getModuleConfig(cart.item!.moduleType).newVariation!) {
      if (cart.foodVariations != null) {
        for (int index = 0; index < cart.foodVariations!.length; index++) {
          if (cart.foodVariations![index].contains(true)) {
            final List<String> values = [];
            for (int i = 0; i < cart.foodVariations![index].length; i++) {
              if (cart.foodVariations![index][i]!) {
                values.add(cart.item!.foodVariations![index].variationValues![i].level ?? '');
              }
            }
            rows.add((cart.item!.foodVariations![index].name ?? '', values.join(', ')));
          }
        }
      }
    } else if (cart.variation != null && cart.variation!.isNotEmpty) {
      final List<String> types = cart.variation![0].type!.split('-');
      if (types.length == cart.item!.choiceOptions!.length) {
        for (int i = 0; i < cart.item!.choiceOptions!.length; i++) {
          rows.add((cart.item!.choiceOptions![i].title ?? '', types[i]));
        }
      }
    }
    return rows;
  }

  double? _calculatePrice({required Item? item, bool isStartingPrice = true}) {
    double? startingPrice;
    double? endingPrice;
    bool newVariation = Get.find<SplashController>().getModuleConfig(item!.moduleType).newVariation ?? false;

    if(item.variations!.isNotEmpty && !newVariation) {
      List<double?> priceList = [];
      for (var variation in item.variations!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if(priceList[0]! < priceList[priceList.length-1]!) {
        endingPrice = priceList[priceList.length-1];
      }
    }else {
      startingPrice = item.price;
    }
    if(isStartingPrice) {
      return startingPrice;
    } else {
      return endingPrice;
    }
  }

}

/// Favourite (wish-list) toggle for a cart item — reuses the existing
/// [FavouriteController]; no new business logic.
class _FavouriteButton extends StatelessWidget {
  final Item item;
  const _FavouriteButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FavouriteController>(builder: (wishController) {
      final bool isWished = wishController.wishItemIdList.contains(item.id);
      return InkWell(
        onTap: () {
          if (AuthHelper.isLoggedIn()) {
            isWished ? wishController.removeFromFavouriteList(item.id, false, getXSnackBar: true)
                : wishController.addToFavouriteList(item, null, false, getXSnackBar: true);
          } else {
            showCustomSnackBar('you_are_not_logged_in'.tr, getXSnackBar: true);
          }
        },
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: Container(
          height: 30, width: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
          ),
          child: Icon(isWished ? Icons.favorite : Icons.favorite_border, size: 16,
              color: isWished ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
        ),
      );
    });
  }
}
