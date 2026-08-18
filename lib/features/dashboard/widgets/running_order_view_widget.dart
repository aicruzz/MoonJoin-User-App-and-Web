import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/order/controllers/order_controller.dart';
import 'package:moonjoin/features/order/domain/models/order_model.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_motion.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_status_animation.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_presentation_state.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/features/order/screens/order_details_screen.dart';

class RunningOrderViewWidget extends StatelessWidget {
  final List<OrderModel> reversOrder;
  final Function onOrderTap;
  const RunningOrderViewWidget({super.key, required this.reversOrder, required this.onOrderTap});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          // Premium MoonJoin soft upward shadow (replaces the flat black12).
          boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6))],
        ),
        child: Column(children: [

           Center(
            child: Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall + 2),
              height: 4, width: 44,
              decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),
           ),

           ListView.builder(
            itemCount: reversOrder.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index){

              bool isFirstOrder =  index == 0;

              String? orderStatus = reversOrder[index].orderStatus;
              // Effective customer-facing state via the single shared resolver —
              // unavailable overrides 'pending' (same rule as the Home card + banner).
              final MoonJoinPresentationState ps = MoonJoinPresentationState.fromOrder(reversOrder[index]);
              int status = 0;

              if(orderStatus == AppConstants.pending){
                status = 1;
              }else if(orderStatus == AppConstants.accepted || orderStatus == AppConstants.processing || orderStatus == AppConstants.confirmed){
                status = 2;
              }else if(orderStatus == AppConstants.handover || orderStatus == AppConstants.pickedUp){
                status = 3;
              }

              return InkWell(
                onTap: () async {
                  await Get.toNamed(
                    RouteHelper.getOrderDetailsRoute(reversOrder[index].id),
                    arguments: OrderDetailsScreen(
                      orderId: reversOrder[index].id,
                      orderModel: reversOrder[index],
                    ),
                  );
                  if(orderController.showBottomSheet){
                    orderController.showRunningOrders();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall, top: Dimensions.paddingSizeSmall),

                  child:  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Row( crossAxisAlignment: CrossAxisAlignment.center, children: [

                      // MoonJoin Motion Design System — reusable, Flutter-native
                      // status animation (replaces the legacy 6amMart status GIFs).
                      // Centralized backend-status → motion-state mapping; themeable.
                      MoonJoinStatusAnimation(
                        state: ps.motion,
                        size: 56,
                      ),

                      SizedBox(width: isFirstOrder ? 0 : Dimensions.paddingSizeSmall),

                      Expanded(
                        child: Column(mainAxisAlignment: isFirstOrder ? MainAxisAlignment.center : MainAxisAlignment.start,
                            crossAxisAlignment: isFirstOrder ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
                              ps.unavailable
                                ? Text('some_items_are_unavailable'.tr, textAlign: TextAlign.center,
                                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: MoonJoinMotionPalette.amberToken))
                                : Row( mainAxisAlignment: isFirstOrder ? MainAxisAlignment.center : MainAxisAlignment.start, children: [

                                    Text('${'your_order_is'.tr} ', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                                    Text(reversOrder[index].orderStatus!.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
                                  ]) ,
                              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                              Text(
                                '${'order'.tr} #${reversOrder[index].id}',
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),

                              isFirstOrder ? SizedBox(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,
                                      vertical: Dimensions.paddingSizeSmall),
                                  child: Row(children: [
                                    Expanded(child: trackView(context, status: status >= 1 ? true : false)),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    Expanded(child: trackView(context, status: status >= 2 ? true : false)),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    Expanded(child: trackView(context, status: status >= 3 ? true : false)),
                                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                    Expanded(child: trackView(context, status: status >= 4 ? true : false)),
                                  ]),
                                ),
                              ) : const SizedBox()

                            ]),
                      ),

                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: isFirstOrder ? !(reversOrder.length < 2) ? InkWell(
                          onTap: () => onOrderTap(),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('+${reversOrder.length - 1}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
                                Text('more'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                              ]),
                            ) : Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor)
                            : Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor),
                      ),

                    ]),
                  ) ,
                ),
              );
            }),
         ]),
     );
    });
  }

  Widget trackView(BuildContext context, {required bool status}) {
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: status ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
    );
  }
}
