import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — the cross-link row
/// (sign up ↔ sign in ↔ back-to-login ↔ continue-as-guest).
///
/// [enabled] is VISUAL ONLY: it disables the tap and dims the action. It never
/// decides routing — the caller passes [onAction] and owns all navigation and
/// `Get.currentRoute` / guest semantics.
class AuthFooter extends StatelessWidget {
  final String leadingText;
  final String actionText;
  final VoidCallback onAction;
  final bool enabled;

  const AuthFooter({
    super.key,
    required this.leadingText,
    required this.actionText,
    required this.onAction,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leadingText,
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
        ),
        InkWell(
          onTap: enabled ? onAction : null,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Text(
              actionText,
              style: robotoMedium.copyWith(
                color: enabled ? green : green.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
