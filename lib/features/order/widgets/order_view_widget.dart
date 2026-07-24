import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/widgets/order_shimmer_widget.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/order/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Storefront **Orders** list (Food/Grocery/Pharmacy/Ecommerce/Parcel). Premium
/// MoonJoin card, consistent with the Rental Trips card. Presentation-only:
/// same `OrderController`, pagination, refresh, empty state, and navigation
/// (`getOrderDetailsRoute` / `getOrderTrackingRoute`) — every branch preserved
/// (parcel / prescription / running-track / history item-count / desktop).
class OrderViewWidget extends StatelessWidget {
  final bool isRunning;
  const OrderViewWidget({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final bool desktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<OrderController>(builder: (orderController) {
        final PaginatedOrderModel? model = isRunning ? orderController.runningOrderModel : orderController.historyOrderModel;
        if(model == null) return OrderShimmerWidget(orderController: orderController);
        if(model.orders!.isEmpty) return NoDataScreen(text: 'no_order_found'.tr, showFooter: true);

        return RefreshIndicator(
          onRefresh: () async => isRunning
              ? orderController.getRunningOrders(1, isUpdate: true)
              : orderController.getHistoryOrders(1, isUpdate: true),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: FooterView(child: SizedBox(width: Dimensions.webMaxWidth,
              child: Padding(
                padding: EdgeInsets.only(bottom: desktop ? 0 : 100),
                child: PaginatedListView(
                  scrollController: scrollController,
                  onPaginate: (int? offset) async => isRunning
                      ? orderController.getRunningOrders(offset!, isUpdate: true)
                      : orderController.getHistoryOrders(offset!, isUpdate: true),
                  totalSize: model.totalSize,
                  offset: model.offset,
                  itemView: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: Dimensions.paddingSizeLarge,
                      mainAxisSpacing: desktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
                      mainAxisExtent: 168,
                      crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 2,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                    itemCount: model.orders!.length,
                    itemBuilder: (context, index) => _orderCard(context, model.orders![index]),
                  ),
                ),
              ),
            )),
          ),
        );
      }),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    final Color green = Theme.of(context).primaryColor;
    final bool isParcel = order.orderType == 'parcel';
    final bool isPrescription = order.prescriptionOrder ?? false;
    final Color statusColor = _statusColor(context, order.orderStatus);
    final String? image = isParcel ? order.parcelCategory?.imageFullUrl : order.store?.logoFullUrl;
    final String title = isParcel ? 'parcel'.tr : (order.store?.name ?? '');

    return CustomInkWell(
      onTap: () => Get.toNamed(
        RouteHelper.getOrderDetailsRoute(order.id),
        arguments: OrderDetailsScreen(orderId: order.id, orderModel: order),
      ),
      radius: Dimensions.radiusLarge,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

          // Status pill + Order/Delivery ID
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
              child: Text((order.orderStatus ?? '').toTitleCase().toUpperCase(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: statusColor)),
            ),
            Text('${isParcel ? 'delivery_id'.tr : 'order_id'.tr}: ${order.id}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
          ]),

          // Store logo (+ parcel/prescription tag) + name + date + amount
          Row(children: [
            Stack(children: [
              Container(
                height: 54, width: 54, alignment: Alignment.center,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: isParcel ? green.withValues(alpha: 0.10) : null),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImage(image: image ?? '', height: isParcel ? 30 : 54, width: isParcel ? 30 : 54, fit: isParcel ? BoxFit.contain : BoxFit.cover),
                ),
              ),
              if(isParcel || isPrescription) Positioned(left: 0, top: 8, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(color: green, borderRadius: const BorderRadius.horizontal(right: Radius.circular(Dimensions.radiusSmall))),
                child: Text(isParcel ? 'parcel'.tr : 'prescription'.tr, style: robotoMedium.copyWith(fontSize: 8, color: Colors.white)),
              )),
            ]),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if(title.isNotEmpty) Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              const SizedBox(height: 2),
              Text(order.createdAt != null ? DateConverter.dateTimeStringToDateTime(order.createdAt!) : '',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ])),
            Text(PriceConverter.convertPrice(order.orderAmount ?? 0), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: green)),
          ]),

          Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),

          // Footer: item count / track + View Details
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            isRunning
                ? InkWell(
                    onTap: () => Get.toNamed(RouteHelper.getOrderTrackingRoute(order.id, null)),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), border: Border.all(width: 1, color: green)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset(Images.tracking, height: 14, width: 14, color: green),
                        const SizedBox(width: 4),
                        Text(isParcel ? 'track_delivery'.tr : 'track_order'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: green)),
                      ]),
                    ),
                  )
                : Text(isParcel ? '' : '${order.detailsCount ?? 0} ${(order.detailsCount ?? 0) > 1 ? 'items'.tr : 'item'.tr}',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            Row(children: [
              Text('view_details'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: green)),
              Icon(Icons.chevron_right, size: 18, color: green),
            ]),
          ]),
        ]),
      ),
    );
  }

  Color _statusColor(BuildContext context, String? status) {
    if(status == 'delivered') return Theme.of(context).primaryColor;
    if(status == 'canceled' || status == 'failed' || status == 'refunded' || status == 'refund_requested') return Theme.of(context).colorScheme.error;
    return Theme.of(context).primaryColor;
  }
}
