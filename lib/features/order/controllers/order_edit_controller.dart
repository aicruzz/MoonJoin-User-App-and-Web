import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';

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
      await Get.find<StoreController>().getStoreItemList(storeId, 1, 'all', false);
      final items = Get.find<StoreController>().storeItemModel?.items ?? [];
      // Filter out items already in the order
      final existingItemIds = _editableItems.map((e) => e.itemId).toSet();
      _storeItems = items.where((i) => !existingItemIds.contains(i.id)).toList();
    } catch (_) {
      _storeItems = [];
    }

    _isStoreItemsLoading = false;
    update();
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
    final index = _editableItems.indexWhere((e) => e.id == itemId);
    if (index != -1) {
      _editableItems[index].quantity = (_editableItems[index].quantity ?? 1) + 1;
      update();
    }
  }

  void decreaseQuantity(int itemId) {
    final index = _editableItems.indexWhere((e) => e.id == itemId);
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
    final removed = _editableItems.firstWhereOrNull((e) => e.id == itemId);
    _editableItems.removeWhere((e) => e.id == itemId);
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
      // TODO: Replace with your actual API call e.g:
      // await orderServiceInterface.updateOrder(
      //   orderId: _orderModel!.id.toString(),
      //   cart: _editableItems.map((item) => {
      //     'item_id': item.itemId,
      //     'quantity': item.quantity,
      //     'price': item.price,
      //     'variant': item.variant,
      //     'variation': item.foodVariation?.map((v) => v.toJson()).toList() ?? [],
      //     'add_ons': item.addOns?.map((a) => a.toJson()).toList() ?? [],
      //   }).toList(),
      //   orderNote: _orderNote,
      // );
      await Future.delayed(const Duration(milliseconds: 800));

      _isLoading = false;
      update();
      Get.back(result: true);
      Get.snackbar(
        'Order Updated',
        'Your order has been updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
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