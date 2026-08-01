import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/moonjoin/bottom_action_bar.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// THE official **MoonJoin Commerce Bottom Action Container**.
///
/// A premium pinned bottom bar that pairs an optional [summary] line (e.g. an
/// order total) with a primary [action] button, laid out with an intentional
/// spacing rhythm. It **composes** the shared [BottomActionBar] (rounded-top
/// card surface, soft upward shadow, single bottom safe-area) so the container
/// chrome is never duplicated — there is exactly one bottom inset.
///
/// Designed for reuse across every commerce flow: Checkout, Parcel Request,
/// Wallet actions, Booking confirmation, Subscription checkout, and any future
/// commerce surface. Presentation only — [summary] and [action] are hosted
/// exactly as provided; this widget owns no business logic.
class MoonjoinCommerceActionBar extends StatelessWidget {
  /// Optional info line shown above the action (e.g. the Total Amount row).
  final Widget? summary;

  /// The primary action, typically a full-width button.
  final Widget action;

  /// Vertical rhythm between [summary] and [action].
  final double spacing;

  const MoonjoinCommerceActionBar({
    super.key,
    required this.action,
    this.summary,
    this.spacing = Dimensions.paddingSizeDefault,
  });

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeDefault + 1,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeSmall,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summary != null) ...[
            summary!,
            SizedBox(height: spacing),
          ],
          action,
        ],
      ),
    );
  }
}
