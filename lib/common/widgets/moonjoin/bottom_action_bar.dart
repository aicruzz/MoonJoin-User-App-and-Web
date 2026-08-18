import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';

/// A fixed bottom container with the MoonJoin card surface, top shadow and
/// safe-area padding — the standard pinned footer for a single primary action
/// (wrap a button in it) or any custom [child]. Pure presentation.
class BottomActionBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BottomActionBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Dimensions.paddingSizeDefault),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
