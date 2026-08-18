import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — the unified MoonJoin social / OTP
/// pill that supersedes the legacy `SocialLoginButton` (currently declared in
/// `login_suggestion_bottomsheet.dart`).
///
/// PROVIDER-BLIND BY CONTRACT: this component must NEVER know the auth provider
/// identity. No `if (provider == google)`, no `GoogleSignIn()`, no config-gate
/// reads. It knows only: icon, label, tap callback, and visual state. The SDK
/// work stays entirely in the caller and is passed through via [onTap].
///
/// Migration (staged, not a direct swap): introduce this → point Sign In social
/// rows at it → verify BOTH consumers (social_login_widget + login_suggestion)
/// → only then mark the old `SocialLoginButton` OBSOLETE.
class AuthSocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const AuthSocialButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    const double pillRadius = 26;
    return CustomInkWell(
      onTap: onTap,
      radius: pillRadius,
      child: Container(
        height: 52,
        width: fullWidth ? double.infinity : 150,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(pillRadius),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 22, width: 22),
            if (label.isNotEmpty) ...[
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
