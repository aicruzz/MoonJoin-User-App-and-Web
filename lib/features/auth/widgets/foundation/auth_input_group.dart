import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — a labeled cluster that WRAPS the
/// caller's existing `CustomTextField`s (or any input widgets). It never
/// constructs fields, never owns controllers / focus nodes / validators, and
/// never runs `onChanged` logic — all of that stays with the caller so the
/// frozen validation behavior is untouched.
class AuthInputGroup extends StatelessWidget {
  /// The caller's already-built input widgets (e.g. CustomTextField).
  final List<Widget> children;

  /// Optional already-translated group label.
  final String? label;

  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const AuthInputGroup({
    super.key,
    required this.children,
    this.label,
    this.spacing = Dimensions.paddingSizeLarge,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];

    if (label != null) {
      items.add(Text(
        label!,
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ));
      items.add(SizedBox(height: spacing));
    }

    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(SizedBox(height: spacing));
      }
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}
