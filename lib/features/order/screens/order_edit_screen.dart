import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/screens/food_details_screen.dart';
import 'package:sixam_mart/features/order/controllers/order_edit_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart' hide AddOn;
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';



class OrderEditScreen extends StatefulWidget {
  final OrderModel orderModel;
  final List<OrderDetailsModel> orderDetails;
  final int? storeId;
  final int? moduleId; 

  const OrderEditScreen({
    super.key,
    required this.orderModel,
    required this.orderDetails,
    this.storeId,
    this.moduleId,
  });

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  late final TextEditingController _noteController;

    @override
    void initState() {
      super.initState();
      _noteController = TextEditingController(text: widget.orderModel.orderNote ?? '');
      WidgetsBinding.instance.addPostFrameCallback((_) {

        final moduleId = widget.orderModel.store?.moduleId
            ?? widget.moduleId
            ?? Get.find<SplashController>().module?.id;

        // debugPrint('=== ORDER EDIT DEBUG ===');
        // debugPrint('Store id: ${widget.orderModel.store?.id}');
        // debugPrint('Store moduleId: ${widget.orderModel.store?.moduleId}');
        // debugPrint('Resolved moduleId: $moduleId');
        // debugPrint('========================');

        Get.find<OrderEditController>().loadOrder(
          widget.orderModel,
          widget.orderDetails,
          storeId: widget.storeId,
          moduleId: moduleId, 
        );
      });
    }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  static const Color _bodyBg = Color(0xFFF6F8F0);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderEditController>(
      builder: (controller) {
        final Color bodyColor = Theme.of(context).brightness == Brightness.light ? _bodyBg : Theme.of(context).scaffoldBackgroundColor;
        return Scaffold(
          backgroundColor: bodyColor,
          body: controller.isInitializing
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  _buildHeader(context),
                  Expanded(
                    child: controller.editableItems.isEmpty && !controller.isLoading
                        ? _buildEmptyState(context, controller)
                        : ListView(
                            padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                            children: [
                              _buildShortageBanner(context),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
                                child: Text('${'unavailable_items'.tr} (${controller.editableItems.length})',
                                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).colorScheme.error)),
                              ),

                              ...controller.editableItems.asMap().entries.map((entry) => Padding(
                                    padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                                    child: _OrderItemCard(item: entry.value, controller: controller, onEdit: () => _openEdit(context, controller, entry.value, entry.key)),
                                  )),

                              _buildAddMoreCard(context, controller),
                              _buildChatCard(context, controller),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                                child: _buildOrderNoteField(context, controller),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                child: _buildOrderSummary(context, controller),
                              ),
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                            ],
                          ),
                  ),
                  if (controller.editableItems.isNotEmpty || controller.isLoading) _buildBottomBar(context, controller),
                ]),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: InkWell(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('edit_unavailable_items'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge)),
              const SizedBox(height: 4),
              Text('review_items_below_choose'.tr, style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall, height: 1.35)),
            ])),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Container(
              height: 56, width: 56, alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: const Icon(Icons.production_quantity_limits, color: Colors.white, size: 28),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildShortageBanner(BuildContext context) {
    final Color error = Theme.of(context).colorScheme.error;
    // Show the vendor's actual order note when present; else the default text.
    final String? vendorNote = widget.orderModel.unavailableItemNote?.trim();
    final String message = (vendorNote != null && vendorNote.isNotEmpty) ? vendorNote : 'items_below_currently_unavailable'.tr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(color: error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_rounded, color: error, size: 28),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('vendor_shortage'.tr, style: robotoBold.copyWith(color: error, fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: 2),
            Text(message, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, height: 1.35)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildAddMoreCard(BuildContext context, OrderEditController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        child: Row(children: [
          Container(
            height: 46, width: 46, alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.add_shopping_cart, color: Theme.of(context).primaryColor, size: 22),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('add_more_items'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: 2),
            Text('you_can_add_new_items_to_complete_your_order'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
          ])),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          InkWell(
            onTap: () => _showAddItemsSheet(context, controller),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('add_items'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
                const SizedBox(width: 4),
                Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 18),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // Reuse the existing order chat flow (vendor). Chat belongs to a placed order.
  void _openVendorChat() {
    final order = widget.orderModel;
    if (order.store?.vendorId == null) return;
    Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: NotificationBodyModel(orderId: order.id, restaurantId: order.store!.vendorId),
      user: User(id: order.store!.vendorId, fName: order.store!.name, lName: '', imageFullUrl: order.store!.logoFullUrl),
    ));
  }

  /// Open the frozen Food Product Details page in EDIT MODE, preloaded with the
  /// order item's current quantity/variations/add-ons. Saving updates only this
  /// item in the controller; the order is not submitted until Update Cart.
  void _openEdit(BuildContext context, OrderEditController controller, OrderDetailsModel item, int index) {
    if (item.itemDetails == null) { _showAddItemsSheet(context, controller); return; }
    final CartModel preload = _orderItemToCart(item);
    Get.to(() => FoodDetailsScreen(
      itemId: item.itemId!, item: item.itemDetails, cart: preload,
      onCartItemAdd: (CartModel edited) => controller.updateEditableItem(index, edited),
    ));
  }

  /// Build a preload [CartModel] from an order item so the details page can
  /// pre-select the current choices (reconstructs the food-variation bool matrix
  /// and add-on selections from the stored order data).
  CartModel _orderItemToCart(OrderDetailsModel o) {
    final Item item = o.itemDetails!;
    final List<List<bool?>> foodVars = [];
    if (item.foodVariations != null) {
      for (final group in item.foodVariations!) {
        final selGroup = o.foodVariation?.firstWhereOrNull((g) => g.name == group.name);
        foodVars.add([
          for (final val in group.variationValues ?? [])
            (selGroup?.variationValues?.any((sv) => sv.level == val.level) ?? false),
        ]);
      }
    }
    final List<AddOn> addOnIds = [];
    final List<AddOns> addOnsList = [];
    if (o.addOns != null) {
      for (final oa in o.addOns!) {
        final AddOns? match = item.addOns?.firstWhereOrNull((a) => a.id == oa.id);
        if (match != null) {
          addOnsList.add(match);
          addOnIds.add(AddOn(id: oa.id, quantity: oa.quantity ?? 1));
        }
      }
    }
    return CartModel(
      null, item.price, item.price ?? 0, o.variation ?? [], foodVars, 0,
      o.quantity ?? 1, addOnIds, addOnsList, false, item.stock, item, item.quantityLimit,
    );
  }

  Widget _buildChatCard(BuildContext context, OrderEditController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
      child: InkWell(
        onTap: _openVendorChat,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(children: [
          Container(
            height: 42, width: 42, alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('chat_with_vendor'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: 2),
            Text('ask_anything_help_order'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
          ])),
          Icon(Icons.chevron_right, color: Theme.of(context).disabledColor, size: 22),
        ]),
        ),
      ),
    );
  }


  void _showAddItemsSheet(
      BuildContext context, OrderEditController controller) {
    // Trigger a load if items haven't been fetched yet
    if (!controller.isStoreItemsLoading && controller.storeItems.isEmpty) {
      final storeId = widget.storeId ?? widget.orderModel.store?.id;
      if (storeId != null) {
        controller.loadStoreItems(storeId);
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemsBottomSheet(controller: controller),
    );
  }

  Widget _buildOrderNoteField(
      BuildContext context, OrderEditController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Note',
            style:
                robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        TextField(
          controller: _noteController,
          onChanged: controller.updateOrderNote,
          maxLines: 2,
          style:
              robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
          decoration: InputDecoration(
            hintText: 'Add a note for the restaurant...',
            hintStyle: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).disabledColor,
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeSmall,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .disabledColor
                      .withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .disabledColor
                      .withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(Dimensions.radiusDefault),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(
      BuildContext context, OrderEditController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: robotoBold
                  .copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _summaryRow(context, 'Items Subtotal',
              PriceConverter.convertPrice(controller.itemsSubtotal)),
          if ((controller.orderModel?.totalTaxAmount ?? 0) > 0)
            _summaryRow(
                context,
                'Tax',
                PriceConverter.convertPrice(controller.orderModel!.totalTaxAmount)),
          if ((controller.orderModel?.deliveryCharge ?? 0) > 0)
            _summaryRow(
                context,
                'Delivery Fee',
                PriceConverter.convertPrice(controller.orderModel!.deliveryCharge)),
          if ((controller.orderModel?.couponDiscountAmount ?? 0) > 0)
            _summaryRow(
                context,
                'Coupon Discount',
                '-${PriceConverter.convertPrice(controller.orderModel!.couponDiscountAmount)}',
                isDiscount: true),
          Divider(
              color: Theme.of(context)
                  .disabledColor
                  .withValues(alpha: 0.2)),
          _summaryRow(context, 'Total',
              PriceConverter.convertPrice(controller.orderTotal),
              isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value,
      {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: (isBold ? robotoBold : robotoRegular).copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: isBold
                    ? Theme.of(context).textTheme.bodyLarge!.color
                    : Theme.of(context).disabledColor,
              )),
          Text(value,
              style: (isBold ? robotoBold : robotoMedium).copyWith(
                fontSize: isBold
                    ? Dimensions.fontSizeDefault
                    : Dimensions.fontSizeSmall,
                color: isDiscount
                    ? Colors.green
                    : isBold
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge!.color,
              )),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, OrderEditController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('order_total'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
              PriceConverter.convertAnimationPrice(controller.orderTotal, textStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
            ]),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: controller.isLoading ? null : controller.submitEditedOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                  elevation: 0,
                ),
                child: controller.isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('update_cart'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
              ),
            )),
          ]),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('back_to_cart'.tr, style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault)),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, OrderEditController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 80, color: Theme.of(context).disabledColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text('No items left',
              style: robotoBold
                  .copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text('Add items from the store or go back.',
              style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor)),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          ElevatedButton.icon(
            onPressed: () => _showAddItemsSheet(context, controller),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Add Items',
                style: robotoMedium.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault)),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Go Back',
                style: robotoMedium.copyWith(
                    color: Theme.of(context).disabledColor)),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderDetailsModel item;
  final OrderEditController controller;
  /// Single editing interaction — tapping the card OR the Change button both call
  /// this and open the same Food Product Details page in Edit Mode.
  final VoidCallback onEdit;

  const _OrderItemCard({required this.item, required this.controller, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final String itemName = item.itemDetails?.name ?? 'Item #${item.itemId}';
    final String image = item.imageFullUrl ?? item.itemDetails?.imageFullUrl ?? '';
    final double itemTotal = (item.price ?? 0) * (item.quantity ?? 1);
    final bool hasVariant = item.variant != null && item.variant!.isNotEmpty && item.variant != 'null';
    final bool hasAddons = item.addOns != null && item.addOns!.isNotEmpty;

    final List<(String, String)> detailRows = [
      if (hasVariant) ('variations'.tr, item.variant!),
      if (hasAddons) ('extras'.tr, item.addOns!.map((a) => a.name).join(', ')),
    ];

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      elevation: 0,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: CustomImage(image: image, height: 64, width: 64, fit: BoxFit.cover),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(itemName, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${PriceConverter.convertPrice(itemTotal)}  ·  ${'quantity'.tr} ${item.quantity ?? 1}',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ])),
              InkWell(
                onTap: () => _showRemoveDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.error)),
                  child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.error),
                ),
              ),
            ]),

            if (detailRows.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Column(children: List.generate(detailRows.length, (i) => Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : Dimensions.paddingSizeExtraSmall),
                  child: Row(children: [
                    Text(detailRows[i].$1, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                    Text('  ·  ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                    Expanded(child: Text(detailRows[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
                  ]),
                ))),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                  onPressed: () => _showRemoveDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                  ),
                  child: Text('remove'.tr, style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall)),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                  ),
                  child: Text('change'.tr, style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    final String itemName =
        item.itemDetails?.name ?? 'Item #${item.itemId}';
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(Dimensions.radiusLarge)),
      title: Text('Remove Item?', style: robotoBold),
      content: Text('Remove "$itemName" from your order?',
          style: robotoRegular.copyWith(
              color: Theme.of(context).disabledColor)),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel',
              style: robotoMedium.copyWith(
                  color: Theme.of(context).disabledColor)),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            controller.removeItem(item.itemId!);
          },
          child: Text('Remove',
              style: robotoMedium.copyWith(color: Colors.redAccent)),
        ),
      ],
    ));
  }
}

class _AddItemsBottomSheet extends StatefulWidget {
  final OrderEditController controller;

  const _AddItemsBottomSheet({required this.controller});

  @override
  State<_AddItemsBottomSheet> createState() => _AddItemsBottomSheetState();
}

class _AddItemsBottomSheetState extends State<_AddItemsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderEditController>(
      builder: (ctrl) {
        bool isSearching = ctrl.searchQuery.isNotEmpty;
        List<Item> displayItems = isSearching ? ctrl.storeSearchItems : ctrl.storeItems;
        bool isLoading = isSearching ? ctrl.isStoreSearchLoading : ctrl.isStoreItemsLoading;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Dimensions.radiusLarge)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .disabledColor
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Items',
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge),
                    ),
                    IconButton(
                      onPressed: () {
                        ctrl.clearSearch();
                        Get.back();
                      },
                      icon: Icon(Icons.close,
                          color: Theme.of(context).disabledColor),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: CustomTextField(
                  titleText: 'Search items...',
                  controller: _searchController,
                  focusNode: _searchFocus,
                  inputType: TextInputType.text,
                  inputAction: TextInputAction.search,
                  prefixIcon: Icons.search,
                  onChanged: (text) {
                    ctrl.searchStoreItems(text, widget.controller.orderModel?.store?.id);
                  },
                  onSubmit: (text) {
                    ctrl.searchStoreItems(text, widget.controller.orderModel?.store?.id);
                  },
                ),
              ),

              Divider(
                  color: Theme.of(context)
                      .disabledColor
                      .withValues(alpha: 0.2),
                  height: 1),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    isSearching
                                        ? Icons.search_off
                                        : Icons.storefront_outlined,
                                    size: 60,
                                    color: Theme.of(context).disabledColor),
                                const SizedBox(
                                    height: Dimensions.paddingSizeSmall),
                                Text(
                                  isSearching
                                      ? 'No items found for "${ctrl.searchQuery}"'
                                      : 'No more items available\nfrom this store.',
                                  textAlign: TextAlign.center,
                                  style: robotoRegular.copyWith(
                                      color: Theme.of(context).disabledColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                            itemCount: displayItems.length,
                            separatorBuilder: (_, _) => Divider(
                                color: Theme.of(context)
                                    .disabledColor
                                    .withValues(alpha: 0.15)),
                            itemBuilder: (context, index) {
                              return _StoreItemTile(
                                item: displayItems[index],
                                controller: ctrl,
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StoreItemTile extends StatelessWidget {
  final Item item;
  final OrderEditController controller;

  const _StoreItemTile({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final double price = item.price ?? 0;
    final double discount = item.discount ?? 0;
    final bool hasDiscount = discount > 0;
    final double discountedPrice = hasDiscount
        ? (item.discountType == 'percent'
            ? price - (price * discount / 100)
            : price - discount)
        : price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: CustomImage(
              image: item.imageFullUrl ?? '',
              height: 65,
              width: 65,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? '',
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      PriceConverter.convertPrice(discountedPrice),
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        PriceConverter.convertPrice(price),
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).disabledColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Add button
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ItemBottomSheet(
                  itemId: item.id!,
                  item: item,
                  onCartItemAdd: (CartModel cartModel) {
                    controller.addCartItem(cartModel);
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: robotoMedium.copyWith(
                        color: Colors.white,
                        fontSize: Dimensions.fontSizeSmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}