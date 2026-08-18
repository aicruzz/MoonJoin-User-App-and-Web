import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — an "or continue with" / "or"
/// separator. The [label] is supplied (already translated) by the caller; when
/// null a plain divider renders. No default label lives inside the component.
class AuthDivider extends StatelessWidget {
  final String? label;
  final double verticalPadding;

  const AuthDivider({
    super.key,
    this.label,
    this.verticalPadding = Dimensions.paddingSizeSmall,
  });

  @override
  Widget build(BuildContext context) {
    final Color line = Theme.of(context).disabledColor;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: label == null
          ? Divider(color: line, height: 1)
          : Row(children: [
              Expanded(child: Container(height: 1, color: line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: Text(
                  label!,
                  style: robotoMedium.copyWith(color: line),
                ),
              ),
              Expanded(child: Container(height: 1, color: line)),
            ]),
    );
  }
}
