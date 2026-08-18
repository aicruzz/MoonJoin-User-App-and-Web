import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';

class CartCountView extends StatelessWidget {
  final Item item;
  final Widget? child;
  final int? index;
  const CartCountView({super.key, required this.item, this.child, this.index = -1});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      int cartQty = cartController.cartQuantity(item.id!);
      int cartIndex = cartController.isExistInCart(item.id, cartController.cartVariant(item.id!), false, null);
      // At quantity 1 the minus becomes a delete affordance, matching Your Cart.
      bool showRemoveIcon = cartIndex != -1 && (cartController.cartList[cartIndex].quantity ?? 1) <= 1;
      return cartQty != 0 ? Center(
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            InkWell(
              // Always active so rapid taps keep decrementing instantly and the
              // tap is always absorbed here (never falls through to the card /
              // opens product details) even while a background sync is in flight.
              onTap: () {
                if (cartController.cartList[cartIndex].quantity! > 1) {
                  cartController.setDirectlyAddToCartIndex(index);
                  cartController.setQuantity(false, cartIndex, cartController.cartList[cartIndex].stock, cartController.cartList[cartIndex].item!.quantityLimit);
                }else {
                  cartController.removeFromCart(cartIndex);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: showRemoveIcon ? Theme.of(context).colorScheme.error.withValues(alpha: 0.08) : Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: showRemoveIcon
                    ? Image.asset(Images.delete, height: 16, color: Theme.of(context).colorScheme.error)
                    : const Icon(Icons.remove, size: 16),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              // Always show the live quantity (never a spinner) so +/- feels
              // instant — the local quantity updates immediately and the online
              // sync happens in the background (matches removeFromCart's optimistic
              // behaviour). Buttons stay briefly disabled during sync (below).
              child: Text(cartQty.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
            ),

            InkWell(
              // Always active so rapid taps keep incrementing instantly and the
              // tap is always absorbed here (never falls through to the card /
              // opens product details) even while a background sync is in flight.
              onTap: () {
                cartController.setDirectlyAddToCartIndex(index);
                cartController.setQuantity(true, cartIndex, cartController.cartList[cartIndex].stock, cartController.cartList[cartIndex].quantityLimit);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  border: Border.all(color: Theme.of(context).cardColor),
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Icon(
                  Icons.add, size: 16, color: Theme.of(context).cardColor,
                ),
              ),
            ),
          ]),
        ),
      ) : InkWell(
        onTap: () {
          Get.find<ItemController>().itemDirectlyAddToCart(item, context);
        },
        child: child ?? Container(
          height: 25, width: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: Theme.of(context).cardColor,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          child: Icon(Icons.add, size: 20, color: Theme.of(context).primaryColor),
        ),
      );
    });
  }
}
