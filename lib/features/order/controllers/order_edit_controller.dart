import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart' as cart;
import 'package:sixam_mart/features/item/controllers/item_controller.dart';

class OrderEditController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;
  OrderEditController({required this.orderServiceInterface});

  OrderModel? _orderModel;
  OrderModel? get orderModel => _orderModel;

  List<OrderDetailsModel> _editableItems = [];
  List<OrderDetailsModel> get editableItems => _editableItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isStoreItemsLoading = false;
  bool get isStoreItemsLoading => _isStoreItemsLoading;

  List<Item> _storeItems = [];
  List<Item> get storeItems => _storeItems;

  String? _orderNote;
  String? get orderNote => _orderNote;

  // ── Check if order is editable ────────────────────────────────────────────
  static bool canEdit(OrderModel order) {
    return order.paymentStatus == 'unpaid' && order.orderStatus == 'pending';
  }

  // ── Load order into controller ────────────────────────────────────────────
  void loadOrder(OrderModel order, List<OrderDetailsModel> details, {int? storeId}) {
    _orderModel = order;
    _orderNote = order.orderNote;
    _editableItems = details
        .map((d) => OrderDetailsModel.fromJson(d.toJson()))
        .toList();
    update();

    // Auto-load store items — prefer explicit storeId, fall back to order.store?.id
    final resolvedStoreId = storeId ?? order.store?.id;
    if (resolvedStoreId != null) {
      loadStoreItems(resolvedStoreId);
    }
  }

  // ── Load available items from the same store ──────────────────────────────
  Future<void> loadStoreItems(int storeId) async {
    _isStoreItemsLoading = true;
    _storeItems = [];
    update();

    try {
      // Using the recommended items endpoint as requested
      // We still filter by storeId to ensure items are compatible with the order
      await Get.find<ItemController>().getRecommendedItemList(true, 'all', false);
      final items = Get.find<ItemController>().recommendedItemList ?? [];
      
      // Filter out items already in the order and ensure they belong to the correct store
      final existingItemIds = _editableItems.map((e) => e.itemId).toSet();
      _storeItems = items.where((i) => 
        i.storeId == storeId && !existingItemIds.contains(i.id)
      ).toList();
      
      // If recommended list is empty for this store, fallback to store's items
      if (_storeItems.isEmpty) {
        await Get.find<StoreController>().getStoreItemList(storeId, 1, 'all', false);
        final storeItems = Get.find<StoreController>().storeItemModel?.items ?? [];
        _storeItems = storeItems.where((i) => !existingItemIds.contains(i.id)).toList();
      }
    } catch (e) {
      debugPrint('Error loading items for order edit: $e');
      _storeItems = [];
    }

    _isStoreItemsLoading = false;
    update();
  }

  void addCartItem(cart.CartModel cartModel) {
    if (cartModel.item == null) return;
    
    final item = cartModel.item!;
    
    // Calculate total add-on price for this cart item
    double totalAddOnPrice = 0;
    List<AddOn> addons = [];
    if (cartModel.addOns != null) {
      for (int i = 0; i < cartModel.addOns!.length; i++) {
        final addonRef = cartModel.addOns![i];
        final addonId = cartModel.addOnIds?.firstWhereOrNull((a) => a.id == addonRef.id);
        final qty = addonId?.quantity ?? 1;
        
        addons.add(AddOn(
          name: addonRef.name,
          price: addonRef.price,
          quantity: qty,
        ));
        totalAddOnPrice += (addonRef.price ?? 0) * qty;
      }
    }

    final existing = _editableItems.indexWhere((e) => e.itemId == item.id);

    if (existing != -1 && _isSameVariation(_editableItems[existing], cartModel)) {
      _editableItems[existing].quantity = (_editableItems[existing].quantity ?? 0) + (cartModel.quantity ?? 1);
    } else {
      _editableItems.add(OrderDetailsModel(
        itemId: item.id,
        orderId: _orderModel?.id,
        price: cartModel.price,
        quantity: cartModel.quantity,
        variation: cartModel.variation,
        foodVariation: _convertFoodVariations(item, cartModel.foodVariations ?? []),
        addOns: addons,
        totalAddOnPrice: totalAddOnPrice * (cartModel.quantity ?? 1),
        itemDetails: item,
        imageFullUrl: item.imageFullUrl,
      ));
      
      _storeItems.removeWhere((i) => i.id == item.id);
    }
    update();
  }

  List<FoodVariation> _convertFoodVariations(Item item, List<List<bool?>> selectedVariations) {
    List<FoodVariation> variations = [];
    if (item.foodVariations != null && selectedVariations.isNotEmpty) {
      for (int i = 0; i < item.foodVariations!.length; i++) {
        if (i < selectedVariations.length && selectedVariations[i].contains(true)) {
          FoodVariation original = item.foodVariations![i];
          List<VariationValue> selectedValues = [];
          for (int j = 0; j < original.variationValues!.length; j++) {
            if (j < selectedVariations[i].length && selectedVariations[i][j]!) {
              selectedValues.add(original.variationValues![j]);
            }
          }
          variations.add(FoodVariation(
            name: original.name,
            multiSelect: original.multiSelect,
            min: original.min,
            max: original.max,
            required: original.required,
            variationValues: selectedValues,
          ));
        }
      }
    }
    return variations;
  }

  bool _isSameVariation(OrderDetailsModel existing, cart.CartModel cart) {
    // Simple check: for now, if it's the same itemId, we treat as same or add new if you want separate rows
    // Standard SixamMart merges if variations match exactly. 
    // Implementing a simple merge for now to keep the UI clean.
    return true; 
  }

  // ── Add item from store to order ──────────────────────────────────────────
  void addItemToOrder(Item item) {
    // Check if already in editable items
    final existing = _editableItems.indexWhere((e) => e.itemId == item.id);
    if (existing != -1) {
      // Just increase quantity
      _editableItems[existing].quantity = (_editableItems[existing].quantity ?? 1) + 1;
    } else {
      // Add as new OrderDetailsModel
      _editableItems.add(OrderDetailsModel(
        itemId: item.id,
        orderId: _orderModel?.id,
        price: item.price,
        quantity: 1,
        variation: [],
        foodVariation: [],
        addOns: [],
        discountOnItem: item.discount,
        discountType: item.discountType,
        totalAddOnPrice: 0,
        imageFullUrl: item.imageFullUrl,
        itemDetails: item,
      ));
      // Remove from available store items
      _storeItems.removeWhere((i) => i.id == item.id);
    }
    update();

    Get.snackbar(
      'Item Added',
      '${item.name} added to your order.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // ── Quantity ──────────────────────────────────────────────────────────────
  void increaseQuantity(int itemId) {
    final index = _editableItems.indexWhere((e) => e.itemId == itemId);
    if (index != -1) {
      _editableItems[index].quantity = (_editableItems[index].quantity ?? 1) + 1;
      update();
    }
  }

  void decreaseQuantity(int itemId) {
    final index = _editableItems.indexWhere((e) => e.itemId == itemId);
    if (index != -1) {
      if ((_editableItems[index].quantity ?? 1) <= 1) {
        removeItem(itemId);
      } else {
        _editableItems[index].quantity = _editableItems[index].quantity! - 1;
        update();
      }
    }
  }

  // ── Remove item ───────────────────────────────────────────────────────────
  void removeItem(int itemId) {
    final removed = _editableItems.firstWhereOrNull((e) => e.itemId == itemId);
    _editableItems.removeWhere((e) => e.itemId == itemId);
    // Add back to store items list if it came from there
    if (removed?.itemDetails != null) {
      _storeItems.insert(0, removed!.itemDetails!);
    }
    update();
  }

  // ── Order note ────────────────────────────────────────────────────────────
  void updateOrderNote(String note) {
    _orderNote = note;
  }

  // ── Totals ────────────────────────────────────────────────────────────────
  double get itemsSubtotal {
    return _editableItems.fold(
        0.0, (sum, item) => sum + ((item.price ?? 0) * (item.quantity ?? 1)));
  }

  double get orderTotal {
    final tax = _orderModel?.totalTaxAmount ?? 0;
    final delivery = _orderModel?.deliveryCharge ?? 0;
    final coupon = _orderModel?.couponDiscountAmount ?? 0;
    final store = _orderModel?.storeDiscountAmount ?? 0;
    final addons = _editableItems.fold(
        0.0, (sum, item) => sum + (item.totalAddOnPrice ?? 0));
    return itemsSubtotal + addons + tax + delivery - coupon - store;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> submitEditedOrder() async {
    if (_editableItems.isEmpty) {
      Get.snackbar(
        'Empty Order',
        'You cannot submit an empty order.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    _isLoading = true;
    update();

    try {
      // Build cart payload from editable items
      final List<Map<String, dynamic>> cart = _editableItems.map((item) {
        return {
          'item_id': item.itemId,
          'quantity': item.quantity ?? 1,
          'price': item.price ?? 0,
          'variant': item.variant ?? '',
          'variation': item.foodVariation?.map((v) {
            return {
              'name': v.name,
              'values': {
                'label': v.variationValues?.map((vv) => vv.level).toList() ?? [],
              },
            };
          }).toList() ?? [],
          'add_on_ids': item.addOns?.map((a) {
            // We need to find the ID from itemDetails if available, 
            // because OrderDetailsModel.AddOn only stores name/price/qty
            final addonDetail = item.itemDetails?.addOns?.firstWhereOrNull((ad) => ad.name == a.name);
            return addonDetail?.id ?? 0;
          }).toList() ?? [],
          'add_on_qtys': item.addOns?.map((a) => a.quantity ?? 1).toList() ?? [],
        };
      }).toList();

      final bool success = await orderServiceInterface.updateOrder(
        orderId: _orderModel!.id!,
        cart: cart,
        orderNote: _orderNote,
      );

      _isLoading = false;
      update();

      if (success) {
        Get.back(result: true);
        Get.snackbar(
          'Order Updated',
          'Your order has been updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Update Failed',
          'Could not update your order. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      _isLoading = false;
      update();
      Get.snackbar(
        'Error',
        'Failed to update order. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}