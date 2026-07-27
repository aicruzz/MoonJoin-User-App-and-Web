// MoonJoin Auth Foundation (Phase 9C-1) — STANDALONE visual-QA entrypoint.
//
// Launched ONLY via:  flutter run -t lib/features/auth/widgets/foundation/auth_foundation_demo_main.dart
//
// It does NOT touch the production entrypoint, routes, navigation, or any auth
// screen. It renders the approved premium MoonJoin auth language composed from
// the foundation components. No business logic, no controllers, no API.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

void main() => runApp(const _AuthFoundationDemoApp());

class _AuthFoundationDemoApp extends StatelessWidget {
  const _AuthFoundationDemoApp();

  @override
  Widget build(BuildContext context) {
    // Approximate the MoonJoin brand green so the demo reads accurately without
    // booting the full app/theme/controllers. GetMaterialApp is required so the
    // `Dimensions.fontSize*` getters (which read `Get.context`) resolve — the
    // production app boots via GetMaterialApp too.
    const Color moonjoinGreen = Color(0xFF2C9C44);
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoonJoin Auth Foundation — Demo',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: moonjoinGreen,
        colorScheme: ColorScheme.fromSeed(seedColor: moonjoinGreen),
        cardColor: Colors.white,
        hintColor: const Color(0xFF9AA3AE),
        disabledColor: const Color(0xFFB8C0C9),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      ),
      home: const _PremiumSignInDemo(),
    );
  }
}

/// The approved premium MoonJoin Sign In language, composed entirely from
/// foundation components. The forgot-password link is demo-only composition (it
/// lives in ManualLoginWidget in the real app), not a foundation component.
class _PremiumSignInDemo extends StatelessWidget {
  const _PremiumSignInDemo();

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () {},
      hero: const AuthHero(
        title: 'Welcome back to MoonJoin',
        subtitle: 'Your world of food, shopping and services',
      ),
      child: AuthCard(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AuthInputGroup(children: [
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
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Text(
                  'Forgot Password?',
                  style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall),
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          AuthPrimaryButton(text: 'Login', onPressed: () {}),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // "Sign in with OTP" affordance — visual parity with the old
          // manual+OTP layout (manual_login_widget.dart). In production this is
          // shown/hidden by the admin Login Setup config (centralizeLoginSetup)
          // via SignInView; the demo shows it statically for visual approval.
          Column(children: [
            Text('or', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Sign in with ', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
              InkWell(
                onTap: () {},
                child: Text('OTP', style: robotoRegular.copyWith(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)),
              ),
            ]),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          const AuthDivider(label: 'or continue with'),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Row(children: [
            Expanded(child: AuthSocialButton(iconPath: Images.google, label: 'Google', onTap: () {}, fullWidth: true)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: AuthSocialButton(iconPath: Images.appleLogo, label: 'Apple', onTap: () {}, fullWidth: true)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: AuthSocialButton(iconPath: Images.facebook2, label: 'Facebook', onTap: () {}, fullWidth: true)),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          AuthFooter(leadingText: "Don't have an account? ", actionText: 'Sign up', onAction: () {}),
        ]),
      ),
    );
  }
}
