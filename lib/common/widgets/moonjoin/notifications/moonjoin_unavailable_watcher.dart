import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_motion.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_presentation_state.dart';
import 'package:moonjoin/common/widgets/moonjoin/notifications/moonjoin_notification_banner.dart';
import 'package:moonjoin/features/order/controllers/order_controller.dart';
import 'package:moonjoin/features/order/domain/models/order_model.dart';
import 'package:moonjoin/helper/route_helper.dart';

/// State-reactive presenter for the MoonJoin **unavailable** notification — a second
/// presentation of the SAME business state as the approved Home "Unavailable Items"
/// card. NOT driven by FCM. It observes the SAME `OrderController.runningOrderModel`,
/// applies the IDENTICAL rule (a pending running order with a non-empty
/// unavailableItemNote) and surfaces the frozen `MoonJoinNotificationBanner`.
///
/// Business rules (owner-approved):
/// - A transient `runningOrderModel == null` during a refresh is NOT a business state
///   — it never counts as "resolved". Only a fully-loaded model can end the state.
/// - One unavailable session per order: once shown, it survives refreshes — never
///   recreated, never re-animated, dedup never reset — exactly like the Home card.
/// - Unavailable is action-required: it overrides normal status notifications
///   (`isUnavailableActive`) and persists until the customer resolves the items,
///   at which point the banner + Home card clear and normal notifications resume.
class MoonJoinUnavailableWatcher extends StatelessWidget {
  const MoonJoinUnavailableWatcher({super.key});

  /// The active unavailable order id (persists across refresh churn; reset only on a
  /// genuine, fully-loaded resolution). Also the "unavailable overrides normal" gate.
  static int? _activeOrderId;
  static bool get isUnavailableActive => _activeOrderId != null;

  /// The single unavailable detection — via the shared `MoonJoinPresentationState`
  /// resolver (same rule as the Home card). No duplicated logic.
  static OrderModel? flaggedOrder() {
    final List<OrderModel>? orders = Get.find<OrderController>().runningOrderModel?.orders;
    if (orders == null) return null;
    for (final OrderModel o in orders) {
      if (MoonJoinPresentationState.fromOrder(o).unavailable) return o;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (_) {
      // Transient loading is NOT a business state — never treat null as "resolved".
      final List<OrderModel>? orders = Get.find<OrderController>().runningOrderModel?.orders;
      if (orders == null) return const SizedBox.shrink();

      final OrderModel? flagged = flaggedOrder();

      if (flagged == null) {
        // Fully loaded AND no flagged order → genuinely resolved.
        if (_activeOrderId != null) {
          _activeOrderId = null;
          WidgetsBinding.instance.addPostFrameCallback((_) => MoonJoinNotificationBanner.dismiss());
        }
      } else if (flagged.id != _activeOrderId) {
        // A new unavailable order became active → present once (persistent).
        _activeOrderId = flagged.id;
        final int? id = flagged.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          MoonJoinNotificationBanner.show(MoonJoinNotificationData(
            title: 'some_items_are_unavailable'.tr,
            message: 'review_and_edit_your_order_to_continue'.tr,
            state: MoonJoinMotionState.unavailable,
            unavailable: true,
            autoDismiss: null, // action-required: persist until resolved / user acts
            onTap: () {
              if (id != null) Get.toNamed(RouteHelper.getOrderDetailsRoute(id, fromNotification: true));
            },
          ));
        });
      }
      // else: same active order across refreshes → do nothing (survive, no re-show).
      return const SizedBox.shrink();
    });
  }
}
