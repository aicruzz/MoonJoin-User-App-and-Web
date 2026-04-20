import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/domain/services/order_service_interface.dart';

class OrderEditController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;
  OrderEditController({required this.orderServiceInterface});

  OrderModel? _orderModel;
  OrderModel? get orderModel => _orderModel;

  List<OrderDetailsModel> _editableItems = [];
  List<OrderDetailsModel> get editableItems => _editableItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _orderNote;
  String? get orderNote => _orderNote;

  // ── Check if order is editable ────────────────────────────────────────────
  static bool canEdit(OrderModel order) {
    return order.paymentStatus == 'unpaid' && order.orderStatus == 'pending';
  }

  // ── Load order into controller ────────────────────────────────────────────
  void loadOrder(OrderModel order, List<OrderDetailsModel> details) {
    _orderModel = order;
    _orderNote = order.orderNote;
    _editableItems = details
        .map((d) => OrderDetailsModel.fromJson(d.toJson()))
        .toList();
    update();
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
    _editableItems.removeWhere((e) => e.id == itemId);
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
      //   cart: cartItems,
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