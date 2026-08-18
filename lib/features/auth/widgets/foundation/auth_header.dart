import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — a titled top bar for the
/// verification / forgot / new-password screens. This is the auth-scoped
/// replacement for `CustomAppBar` (auth screens only — NOT an app-wide
/// CustomAppBar migration).
///
/// Deliberately a plain widget, NOT a `PreferredSizeWidget`: auth screens
/// compose `AuthScaffold > AuthHeader > body` instead of `Scaffold > AppBar`,
/// so the foundation stays independent of the Material AppBar lifecycle.
///
/// Presentation only. Callers pass already-translated strings. The back
/// affordance only invokes [onBack]; the host owns navigation.
class AuthHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AuthHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    final double topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topInset + Dimensions.paddingSizeSmall,
        bottom: Dimensions.paddingSizeLarge,
        left: Dimensions.paddingSizeSmall,
        right: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: green,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: showBack
                ? IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                  )
                : const SizedBox(),
          ),

          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white),
            ),
          ),

          SizedBox(width: 48, child: trailing ?? const SizedBox()),
        ],
      ),
    );
  }
}
