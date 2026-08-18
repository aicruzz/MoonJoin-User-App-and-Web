import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/models/error_response.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/order/domain/models/order_details_model.dart';
import 'package:moonjoin/features/order/domain/models/order_model.dart';
import 'package:moonjoin/features/order/controllers/order_controller.dart';
import 'package:moonjoin/features/order/domain/services/order_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/cart/domain/models/cart_model.dart' as cart;
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/util/app_constants.dart';

class OrderEditController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;
  OrderEditController({required this.orderServiceInterface});

  OrderModel? _orderModel;
  OrderModel? get orderModel => _orderModel;

  List<OrderDetailsModel> _editableItems = [];
  List<OrderDetailsModel> get editableItems => _editableItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  bool _isStoreItemsLoading = false;
  bool get isStoreItemsLoading => _isStoreItemsLoading;

  List<Item> _storeItems = [];
  List<Item> get storeItems => _storeItems;

  List<Item> _storeSearchItems = [];
  List<Item> get storeSearchItems => _storeSearchItems;

  bool _isStoreSearchLoading = false;
  bool get isStoreSearchLoading => _isStoreSearchLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _orderNote;
  String? get orderNote => _orderNote;

  // ── Check if order is editable ────────────────────────────────────────────
  static bool canEdit(OrderModel order) {
    // A pending order is editable while it is still unpaid — OR the vendor has
    // requested a customer edit (`customer_edit_requested`), the authoritative
    // negotiation signal. The vendor-request path applies to both pending AND
    // confirmed orders (the live backend authorizes customer update for
    // order_status in [pending, confirmed] while unclaimed); confirmed orders are
    // editable ONLY when the vendor requested it — never blanket-confirmed, never
    // processing. The customer's own checkout note (`unavailable_item_note`) must
    // NOT grant edit access.
    return (order.orderStatus == 'pending' && order.paymentStatus == 'unpaid')
        || ((order.orderStatus == 'pending' || order.orderStatus == 'confirmed')
            && order.customerEditRequested == true);
  }

  // ── Update-failure messaging ──────────────────────────────────────────────
  // Pure/testable. The backend financial guard returns HTTP 403 with an error
  // whose `code == 'wallet'` when the edited total exceeds the customer's wallet
  // balance. Surface a clear, specific message for that case ONLY; every other
  // failure keeps the existing generic wording. Never widens all 403s.
  static bool isWalletInsufficient(Response response) {
    if (response.statusCode != 403) return false;
    try {
      final ErrorResponse error = ErrorResponse.fromJson(response.body);
      return error.errors?.any((e) => (e.code ?? '').toLowerCase() == 'wallet') ?? false;
    } catch (_) {
      return false;
    }
  }

  static String updateFailureMessage(Response response) {
    if (isWalletInsufficient(response)) {
      return 'Insufficient wallet balance. Your wallet balance is not enough to cover the updated order total.';
    }
    return 'Could not update your order. Please try again.';
  }

  int? _moduleId;

  void loadOrder(OrderModel order, List<OrderDetailsModel> details,
      {int? storeId, int? moduleId}) {
    _orderModel = order;
    _moduleId = moduleId;
    _orderNote = order.orderNote;
    // Deep-copy each already-parsed detail so edits don't mutate the original.
    // Guard the round-trip: a re-parse must never crash the Edit screen (some
    // order/track payloads carry fields that trip the model's type parsing).
    _editableItems = details.map((d) {
      try {
        return OrderDetailsModel.fromJson(d.toJson());
      } catch (_) {
        return d;
      }
    }).toList();
    _isInitializing = false;
    update();
    final resolvedStoreId = storeId ?? order.store?.id;
    if (resolvedStoreId != null) {
      loadStoreItems(resolvedStoreId);
    }
  }

  void _applyModuleHeader() {
    if (_moduleId != null) {
      Get.find<ApiClient>().getHeader()[AppConstants.moduleId] = '$_moduleId';
    }
  }

  // ── Load available items from the same store ──────────────────────────────
  Future<void> loadStoreItems(int storeId) async {
    _isStoreItemsLoading = true;
    _storeItems = [];
    update();

    try {
      _applyModuleHeader();
      final storeController = Get.find<StoreController>();
      ItemModel? result = await storeController.storeServiceInterface
          .getStoreItemList(storeID: storeId, offset: 1, type: 'all');

      if (result != null) {
        final existingItemIds = _editableItems.map((e) => e.itemId).toSet();
        _storeItems = result.items
                ?.where((i) => !existingItemIds.contains(i.id))
                .toList() ??
            [];
      }
    } catch (e) {
      debugPrint('Error loading store items: $e');
      _storeItems = [];
    }

    _isStoreItemsLoading = false;
    update();
  }

  // ── Search Store Items ──────────────────────────────────────────────────
  Future<void> searchStoreItems(String query, int? storeId) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _storeSearchItems = [];
      update();
      return;
    }
    if (storeId == null) return;

    _isStoreSearchLoading = true;
    update();

    try {
      _applyModuleHeader();
      final storeController = Get.find<StoreController>();
      ItemModel? searchResult =
          await storeController.storeServiceInterface.getStoreSearchItemList(
        query, storeId.toString(), 1, 'all', null,
      );

      if (searchResult != null) {
        final existingItemIds = _editableItems.map((e) => e.itemId).toSet();
        _storeSearchItems = searchResult.items
                ?.where((i) => !existingItemIds.contains(i.id))
                .toList() ??
            [];
      }
    } catch (e) {
      _storeSearchItems = [];
    }

    _isStoreSearchLoading = false;
    update();
  }

  void clearSearch() {
    _searchQuery = '';
    _storeSearchItems = [];
    update();
  }

  void addCartItem(cart.CartModel cartModel) {
    if (cartModel.item == null) return;

    final item = cartModel.item!;

    double totalAddOnPrice = 0;
    List<AddOn> addons = [];
    if (cartModel.addOns != null) {
      for (int i = 0; i < cartModel.addOns!.length; i++) {
        final addonRef = cartModel.addOns![i];
        final addonId =
            cartModel.addOnIds?.firstWhereOrNull((a) => a.id == addonRef.id);
        final qty = addonId?.quantity ?? 1;

        addons.add(AddOn(
          id: addonRef.id,
          name: addonRef.name,
          price: addonRef.price,
          quantity: qty,
        ));
        totalAddOnPrice += (addonRef.price ?? 0) * qty;
      }
    }

    final existing =
        _editableItems.indexWhere((e) => e.itemId == item.id);

    if (existing != -1 &&
        _isSameVariation(_editableItems[existing], cartModel)) {
      int newQty =
          (_editableItems[existing].quantity ?? 0) + (cartModel.quantity ?? 1);
      _editableItems[existing].quantity = newQty;
      double singleItemAddOnPrice = totalAddOnPrice;
      _editableItems[existing].totalAddOnPrice =
          singleItemAddOnPrice * newQty;
    } else {
      _editableItems.add(OrderDetailsModel(
        itemId: item.id,
        orderId: _orderModel?.id,
        price: cartModel.price,
        quantity: cartModel.quantity,
        variation: cartModel.variation,
        foodVariation:
            _convertFoodVariations(item, cartModel.foodVariations ?? []),
        addOns: addons,
        totalAddOnPrice: totalAddOnPrice * (cartModel.quantity ?? 1),
        itemDetails: item,
        imageFullUrl: item.imageFullUrl,
      ));
      _storeSearchItems.removeWhere((i) => i.id == item.id);
    }
    update();
  }

  /// Replace the editable item at [index] with the edited selection returned from
  /// the Food Product Details page (Edit Mode). Reuses the same OrderDetailsModel
  /// construction as [addCartItem] — only that one item changes; the order is not
  /// submitted until the user presses Update Cart.
  void updateEditableItem(int index, cart.CartModel cartModel) {
    if (index < 0 || index >= _editableItems.length || cartModel.item == null) return;
    final item = cartModel.item!;

    double totalAddOnPrice = 0;
    List<AddOn> addons = [];
    if (cartModel.addOns != null) {
      for (int i = 0; i < cartModel.addOns!.length; i++) {
        final addonRef = cartModel.addOns![i];
        final addonId = cartModel.addOnIds?.firstWhereOrNull((a) => a.id == addonRef.id);
        final qty = addonId?.quantity ?? 1;
        addons.add(AddOn(id: addonRef.id, name: addonRef.name, price: addonRef.price, quantity: qty));
        totalAddOnPrice += (addonRef.price ?? 0) * qty;
      }
    }

    _editableItems[index] = OrderDetailsModel(
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
    );
    update();
  }

  List<FoodVariation> _convertFoodVariations(
      Item item, List<List<bool?>> selectedVariations) {
    List<FoodVariation> variations = [];
    if (item.foodVariations != null && selectedVariations.isNotEmpty) {
      for (int i = 0; i < item.foodVariations!.length; i++) {
        if (i < selectedVariations.length &&
            selectedVariations[i].contains(true)) {
          FoodVariation original = item.foodVariations![i];
          List<VariationValue> selectedValues = [];
          for (int j = 0; j < original.variationValues!.length; j++) {
            if (j < selectedVariations[i].length &&
                selectedVariations[i][j]!) {
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
    return true;
  }

  void addItemToOrder(Item item) {
    final existing = _editableItems.indexWhere((e) => e.itemId == item.id);
    if (existing != -1) {
      _editableItems[existing].quantity =
          (_editableItems[existing].quantity ?? 1) + 1;
    } else {
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
      _storeItems.removeWhere((i) => i.id == item.id);
    }
    update();

    Get.snackbar(
      'Item Added',
      '${item.name} added to your order.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void increaseQuantity(int itemId) {
    final index = _editableItems.indexWhere((e) => e.itemId == itemId);
    if (index != -1) {
      int oldQty = _editableItems[index].quantity ?? 1;
      double currentAddOnTotal = _editableItems[index].totalAddOnPrice ?? 0;
      double unitAddOnPrice = oldQty > 0 ? currentAddOnTotal / oldQty : 0;

      int newQty = oldQty + 1;
      _editableItems[index].quantity = newQty;
      _editableItems[index].totalAddOnPrice = unitAddOnPrice * newQty;
      update();
    }
  }

  void decreaseQuantity(int itemId) {
    final index = _editableItems.indexWhere((e) => e.itemId == itemId);
    if (index != -1) {
      int oldQty = _editableItems[index].quantity ?? 1;
      if (oldQty <= 1) {
        removeItem(itemId);
      } else {
        double currentAddOnTotal = _editableItems[index].totalAddOnPrice ?? 0;
        double unitAddOnPrice = oldQty > 0 ? currentAddOnTotal / oldQty : 0;

        int newQty = oldQty - 1;
        _editableItems[index].quantity = newQty;
        _editableItems[index].totalAddOnPrice = unitAddOnPrice * newQty;
        update();
      }
    }
  }

  void removeItem(int itemId) {
    final removed =
        _editableItems.firstWhereOrNull((e) => e.itemId == itemId);
    _editableItems.removeWhere((e) => e.itemId == itemId);

    if (removed?.itemDetails != null) {
      _storeItems.insert(0, removed!.itemDetails!);
      _storeSearchItems.removeWhere((i) => i.id == itemId);
    }
    update();
  }

  void updateOrderNote(String note) {
    _orderNote = note;
  }

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

  // ── Submit edited order ───────────────────────────────────────────────────
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
      final List<Map<String, dynamic>> cartPayload =
          _editableItems.map((item) {
        final resolvedAddOns = (item.addOns ?? []).map((a) {
          final id = (a.id != null && a.id != 0)
              ? a.id!
              : item.itemDetails?.addOns
                  ?.firstWhereOrNull((ad) => ad.name == a.name)
                  ?.id;
          return id != null ? (id: id, qty: a.quantity ?? 1) : null;
        }).whereType<({int id, int qty})>().toList();
        final addOnIds = resolvedAddOns.map((e) => e.id).toList();
        final addOnQtys = resolvedAddOns.map((e) => e.qty).toList();

        final payload = <String, dynamic>{
          if (item.id != null) 'id': item.id,
          'item_id': item.itemId,
          'item_campaign_id': item.itemCampaignId,
          'quantity': item.quantity ?? 1,
          'price': item.price ?? 0,
          'total_add_on_price': item.totalAddOnPrice ?? 0,
          'tax_amount': item.taxAmount ?? 0,
          'discount_on_item': ((item.discountOnItem ?? 0) / (item.quantity ?? 1)),
          'variant': item.variant == 'null' ? '' : (item.variant ?? ''),
          'variation': (item.foodVariation != null && item.foodVariation!.isNotEmpty)
              ? item.foodVariation!
                  .map((v) => {
                        'name': v.name,
                        'values': {
                          'label': v.variationValues
                                  ?.map((vv) => vv.level)
                                  .toList() ??
                              [],
                        },
                      })
                  .toList()
              : item.variation?.map((v) => v.toJson()).toList() ?? [],
          'add_on_ids': addOnIds,
          'add_on_qtys': addOnQtys,
        };

        debugPrint(
            '  📦 [${item.id}|${item.itemId}] ${item.itemDetails?.name}'
            ' | qty=${payload['quantity']}'
            ' | price=${payload['price']}'
            ' | addOnIds=$addOnIds'
            ' | addOnQtys=$addOnQtys'
            ' | totalAddOn=${payload['total_add_on_price']}');

        if (addOnIds.any((id) => id == 0)) {
          debugPrint('  ⚠️  Unresolved add-on ID for item ${item.itemId}');
        }

        return payload;
      }).toList();

      debugPrint('=== SUBMITTING EDITED ORDER #${_orderModel!.id} ===');
      debugPrint('  Total items : ${cartPayload.length}');
      debugPrint('  Order note  : $_orderNote');
      for (final c in cartPayload) {
        debugPrint('  → $c');
      }
      debugPrint('================================================');

      final Response response = await orderServiceInterface.updateOrder(
        orderId: _orderModel!.id!,
        cart: cartPayload,
        orderNote: _orderNote,
      );
      final bool success = response.statusCode == 200;

      _isLoading = false;
      update();

      if (success) {
        debugPrint('✅ Order #${_orderModel!.id} updated successfully.');
        // Refresh the running orders so the Home "Review Items" notification
        // re-evaluates automatically (it hides once no order still carries an
        // unavailable-item note). Reuses the existing endpoint — no new API.
        if (Get.isRegistered<OrderController>()) {
          Get.find<OrderController>().getRunningOrders(1, fromDashboard: true);
        }
        Get.back(result: true);
        Get.snackbar(
          'Order Updated',
          'Your order has been updated successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        debugPrint('❌ Order update failed for #${_orderModel!.id}.');
        Get.snackbar(
          'Update Failed',
          updateFailureMessage(response),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e, st) {
      _isLoading = false;
      update();
      debugPrint('💥 submitEditedOrder exception: $e\n$st');
      Get.snackbar(
        'Error',
        'Failed to update order. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}