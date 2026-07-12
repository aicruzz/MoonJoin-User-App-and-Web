import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/checkout/widgets/time_slot_bottom_sheet.dart';

class TimeSlotSection extends StatelessWidget {
  final int? storeId;
  final CheckoutController checkoutController;
  final List<CartModel?>? cartList;
  final JustTheController tooltipController2;
  final bool tomorrowClosed;
  final bool todayClosed;
  final Module? module;
  const TimeSlotSection({super.key, this.storeId, required this.checkoutController, this.cartList, required this.tooltipController2,
    required this.tomorrowClosed, required this.todayClosed, this.module,
  });

  @override
  Widget build(BuildContext context) {
    bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    return Column(children: [
      !isGuestLoggedIn && storeId == null && checkoutController.store!.scheduleOrder! && cartList!.isNotEmpty && cartList![0]!.item!.availableDateStarts == null ? Container(
        // MoonJoin "Preference Time" card (Figma).
        margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('preference_time'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            JustTheTooltip(
              backgroundColor: Colors.black87,
              controller: tooltipController2,
              preferredDirection: AxisDirection.right,
              tailLength: 14,
              tailBaseWidth: 20,
              content: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('schedule_time_tool_tip'.tr,style: robotoRegular.copyWith(color: Colors.white)),
              ),
              child: InkWell(
                onTap: () => tooltipController2.showTooltip(),
                child: const Icon(Icons.info_outline),
              ),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          InkWell(
            onTap: (){
              if(ResponsiveHelper.isDesktop(context)){
                showDialog(context: context, builder: (con) => Dialog(
                  child: TimeSlotBottomSheet(
                    tomorrowClosed: tomorrowClosed,
                    todayClosed: todayClosed, module: module,
                  ),
                ));
              }else{
                showModalBottomSheet(
                  context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (con) => TimeSlotBottomSheet(
                    tomorrowClosed: tomorrowClosed,
                    todayClosed: todayClosed, module: module,
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault)
              ),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              child: Builder(builder: (context) {
                bool closed = (checkoutController.selectedDateSlot == 0 && todayClosed) || (checkoutController.selectedDateSlot == 1 && tomorrowClosed);
                bool instant = checkoutController.preferableTime.isEmpty;
                return Row(children: [
                  Icon(Icons.access_time, color: Theme.of(context).primaryColor, size: 24),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(
                    child: closed
                      ? Text(module!.showRestaurantText! ? 'restaurant_is_closed'.tr : 'store_is_closed'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(instant ? 'instant_delivery'.tr : checkoutController.preferableTime, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          if(instant) Text('as_soon_as_possible'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                        ]),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Icon(Icons.keyboard_arrow_down, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ]);
              }),
            ),
          ),
        ]),
      ) : const SizedBox(),

      SizedBox(height: !isGuestLoggedIn && storeId == null && checkoutController.store!.scheduleOrder! && cartList!.isNotEmpty && cartList![0]!.item!.availableDateStarts == null ? Dimensions.paddingSizeSmall : 0),

    ]);
  }
}
