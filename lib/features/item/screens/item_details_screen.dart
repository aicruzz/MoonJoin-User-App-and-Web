import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/moonjoin/wavy_header.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/item/widgets/details_web_view_widget.dart';

class ItemDetailsScreen extends StatefulWidget {
  final int itemId;
  final bool inStorePage;
  final bool isCampaign;
  final Item? item;
  /// EDIT MODE (from Cart): when [cart] is supplied the page preloads the existing
  /// variations/add-ons/quantity via getItemDetails(cart:) (which sets
  /// itemController.cartIndex) and UPDATES the existing cart line instead of adding
  /// a new one. Same single Shared Product Details implementation — no layout change.
  final CartModel? cart;
  const ItemDetailsScreen({super.key, required this.itemId, required this.inStorePage, this.isCampaign = false, this.item, this.cart});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final Size size = Get.size;
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  final PageController _imageController = PageController();

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Get.find<ItemController>().getItemDetails(itemId: widget.itemId, cart: widget.cart, item: widget.isCampaign ? widget.item : null);
    Get.find<ItemController>().setSelect(0, false);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<ItemController>(builder: (itemController) {

        Item? item = itemController.item;

        int? stock = 0;
        CartModel? cartModel;
        OnlineCart? cart;
        double priceWithAddons = 0;
        int? cartId = cartController.getCartId(itemController.cartIndex);
        if(item != null && itemController.variationIndex != null){
          List<String> variationList = [];
          for (int index = 0; index < item.choiceOptions!.length; index++) {
            variationList.add(item.choiceOptions![index].options![itemController.variationIndex![index]].replaceAll(' ', ''));
          }
          String variationType = '';
          bool isFirst = true;
          for (var variation in variationList) {
            if (isFirst) {
              variationType = '$variationType$variation';
              isFirst = false;
            } else {
              variationType = '$variationType-$variation';
            }
          }

          double? price = item.price;
          Variation? variation;
          stock = item.stock ?? 0;
          for (Variation v in item.variations!) {
            if (v.type == variationType) {
              price = v.price;
              variation = v;
              stock = v.stock;
              break;
            }
          }

          double? discount = item.discount;
          String? discountType = item.discountType;
          double priceWithDiscount = PriceConverter.convertWithDiscount(price, discount, discountType)!;
          double priceWithQuantity = priceWithDiscount * itemController.quantity!;
          double addonsCost = 0;
          List<AddOn> addOnIdList = [];
          List<AddOns> addOnsList = [];
          for (int index = 0; index < item.addOns!.length; index++) {
            if (itemController.addOnActiveList[index]) {
              addonsCost = addonsCost + (item.addOns![index].price! * itemController.addOnQtyList[index]!);
              addOnIdList.add(AddOn(id: item.addOns![index].id, quantity: itemController.addOnQtyList[index]));
              addOnsList.add(item.addOns![index]);
            }
          }

          cartModel = CartModel(
            null, price, priceWithDiscount, variation != null ? [variation] : [], [],
            (price! - PriceConverter.convertWithDiscount(price, discount, discountType)!),
            itemController.quantity, addOnIdList, addOnsList, item.availableDateStarts != null, stock, item,
            item.quantityLimit,
          );

          List<int?> listOfAddOnId = _getSelectedAddonIds(addOnIdList: addOnIdList);
          List<int?> listOfAddOnQty = _getSelectedAddonQtnList(addOnIdList: addOnIdList);

          cart = OnlineCart(
            cartId, widget.itemId, null, priceWithDiscount.toString(), '',
            variation != null ? [variation] : [], null,
            itemController.cartIndex != -1 ? cartController.cartList[itemController.cartIndex].quantity 
              : itemController.quantity, listOfAddOnId, addOnsList, listOfAddOnQty, 'Item'
          );
          priceWithAddons = priceWithQuantity + (Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn! ? addonsCost : 0);
        }

        final bool isDesktop = ResponsiveHelper.isDesktop(context);
        final bool stockOut = Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && (stock ?? 0) <= 0;
        final Color bodyBg = Theme.of(context).brightness == Brightness.light ? const Color(0xFFF6F8F0) : Theme.of(context).scaffoldBackgroundColor;
        final double totalValue = itemController.cartIndex != -1
            ? _getItemDetailsDiscountPrice(cart: Get.find<CartController>().cartList[itemController.cartIndex])
            : priceWithAddons;

        return Scaffold(
          key: _globalKey,
          backgroundColor: isDesktop ? Theme.of(context).cardColor : bodyBg,
          endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
          appBar: isDesktop ? const CustomAppBar(title: '') : null,

          body: (item == null) ? const Center(child: CircularProgressIndicator())
            : isDesktop ? SafeArea(child: DetailsWebViewWidget(
                cartModel: cartModel, stock: stock, priceWithAddOns: priceWithAddons, cart: cart,
              ))
            // MoonJoin grocery/others product details (ui-designs/product_details_for_grocery_and_others_module.png):
            // green wavy header + image carousel, name/store/price/rating + In-Stock badge, Size/Type variation
            // chips, quantity stepper, Total, and a fixed Total + qty + Add-to-Cart footer. Presentation only —
            // all pricing/variation/stock/cart logic (the computed cartModel/cart/priceWithAddons/stock above)
            // is the existing production logic, unchanged.
            : Column(children: [
                Expanded(child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                    _header(context, item, itemController),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
                      child: _titleBlock(context, item, stockOut),
                    ),

                    // Variation chip rows (Size / Type / …)
                    if (item.choiceOptions!.isNotEmpty)
                      ...List.generate(item.choiceOptions!.length, (index) => _variationChipGroup(context, item, itemController, index)),

                    // Quantity + Total
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('quantity'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                          const Spacer(),
                          _quantityStepper(context, item, itemController, cartController, stock),
                        ]),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        Row(children: [
                          Text('${'total_amount'.tr}:', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          Text(
                            PriceConverter.convertPrice(totalValue), textDirection: TextDirection.ltr,
                            style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                          ),
                        ]),
                      ]),
                    ),

                    _extraInfo(context, item),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                  ]),
                )),

                _footer(context, item, itemController, cartController, cartModel, cart, stock, totalValue, stockOut),
              ]),
        );
      });
    });
  }

  // ---------- MoonJoin grocery/others presentation helpers (no business logic) ----------

  /// Green wavy header: controls row pinned to the top + image carousel straddling the wave.
  Widget _header(BuildContext context, Item item, ItemController itemController) {
    final Color green = Theme.of(context).primaryColor;
    final List<String?> images = [];
    if (widget.isCampaign) {
      images.add(item.imageFullUrl);
    } else {
      images.add(item.imageFullUrl);
      images.addAll(item.imagesFullUrl ?? []);
    }

    return SizedBox(
      height: 384,
      child: Stack(clipBehavior: Clip.none, children: [

        Positioned(top: 0, left: 0, right: 0, child: WavyHeader(height: 250, color: green)),

        // Image carousel straddling the wave — sits comfortably below the top controls row.
        Positioned(
          top: 132, left: 0, right: 0,
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _imageController,
              itemCount: images.length,
              onPageChanged: (i) => itemController.setImageSliderIndex(i),
              itemBuilder: (_, i) => Center(child: InkWell(
                onTap: widget.isCampaign ? null : () => Get.toNamed(RouteHelper.getItemImagesRoute(item)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  child: CustomImage(image: images[i] ?? '', width: 230, height: 200, fit: BoxFit.cover),
                ),
              )),
            ),
          ),
        ),

        // Carousel dots
        if (images.length > 1)
          Positioned(top: 340, left: 0, right: 0, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 7, width: i == itemController.imageSliderIndex ? 18 : 7,
              decoration: BoxDecoration(
                color: i == itemController.imageSliderIndex ? green : Theme.of(context).disabledColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              ),
            )),
          )),

        // Controls row (back · store · share · favourite)
        Positioned(top: 0, left: 0, right: 0, child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
            child: Row(children: [
              _circleIcon(context, Icons.arrow_back, () => Get.back()),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Container(
                height: 34, width: 34, alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                child: Icon(Icons.storefront, color: green, size: 20),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Flexible(child: Text(item.storeName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(color: Colors.white.withValues(alpha: 0.95), fontSize: Dimensions.fontSizeDefault))),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
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
              _favCircle(context, item),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _titleBlock(BuildContext context, Item item, bool stockOut) {
    final bool hasDiscount = (item.discount ?? 0) > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(item.name ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Theme.of(context).textTheme.bodyLarge?.color))),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        _favCard(context, item),
      ]),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

      Text(item.storeName ?? '', style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(
            PriceConverter.convertPrice(item.price, discount: item.discount, discountType: item.discountType),
            textDirection: TextDirection.ltr,
            style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraLarge),
          ),
          if (hasDiscount) Text(
            PriceConverter.convertPrice(item.price), textDirection: TextDirection.ltr,
            style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall, decoration: TextDecoration.lineThrough),
          ),
        ]),
        const Spacer(),
        if ((item.unitType ?? '').isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 5),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            child: Text(item.unitType!, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
          ),
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      Row(children: [
        RatingBar(rating: item.avgRating ?? 0, size: 16, ratingCount: null),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text((item.avgRating ?? 0).toStringAsFixed(1), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        const SizedBox(width: 3),
        Text('(${item.ratingCount ?? 0})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
        const Spacer(),
        _stockBadge(context, stockOut),
      ]),

      Divider(height: Dimensions.paddingSizeExtraLarge, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
    ]);
  }

  Widget _variationChipGroup(BuildContext context, Item item, ItemController itemController, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.choiceOptions![index].title ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Wrap(
          spacing: Dimensions.paddingSizeSmall, runSpacing: Dimensions.paddingSizeSmall,
          children: List.generate(item.choiceOptions![index].options!.length, (i) {
            final bool selected = itemController.variationIndex![index] == i;
            return InkWell(
              onTap: () => itemController.setCartVariationIndex(index, i, item),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall + 2),
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Text(
                  item.choiceOptions![index].options![i].trim(),
                  style: robotoMedium.copyWith(color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _quantityStepper(BuildContext context, Item item, ItemController itemController, CartController cartController, int? stock) {
    final String qty = itemController.cartIndex != -1
        ? cartController.cartList[itemController.cartIndex].quantity.toString()
        : itemController.quantity.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _stepButton(context, isIncrement: false, onTap: cartController.isLoading ? null : () {
          if (itemController.cartIndex != -1) {
            if (cartController.cartList[itemController.cartIndex].quantity! > 1) {
              cartController.setQuantity(false, itemController.cartIndex, stock, cartController.cartList[itemController.cartIndex].quantity);
            }
          } else {
            if (itemController.quantity! > 1) itemController.setQuantity(false, stock, item.quantityLimit);
          }
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          child: Text(qty, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),
        _stepButton(context, isIncrement: true, onTap: cartController.isLoading ? null : () => itemController.cartIndex != -1
            ? cartController.setQuantity(true, itemController.cartIndex, stock, cartController.cartList[itemController.cartIndex].quantityLimit)
            : itemController.setQuantity(true, stock, item.quantityLimit)),
      ]),
    );
  }

  Widget _stepButton(BuildContext context, {required bool isIncrement, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 30, width: 30, alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isIncrement ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.15),
        ),
        child: Icon(isIncrement ? Icons.add : Icons.remove, size: 16,
            color: isIncrement ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _extraInfo(BuildContext context, Item item) {
    final List<Widget> children = [];
    if (item.isPrescriptionRequired!) {
      children.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        child: Text('* ${'prescription_required'.tr}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error)),
      ));
    }
    if (item.description != null && item.description!.isNotEmpty) {
      children.addAll([
        Text('description'.tr, style: robotoBold), const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(item.description!, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7))),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ]);
    }
    if (item.nutritionsName != null && item.nutritionsName!.isNotEmpty) {
      children.addAll([
        Text('nutrition_details'.tr, style: robotoBold), const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Wrap(children: List.generate(item.nutritionsName!.length, (i) => Text(
          '${item.nutritionsName![i]}${item.nutritionsName!.length - 1 == i ? '.' : ', '}',
          style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.5)),
        ))),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ]);
    }
    if (item.allergiesName != null && item.allergiesName!.isNotEmpty) {
      children.addAll([
        Text('allergic_ingredients'.tr, style: robotoBold), const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Wrap(children: List.generate(item.allergiesName!.length, (i) => Text(
          '${item.allergiesName![i]}${item.allergiesName!.length - 1 == i ? '.' : ', '}',
          style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.5)),
        ))),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ]);
    }
    if (children.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraLarge, Dimensions.paddingSizeDefault, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _footer(BuildContext context, Item item, ItemController itemController, CartController cartController, CartModel? cartModel, OnlineCart? cart, int? stock, double totalValue, bool stockOut) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      child: SafeArea(top: false, child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('${'total_amount'.tr}:', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
          Text(PriceConverter.convertPrice(totalValue), textDirection: TextDirection.ltr,
              style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraLarge)),
        ]),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        _quantityStepper(context, item, itemController, cartController, stock),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: CustomButton(
          height: 50,
          radius: Dimensions.radiusLarge,
          icon: Icons.shopping_cart_outlined,
          isLoading: cartController.isLoading,
          buttonText: stockOut ? 'out_of_stock'.tr
              : item.availableDateStarts != null ? 'order_now'.tr
              : itemController.cartIndex != -1 ? 'update_in_cart'.tr : 'add_to_cart'.tr,
          onPressed: stockOut ? null : () => _addToCart(context, item, itemController, cartController, cartModel, cart, stock),
        )),
      ])),
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

  Widget _favCircle(BuildContext context, Item item) {
    if (widget.isCampaign) return const SizedBox(width: 40);
    return GetBuilder<FavouriteController>(builder: (wishList) {
      final bool isWished = wishList.wishItemIdList.contains(item.id);
      return InkWell(
        onTap: () => _toggleFav(isWished, item, wishList),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 40, width: 40,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), shape: BoxShape.circle),
          child: Icon(isWished ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 20),
        ),
      );
    });
  }

  Widget _favCard(BuildContext context, Item item) {
    if (widget.isCampaign) return const SizedBox();
    return GetBuilder<FavouriteController>(builder: (wishList) {
      final bool isWished = wishList.wishItemIdList.contains(item.id);
      return InkWell(
        onTap: () => _toggleFav(isWished, item, wishList),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Container(
          height: 44, width: 44, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.25)),
          ),
          child: Icon(isWished ? Icons.favorite : Icons.favorite_border,
              color: isWished ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, size: 22),
        ),
      );
    });
  }

  void _toggleFav(bool isWished, Item item, FavouriteController wishList) {
    if (AuthHelper.isLoggedIn()) {
      isWished ? wishList.removeFromFavouriteList(item.id, false, getXSnackBar: true)
          : wishList.addToFavouriteList(item, null, false, getXSnackBar: true);
    } else {
      showCustomSnackBar('you_are_not_logged_in'.tr, getXSnackBar: true);
    }
  }

  Widget _stockBadge(BuildContext context, bool stockOut) {
    final Color color = stockOut ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall + 2, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      child: Text(stockOut ? 'out_of_stock'.tr : 'in_stock'.tr, style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
    );
  }

  /// Existing production add/update-to-cart behaviour (unchanged) — extracted from the old
  /// Add-to-Cart button so the footer and any caller share one implementation.
  Future<void> _addToCart(BuildContext context, Item item, ItemController itemController, CartController cartController, CartModel? cartModel, OnlineCart? cart, int? stock) async {
    final splash = Get.find<SplashController>();
    if (!(splash.configModel!.moduleConfig!.module!.stock!) || (stock ?? 0) > 0) {
      if (item.availableDateStarts != null) {
        Get.toNamed(RouteHelper.getCheckoutRoute('campaign'), arguments: CheckoutScreen(storeId: null, fromCart: false, cartList: [cartModel]));
      } else {
        if (cartController.existAnotherStoreItem(cartModel!.item!.storeId, splash.module == null ? splash.cacheModule!.id : splash.module!.id)) {
          Get.dialog(ConfirmationDialog(
            icon: Images.warning,
            title: 'are_you_sure_to_reset'.tr,
            description: splash.configModel!.moduleConfig!.module!.showRestaurantText! ? 'if_you_continue'.tr : 'if_you_continue_without_another_store'.tr,
            onYesPressed: () {
              Get.back();
              cartController.clearCartOnline().then((success) async {
                if (success) {
                  await cartController.addToCartOnline(cart!);
                  itemController.setExistInCart(item, null);
                  showCartSnackBar();
                }
              });
            },
          ), barrierDismissible: false);
        } else {
          if (itemController.cartIndex == -1) {
            await cartController.addToCartOnline(cart!).then((success) {
              if (success) {
                itemController.setExistInCart(item, null);
                showCartSnackBar();
              }
            });
          } else {
            await cartController.updateCartOnline(cart!).then((success) {
              if (success) showCartSnackBar();
            });
          }
        }
      }
    }
  }

  List<int?> _getSelectedAddonIds({required List<AddOn> addOnIdList }) {
    List<int?> listOfAddOnId = [];
    for (var addOn in addOnIdList) {
      listOfAddOnId.add(addOn.id);
    }
    return listOfAddOnId;
  }

  List<int?> _getSelectedAddonQtnList({required List<AddOn> addOnIdList }) {
    List<int?> listOfAddOnQty = [];
    for (var addOn in addOnIdList) {
      listOfAddOnQty.add(addOn.quantity);
    }
    return listOfAddOnQty;
  }

  double _getItemDetailsDiscountPrice({required CartModel cart}) {
    double discountedPrice = 0;

    double? discount = cart.item!.discount;
    String? discountType = cart.item!.discountType;
    String variationType = cart.variation != null && cart.variation!.isNotEmpty ? cart.variation![0].type! : '';

    if(cart.variation != null && cart.variation!.isNotEmpty){
      for (Variation variation in cart.item!.variations!) {
        if (variation.type == variationType) {
          discountedPrice = (PriceConverter.convertWithDiscount(variation.price!, discount, discountType)! * cart.quantity!);
          break;
        }
      }
    } else {
      discountedPrice = (PriceConverter.convertWithDiscount(cart.item!.price!, discount, discountType)! * cart.quantity!);
    }

    return discountedPrice;
  }

}

class QuantityButton extends StatelessWidget {
  final bool isIncrement;
  final int? quantity;
  final bool isCartWidget;
  final int? stock;
  final bool isExistInCart;
  final int cartIndex;
  final int? quantityLimit;
  final CartController cartController;
  const QuantityButton({super.key,
    required this.isIncrement,
    required this.quantity,
    required this.stock,
    required this.isExistInCart,
    required this.cartIndex,
    this.isCartWidget = false,
    this.quantityLimit,
    required this.cartController,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: cartController.isLoading ? null : () {
        if(isExistInCart) {
          if (!isIncrement && quantity! > 1) {
            Get.find<CartController>().setQuantity(false, cartIndex, stock, quantityLimit);
          } else if (isIncrement && quantity! > 0) {
            if(quantity! < stock! || !Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!) {
              Get.find<CartController>().setQuantity(true, cartIndex, stock, quantityLimit);
            }else {
              showCustomSnackBar('out_of_stock'.tr);
            }
          }
        } else {
          if (!isIncrement && quantity! > 1) {
            Get.find<ItemController>().setQuantity(false, stock, quantityLimit);
          } else if (isIncrement && quantity! > 0) {
            if(quantity! < stock! || !Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!) {
              Get.find<ItemController>().setQuantity(true, stock, quantityLimit);
            }else {
              showCustomSnackBar('out_of_stock'.tr);
            }
          }

        }
      },
      child: Container(
        height: 30, width: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (quantity! == 1 && !isIncrement) || cartController.isLoading ? Theme.of(context).disabledColor.withValues(alpha: 0.1) : Theme.of(context).primaryColor,
        ),
        child: Center(
          child: Icon(
            isIncrement ? Icons.add : Icons.remove,
            color: isIncrement ? Colors.white : quantity! == 1 ? Theme.of(context).disabledColor : Colors.white,
            size: isCartWidget ? 26 : 20,
          ),
        ),
      ),
    );
  }
}
