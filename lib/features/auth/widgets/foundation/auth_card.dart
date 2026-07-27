import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — the premium floating form surface.
///
/// Fixed MoonJoin tokens (not free params): large `radiusExtraLarge` corners, a
/// soft premium shadow, `cardColor` fill. Only [padding], [margin] and
/// [widthConstraint] are configurable, and only via `Dimensions.*` — no new
/// radius system, no hardcoded spacing.
class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double? widthConstraint;

  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Dimensions.paddingSizeLarge),
    this.margin,
    this.widthConstraint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widthConstraint,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
