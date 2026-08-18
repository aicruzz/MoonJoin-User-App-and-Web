import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_text_field.dart';
import 'package:moonjoin/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — ISOLATED demonstration harness for
/// the 10 foundation components. This file is intentionally NOT routed and NOT
/// imported by any production screen — it exists only for foundation
/// review/testing per the 9C-1 contract ("do not import outside foundation
/// demo/testing"). It contains no business logic, no navigation, no API calls.
class AuthFoundationGallery extends StatelessWidget {
  const AuthFoundationGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      hero: const AuthHero(
        title: 'Welcome back to MoonJoin',
        subtitle: 'Your world of food, shopping and services awaits',
      ),
      onBack: () {},
      child: AuthCard(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthInputGroup(
              label: 'Sign in',
              children: [
                CustomTextField(
                  labelText: 'Email or phone',
                  titleText: 'Enter email or phone',
                  controller: TextEditingController(),
                  focusNode: FocusNode(),
                ),
                CustomTextField(
                  labelText: 'Password',
                  titleText: '8+ characters',
                  isPassword: true,
                  controller: TextEditingController(),
                  focusNode: FocusNode(),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            AuthPrimaryButton(text: 'Login', onPressed: () {}, icon: Icons.login_rounded),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            AuthPrimaryButton(text: 'Login', onPressed: () {}, isLoading: true),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            const AuthDivider(label: 'or continue with'),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Wrap(spacing: 15, runSpacing: 15, children: [
              AuthSocialButton(iconPath: Images.google, label: 'Google', onTap: () {}),
              AuthSocialButton(iconPath: Images.appleLogo, label: 'Apple', onTap: () {}),
            ]),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            AuthOtpField(onChanged: (_) {}),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            AuthFooter(leadingText: "Don't have an account? ", actionText: 'Sign up', onAction: () {}),
          ],
        ),
      ),
    );
  }
}
