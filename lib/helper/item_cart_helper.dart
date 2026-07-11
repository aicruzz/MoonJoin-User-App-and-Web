import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';

/// Derived pricing/selection values for an item, computed once from the live
/// [Item] + [ItemController] state so the display and the add-to-cart action use
/// the exact same numbers. Extracted from `item_bottom_sheet.dart` so the food
/// full page and the bottom sheet share one source of truth (no duplication).
class ItemCartData {
  final double? startingPrice;
  final double? endingPrice;
  final double price; // base + variation price (single unit, pre-discount)
  final double priceWithDiscount;
  final double priceWithDiscountAndAddons;
  final double addonsCost;
  final double? initialDiscount;
  final double? discount;
  final String? discountType;
  final int? stock;
  final Variation? variation; // old-style single variation (non-food modules)
  final List<AddOn> addOnIdList;
  final List<AddOns> addOnsList;
  final bool isAvailable;

  ItemCartData({
    required this.startingPrice,
    required this.endingPrice,
    required this.price,
    required this.priceWithDiscount,
    required this.priceWithDiscountAndAddons,
    required this.addonsCost,
    required this.initialDiscount,
    required this.discount,
    required this.discountType,
    required this.stock,
    required this.variation,
    required this.addOnIdList,
    required this.addOnsList,
    required this.isAvailable,
  });
}

/// Shared item cart logic used by both `ItemBottomSheet` and the full-page
/// `FoodDetailsScreen`. This is the single implementation of the pricing,
/// variation/add-on resolution, required-variation validation, another-store
/// reset flow, campaign and cart add/update behaviour — do not duplicate it.
class ItemCartHelper {
  /// Recompute all derived pricing/selection values (mirror of the original
  /// `item_bottom_sheet.dart` build math, unchanged).
  static ItemCartData compute(Item item, ItemController itemController, bool newVariation) {
    double? startingPrice;
    double? endingPrice;
    if (item.choiceOptions!.isNotEmpty && item.foodVariations!.isEmpty && !newVariation) {
      List<double?> priceList = [];
      for (var variation in item.variations!) {
        priceList.add(variation.price);
      }
      priceList.sort((a, b) => a!.compareTo(b!));
      startingPrice = priceList[0];
      if (priceList[0]! < priceList[priceList.length - 1]!) {
        endingPrice = priceList[priceList.length - 1];
      }
    } else {
      startingPrice = item.price;
    }

    double? price = item.price;
    double variationPrice = 0;
    Variation? variation;
    double? initialDiscount = item.discount;
    double? discount = item.discount;
    String? discountType = item.discountType;
    int? stock = item.stock ?? 0;

    if (discountType == 'amount') {
      discount = discount! * itemController.quantity!;
    }

    if (newVariation) {
      for (int index = 0; index < item.foodVariations!.length; index++) {
        for (int i = 0; i < item.foodVariations![index].variationValues!.length; i++) {
          if (itemController.selectedVariations[index][i]!) {
            variationPrice += item.foodVariations![index].variationValues![i].optionPrice!;
          }
        }
      }
    } else {
      List<String> variationList = [];
      for (int index = 0; index < item.choiceOptions!.length; index++) {
        variationList.add(item.choiceOptions![index].options![itemController.variationIndex![index]].replaceAll(' ', ''));
      }
      String variationType = '';
      bool isFirst = true;
      for (var v in variationList) {
        if (isFirst) {
          variationType = '$variationType$v';
          isFirst = false;
        } else {
          variationType = '$variationType-$v';
        }
      }
      for (Variation variations in item.variations!) {
        if (variations.type == variationType) {
          price = variations.price;
          variation = variations;
          stock = variations.stock;
          break;
        }
      }
    }

    price = price! + variationPrice;
    double priceWithDiscount = PriceConverter.convertWithDiscount(price, discount, discountType)!;
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
    double priceWithDiscountAndAddons = priceWithDiscount + addonsCost;
    bool isAvailable = DateConverter.isAvailable(item.availableTimeStarts, item.availableTimeEnds);

    return ItemCartData(
      startingPrice: startingPrice, endingPrice: endingPrice, price: price,
      priceWithDiscount: priceWithDiscount, priceWithDiscountAndAddons: priceWithDiscountAndAddons,
      addonsCost: addonsCost, initialDiscount: initialDiscount, discount: discount, discountType: discountType,
      stock: stock, variation: variation, addOnIdList: addOnIdList, addOnsList: addOnsList, isAvailable: isAvailable,
    );
  }

  /// Validate required food variations, build the cart payload and add/update the
  /// cart (or route a campaign item to checkout). Identical behaviour to the
  /// original `item_bottom_sheet.dart` add-to-cart button. On success the caller's
  /// [onSuccess] runs (e.g. `Get.back()` for the sheet, a snackbar for the page).
  static Future<void> addOrUpdateCart({
    required BuildContext context,
    required Item item,
    required ItemController itemController,
    required ItemCartData data,
    required bool isCampaign,
    required bool newVariation,
    CartModel? cart,
    Function(CartModel)? onCartItemAdd,
    VoidCallback? onSuccess,
  }) async {
    final cartController = Get.find<CartController>();
    final splashController = Get.find<SplashController>();

    String? invalid;
    if (newVariation) {
      for (int index = 0; index < item.foodVariations!.length; index++) {
        if (!item.foodVariations![index].multiSelect! && item.foodVariations![index].required! &&
            !itemController.selectedVariations[index].contains(true)) {
          invalid = '${'choose_a_variation_from'.tr} ${item.foodVariations![index].name}';
          break;
        } else if (item.foodVariations![index].multiSelect! && (item.foodVariations![index].required! ||
            itemController.selectedVariations[index].contains(true)) && item.foodVariations![index].min! >
            itemController.selectedVariationLength(itemController.selectedVariations, index)) {
          invalid = '${'select_minimum'.tr} ${item.foodVariations![index].min} '
              '${'and_up_to'.tr} ${item.foodVariations![index].max} ${'options_from'.tr}'
              ' ${item.foodVariations![index].name} ${'variation'.tr}';
          break;
        }
      }
    }

    if (splashController.moduleList != null) {
      for (ModuleModel module in splashController.moduleList!) {
        if (module.id == item.moduleId) {
          splashController.setModule(module);
          break;
        }
      }
    }

    if (invalid != null) {
      showCustomSnackBar(invalid, getXSnackBar: true);
      return;
    }

    CartModel cartModel = CartModel(
      null, data.price, data.priceWithDiscountAndAddons, data.variation != null ? [data.variation!] : [],
      itemController.selectedVariations,
      (data.price - PriceConverter.convertWithDiscount(data.price, data.discount, data.discountType)!),
      itemController.quantity, data.addOnIdList, data.addOnsList, isCampaign, data.stock, item, item.quantityLimit,
    );

    if (onCartItemAdd != null) {
      onCartItemAdd(cartModel);
      Get.back();
      return;
    }

    List<OrderVariation> variations = _getSelectedVariations(
      isFoodVariation: splashController.getModuleConfig(item.moduleType).newVariation!,
      foodVariations: item.foodVariations!, selectedVariations: itemController.selectedVariations,
    );
    List<int?> listOfAddOnId = _getSelectedAddonIds(addOnIdList: data.addOnIdList);
    List<int?> listOfAddOnQty = _getSelectedAddonQtnList(addOnIdList: data.addOnIdList);

    OnlineCart onlineCart = OnlineCart(
      (cart != null || itemController.cartIndex != -1) ? cart?.id ?? cartController.cartList[itemController.cartIndex].id : null,
      isCampaign ? null : item.id, isCampaign ? item.id : null,
      data.priceWithDiscountAndAddons.toString(), '', data.variation != null ? [data.variation!] : null,
      splashController.getModuleConfig(item.moduleType).newVariation! ? variations : null,
      itemController.quantity, listOfAddOnId, data.addOnsList, listOfAddOnQty, 'Item',
    );

    if (isCampaign) {
      Get.toNamed(RouteHelper.getCheckoutRoute('campaign'), arguments: CheckoutScreen(
        storeId: null, fromCart: false, cartList: [cartModel],
      ));
    } else {
      if (cartController.existAnotherStoreItem(cartModel.item!.storeId, splashController.module != null
          ? splashController.module!.id : splashController.cacheModule!.id)) {
        Get.dialog(ConfirmationDialog(
          icon: Images.warning,
          title: 'are_you_sure_to_reset'.tr,
          description: splashController.configModel!.moduleConfig!.module!.showRestaurantText!
              ? 'if_you_continue'.tr : 'if_you_continue_without_another_store'.tr,
          onYesPressed: () {
            Get.back();
            cartController.clearCartOnline().then((success) async {
              if (success) {
                await cartController.addToCartOnline(onlineCart);
                if (onSuccess != null) onSuccess();
              }
            });
          },
        ), barrierDismissible: false);
      } else {
        if (cart != null || itemController.cartIndex != -1) {
          await cartController.updateCartOnline(onlineCart).then((success) {
            if (success && onSuccess != null) onSuccess();
          });
        } else {
          await cartController.addToCartOnline(onlineCart).then((success) {
            if (success && onSuccess != null) onSuccess();
          });
        }
      }
    }
  }

  static List<OrderVariation> _getSelectedVariations({required bool isFoodVariation, required List<FoodVariation>? foodVariations, required List<List<bool?>> selectedVariations}) {
    List<OrderVariation> variations = [];
    if (isFoodVariation) {
      for (int i = 0; i < foodVariations!.length; i++) {
        if (selectedVariations[i].contains(true)) {
          variations.add(OrderVariation(name: foodVariations[i].name, values: OrderVariationValue(label: [])));
          for (int j = 0; j < foodVariations[i].variationValues!.length; j++) {
            if (selectedVariations[i][j]!) {
              variations[variations.length - 1].values!.label!.add(foodVariations[i].variationValues![j].level);
            }
          }
        }
      }
    }
    return variations;
  }

  static List<int?> _getSelectedAddonIds({required List<AddOn> addOnIdList}) {
    List<int?> listOfAddOnId = [];
    for (var addOn in addOnIdList) {
      listOfAddOnId.add(addOn.id);
    }
    return listOfAddOnId;
  }

  static List<int?> _getSelectedAddonQtnList({required List<AddOn> addOnIdList}) {
    List<int?> listOfAddOnQty = [];
    for (var addOn in addOnIdList) {
      listOfAddOnQty.add(addOn.quantity);
    }
    return listOfAddOnQty;
  }
}
