import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/order/controllers/order_edit_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_details_model.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';

class OrderEditScreen extends StatefulWidget {
  final OrderModel orderModel;
  final List<OrderDetailsModel> orderDetails;
  final int? storeId;

  const OrderEditScreen({
    super.key,
    required this.orderModel,
    required this.orderDetails,
    this.storeId,
  });

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController =
        TextEditingController(text: widget.orderModel.orderNote ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OrderEditController>()
          .loadOrder(widget.orderModel, widget.orderDetails, storeId: widget.storeId);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderEditController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  size: 20),
              onPressed: () => Get.back(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Order #${widget.orderModel.id}',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
                Text(
                  'Unpaid • Pending',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            actions: [
              // Add Items button in app bar
              TextButton.icon(
                onPressed: () => _showAddItemsSheet(context, controller),
                icon: Icon(Icons.add_circle_outline,
                    color: Theme.of(context).primaryColor, size: 18),
                label: Text(
                  'Add Items',
                  style: robotoMedium.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),
            ],
          ),
          body: controller.editableItems.isEmpty && !controller.isLoading
              ? _buildEmptyState(context, controller)
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        children: [
                          // Info banner
                          _buildInfoBanner(context),
                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Items
                          ...controller.editableItems.map((item) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: Dimensions.paddingSizeSmall),
                                child: _OrderItemCard(
                                    item: item, controller: controller),
                              )),

                          // Order note
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          _buildOrderNoteField(context, controller),
                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Summary
                          _buildOrderSummary(context, controller),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                        ],
                      ),
                    ),
                    _buildBottomBar(context, controller),
                  ],
                ),
        );
      },
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

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.orange, size: 20),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              'Remove unavailable items, adjust quantities, or add new items before resubmitting.',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Colors.orange.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusLarge)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : controller.submitEditedOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusDefault)),
              elevation: 0,
            ),
            child: controller.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Submit Updated Order',
                          style: robotoBold.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeDefault)),
                    ],
                  ),
          ),
        ),
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

  const _OrderItemCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final String itemName =
        item.itemDetails?.name ?? 'Item #${item.itemId}';
    final String image =
        item.imageFullUrl ?? item.itemDetails?.imageFullUrl ?? '';
    final double itemTotal = (item.price ?? 0) * (item.quantity ?? 1);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusSmall),
                  child: CustomImage(
                      image: image,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemName,
                          style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (item.variant != null && item.variant!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(item.variant!,
                              style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: Theme.of(context).disabledColor)),
                        ),
                      if (item.addOns != null && item.addOns!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                              'Add-ons: ${item.addOns!.map((a) => a.name).join(', ')}',
                              style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: Theme.of(context).disabledColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      const SizedBox(height: 6),
                      Text(PriceConverter.convertPrice(itemTotal),
                          style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).primaryColor)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showRemoveDialog(context),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: Dimensions.paddingSizeSmall,
              right: Dimensions.paddingSizeSmall,
              bottom: Dimensions.paddingSizeSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildQuantityStepper(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
            color:
                Theme.of(context).disabledColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => controller.decreaseQuantity(item.itemId!),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                (item.quantity ?? 1) <= 1
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                size: 18,
                color: (item.quantity ?? 1) <= 1
                    ? Colors.redAccent
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('${item.quantity ?? 1}',
                style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault)),
          ),
          GestureDetector(
            onTap: () => controller.increaseQuantity(item.itemId!),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.add_rounded,
                  size: 18, color: Theme.of(context).primaryColor),
            ),
          ),
        ],
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
                            separatorBuilder: (_, __) => Divider(
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
                      '\₦${discountedPrice.toStringAsFixed(2)}',
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\₦${price.toStringAsFixed(2)}',
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