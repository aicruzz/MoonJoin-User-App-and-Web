import 'package:sixam_mart/common/widgets/moonjoin/motion/moonjoin_motion.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';

/// THE single MoonJoin customer-facing order-status resolver.
///
/// Backend workflow status is NOT always the customer-facing status. Once the vendor
/// requests a customer edit (`customerEditRequested`, while the order is still
/// `pending` or `confirmed`), the **effective** customer state becomes **Unavailable /
/// Action Required** — overriding the raw `orderStatus`. This is the exact rule the approved
/// Home "Unavailable Items" card already uses; centralising it here so every status
/// surface derives it identically and the rule is never duplicated again.
///
/// Presentation only — it never mutates backend status, order lifecycle, database,
/// `OrderController`, or business workflow.
class MoonJoinPresentationState {
  /// The MoonJoin motion/moon to display.
  final MoonJoinMotionState motion;
  /// Whether the effective state is the action-required "unavailable" state.
  final bool unavailable;
  const MoonJoinPresentationState(this.motion, this.unavailable);

  /// Resolve the effective presentation from an order:
  ///   IF the vendor requested a customer edit (customerEditRequested, pending/confirmed) → Unavailable
  ///   ELSE → orderStatus
  static MoonJoinPresentationState fromOrder(OrderModel order) {
    if ((order.orderStatus == 'pending' || order.orderStatus == 'confirmed') && order.customerEditRequested == true) {
      return const MoonJoinPresentationState(MoonJoinMotionState.unavailable, true);
    }
    return MoonJoinPresentationState(MoonJoinMotion.forOrderStatus(order.orderStatus), false);
  }
}
