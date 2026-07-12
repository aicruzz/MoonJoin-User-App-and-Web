import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet.dart' show VariationView;
import 'package:sixam_mart/common/widgets/moonjoin/wavy_header.dart';
import 'package:sixam_mart/common/widgets/quantity_button.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/item_cart_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:share_plus/share_plus.dart';

/// Full-page Food Product Details (ui-designs/product_details_for_only_food.PNG):
/// green wavy header + hero image, name/veg/rating/price, Food Type / Size
/// variation cards, Extras add-on cards, and a Total + quantity + Add-to-Cart
/// footer. Presentation only — all cart/variation/add-on/campaign/stock logic is
/// the existing [ItemController] + shared [ItemCartHelper] (no duplicated logic).
class FoodDetailsScreen extends StatefulWidget {
  final int itemId;
  final bool inStorePage;
  final bool isCampaign;
  final Item? item;
  /// EDIT MODE: when [cart] + [onCartItemAdd] are supplied the page preloads the
  /// existing selections (quantity, variations, add-ons) and shows a "Save"
  /// button that returns the edited item via [onCartItemAdd] instead of adding a
  /// new cart entry. Same single Food Product Details implementation for both
  /// adding and editing.
  final CartModel? cart;
  final Function(CartModel)? onCartItemAdd;
  const FoodDetailsScreen({super.key, required this.itemId, this.inStorePage = false, this.isCampaign = false, this.item, this.cart, this.onCartItemAdd});

  bool get isEdit => onCartItemAdd != null;

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  bool _newVariation = false;

  @override
  void initState() {
    super.initState();
    final itemController = Get.find<ItemController>();
    final splashController = Get.find<SplashController>();
    if (splashController.module == null && splashController.cacheModule != null) {
      splashController.setCacheConfigModule(splashController.cacheModule);
    }
    itemController.getItemDetails(itemId: widget.itemId, cart: widget.cart, item: widget.isCampaign ? widget.item : widget.item).then((_) {
      if (itemController.item != null) {
        _newVariation = splashController.getModuleConfig(itemController.item!.moduleType).newVariation ?? false;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bodyBg = Theme.of(context).brightness == Brightness.light ? const Color(0xFFF6F8F0) : Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bodyBg,
      body: GetBuilder<CartController>(builder: (cartController) {
        return GetBuilder<ItemController>(builder: (itemController) {
          final Item? item = itemController.item;
          if (item == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final ItemCartData data = ItemCartHelper.compute(item, itemController, _newVariation);
          final bool stockOut = Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && (data.stock ?? 0) <= 0;

          return Stack(children: [
            Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                    _header(context, item),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
                      child: _titleBlock(context, item, data),
                    ),

                    // Food Type / Size / other food-variation groups
                    if (_newVariation)
                      ...List.generate(item.foodVariations!.length, (index) => _FoodVariationSection(
                        item: item, itemController: itemController, groupIndex: index,
                        discount: data.initialDiscount, discountType: data.discountType,
                      ))
                    else if (item.choiceOptions!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: _cardDecoration(context),
                        child: VariationView(item: item, itemController: itemController),
                      ),

                    // Extras (add-ons)
                    if (Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn! && item.addOns!.isNotEmpty)
                      _ExtrasSection(item: item, itemController: itemController),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                  ]),
                ),
              ),

              _footer(context, item, itemController, cartController, data, stockOut),
            ]),
          ]);
        });
      }),
    );
  }

  static BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
  );

  /// Green wavy header: controls row pinned to the top, hero image straddling
  /// the wave below it.
  Widget _header(BuildContext context, Item item) {
    final Color green = Theme.of(context).primaryColor;
    return SizedBox(
      height: 330,
      child: Stack(clipBehavior: Clip.none, children: [

        // Green wave
        Positioned(top: 0, left: 0, right: 0, child: WavyHeader(height: 250, color: green)),

        // Hero image straddling the wave
        Positioned(
          top: 92, left: 0, right: 0,
          child: Center(child: InkWell(
            onTap: widget.isCampaign ? null : () => Get.toNamed(RouteHelper.getItemImagesRoute(item)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              child: CustomImage(image: item.imageFullUrl ?? '', width: 210, height: 210, fit: BoxFit.cover),
            ),
          )),
        ),

        // Controls row (back · store · share · favourite) pinned to the top
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
            child: Row(children: [
              _circleIcon(context, Icons.arrow_back, () => Get.back()),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Container(
                height: 34, width: 34, alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                child: Text((item.storeName ?? '?').isNotEmpty ? item.storeName!.characters.first.toUpperCase() : '?',
                    style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Flexible(child: Text(item.storeName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(color: Colors.white.withValues(alpha: 0.95), fontSize: Dimensions.fontSizeDefault))),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                  const SizedBox(width: 3),
                  Text((item.avgRating ?? 0).toStringAsFixed(1), style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
                ]),
              ),
              const Spacer(),
              _circleIcon(context, Icons.share, () {
                final String shareText = '${item.name}${item.storeName != null ? ' - ${item.storeName}' : ''}';
                SharePlus.instance.share(ShareParams(text: shareText));
              }),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _favIcon(context, item),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _titleBlock(BuildContext context, Item item, ItemCartData data) {
    final splash = Get.find<SplashController>();
    final bool showVeg = splash.configModel!.moduleConfig!.module!.vegNonVeg! && splash.configModel!.toggleVegNonVeg!;
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(item.name ?? '', textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: 26, color: Theme.of(context).textTheme.bodyLarge?.color)),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      if (showVeg)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset(item.veg == 1 ? Images.vegLogo : Images.nonVegLogo, height: 16, width: 16),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(item.veg == 1 ? 'veg'.tr : 'non_veg'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault)),
        ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      if (!widget.isCampaign)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          RatingBar(rating: item.avgRating ?? 0, size: 18, ratingCount: null),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text((item.avgRating ?? 0).toStringAsFixed(1), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(width: 3),
          Text('(${item.ratingCount ?? 0})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
        ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      Text(
        '${PriceConverter.convertPrice(data.startingPrice, discount: data.initialDiscount, discountType: data.discountType)}'
        '${data.endingPrice != null ? ' - ${PriceConverter.convertPrice(data.endingPrice, discount: data.initialDiscount, discountType: data.discountType)}' : ''}',
        textDirection: TextDirection.ltr,
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      if ((data.initialDiscount ?? 0) > 0)
        Text(
          '${PriceConverter.convertPrice(data.startingPrice)}${data.endingPrice != null ? ' - ${PriceConverter.convertPrice(data.endingPrice)}' : ''}',
          textDirection: TextDirection.ltr,
          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough, fontSize: Dimensions.fontSizeSmall),
        ),
    ]);
  }

  Widget _footer(BuildContext context, Item item, ItemController itemController, CartController cartController, ItemCartData data, bool stockOut) {
    if (!item.scheduleOrder! && !data.isAvailable) return const SizedBox();
    final double total = (PriceConverter.convertWithDiscount((data.price * itemController.quantity!), data.discount, data.discountType) ?? 0) + data.addonsCost;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('${'total_amount'.tr}:', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
            PriceConverter.convertAnimationPrice(total, textStyle: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraLarge)),
          ]),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Row(children: [
            QuantityButton(isIncrement: false, fromSheet: true, onTap: () {
              if (itemController.quantity! > 1) itemController.setQuantity(false, data.stock, item.quantityLimit, getxSnackBar: true);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(itemController.quantity.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
            ),
            QuantityButton(isIncrement: true, fromSheet: true, onTap: () => itemController.setQuantity(true, data.stock, item.quantityLimit, getxSnackBar: true)),
          ]),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: CustomButton(
            height: 50,
            isLoading: cartController.isLoading,
            radius: Dimensions.radiusLarge,
            buttonText: stockOut ? 'out_of_stock'.tr : widget.isEdit ? 'save'.tr : widget.isCampaign ? 'order_now'.tr : 'add_to_cart'.tr,
            onPressed: stockOut ? null : () async {
              await ItemCartHelper.addOrUpdateCart(
                context: context, item: item, itemController: itemController, data: data,
                isCampaign: widget.isCampaign, newVariation: _newVariation,
                cart: widget.cart, onCartItemAdd: widget.onCartItemAdd,
                onSuccess: () => showCartSnackBar(),
              );
            },
          )),
        ]),
      ),
    );
  }

  Widget _circleIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 40, width: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _favIcon(BuildContext context, Item item) {
    if (widget.isCampaign) return const SizedBox(width: 40);
    return GetBuilder<FavouriteController>(builder: (wishList) {
      final bool isWished = wishList.wishItemIdList.contains(item.id);
      return InkWell(
        onTap: () {
          if (AuthHelper.isLoggedIn()) {
            isWished ? wishList.removeFromFavouriteList(item.id, false, getXSnackBar: true)
                : wishList.addToFavouriteList(item, null, false, getXSnackBar: true);
          } else {
            showCustomSnackBar('you_are_not_logged_in'.tr, getXSnackBar: true);
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 40, width: 40,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), shape: BoxShape.circle),
          child: Icon(isWished ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 20),
        ),
      );
    });
  }
}

/// A single food-variation group (e.g. Food Type / Size) as a MoonJoin card with
/// a Required/Optional/Completed badge and selectable option cards. Reuses the
/// existing [ItemController] selection methods — no new business logic.
class _FoodVariationSection extends StatelessWidget {
  final Item item;
  final ItemController itemController;
  final int groupIndex;
  final double? discount;
  final String? discountType;
  const _FoodVariationSection({required this.item, required this.itemController, required this.groupIndex, this.discount, this.discountType});

  @override
  Widget build(BuildContext context) {
    final FoodVariation group = item.foodVariations![groupIndex];
    final bool multi = group.multiSelect!;
    int selectedCount = 0;
    for (var v in itemController.selectedVariations[groupIndex]) {
      if (v == true) selectedCount++;
    }
    final bool complete = group.required! && (multi ? group.min! : 1) <= selectedCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: _FoodDetailsScreenState._cardDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(group.name ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          _badge(context, group.required!, complete),
        ]),
        if (multi) Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('${'select_minimum'.tr} ${group.min} ${'and_up_to'.tr} ${group.max} ${'options'.tr}',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        LayoutBuilder(builder: (context, constraints) {
          const double gap = Dimensions.paddingSizeSmall;
          final double cardWidth = (constraints.maxWidth - (gap * 2)) / 3;
          // Short single-select labels (e.g. Medium/Large/Chairman) render as
          // compact pills with the control on the left (Figma "Size"); longer or
          // multi-line labels use the taller card with the control below ("Food Type").
          final bool compact = !multi && group.variationValues!.every((v) => (v.level ?? '').length <= 12);
          return Wrap(
            spacing: gap, runSpacing: gap,
            children: List.generate(group.variationValues!.length, (i) {
              final bool selected = itemController.selectedVariations[groupIndex][i]!;
              final double optionPrice = group.variationValues![i].optionPrice ?? 0;
              final Widget control = Icon(
                multi
                    ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                    : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                size: 22, color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
              );
              final Text label = Text(group.variationValues![i].level ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: (selected ? robotoMedium : robotoRegular).copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: selected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color));
              final Widget price = optionPrice > 0
                  ? Text('+${PriceConverter.convertPrice(optionPrice, discount: discount, discountType: discountType, isFoodVariation: true)}',
                      textDirection: TextDirection.ltr,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor))
                  : const SizedBox.shrink();

              return SizedBox(
                width: cardWidth,
                child: InkWell(
                  onTap: () => itemController.setNewCartVariationIndex(groupIndex, i, item),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: selected ? Theme.of(context).primaryColor.withValues(alpha: 0.06) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.35)),
                    ),
                    child: compact
                        ? Row(children: [
                            control,
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                              label, if (optionPrice > 0) price,
                            ])),
                          ])
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            label,
                            if (optionPrice > 0) Padding(padding: const EdgeInsets.only(top: 2), child: price),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            control,
                          ]),
                  ),
                ),
              );
            }),
          );
        }),
      ]),
    );
  }

  Widget _badge(BuildContext context, bool required, bool complete) {
    final Color color = required && !complete ? Theme.of(context).colorScheme.error : Theme.of(context).hintColor;
    final Color bg = required && !complete ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1) : Theme.of(context).disabledColor.withValues(alpha: 0.12);
    final String text = required ? (complete ? 'completed'.tr : 'required'.tr) : 'optional'.tr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      child: Text(text, style: robotoMedium.copyWith(color: color, fontSize: Dimensions.fontSizeSmall)),
    );
  }
}

/// Extras (add-ons) as a MoonJoin card of 2-column checkbox cards. Reuses the
/// existing [ItemController] add-on methods — no new business logic.
class _ExtrasSection extends StatelessWidget {
  final Item item;
  final ItemController itemController;
  const _ExtrasSection({required this.item, required this.itemController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: _FoodDetailsScreenState._cardDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('extras'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
            decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            child: Text('optional'.tr, style: robotoMedium.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        LayoutBuilder(builder: (context, constraints) {
          const double gap = Dimensions.paddingSizeSmall;
          final double cardWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap, runSpacing: gap,
            children: List.generate(item.addOns!.length, (index) {
              final bool active = itemController.addOnActiveList[index];
              return SizedBox(
                width: cardWidth,
                child: InkWell(
                  onTap: () {
                    if (!active) {
                      itemController.addAddOn(true, index);
                    } else if (itemController.addOnQtyList[index] == 1) {
                      itemController.addAddOn(false, index);
                    }
                  },
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: active ? Theme.of(context).primaryColor.withValues(alpha: 0.06) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: active ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(active ? Icons.check_box : Icons.check_box_outline_blank, size: 22,
                          color: active ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.addOns![index].name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: (active ? robotoMedium : robotoRegular).copyWith(fontSize: Dimensions.fontSizeSmall)),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.addOns![index].price! > 0 ? '+${PriceConverter.convertPrice(item.addOns![index].price)}' : 'free'.tr,
                            textDirection: TextDirection.ltr,
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall,
                                color: active ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
                          ),
                        ),
                      ])),
                    ]),
                  ),
                ),
              );
            }),
          );
        }),
      ]),
    );
  }
}
