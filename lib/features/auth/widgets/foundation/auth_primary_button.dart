import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — a thin MoonJoin PRESET over the
/// frozen `CustomButton` (green, `radiusLarge`, `isLoading`).
///
/// It only presets `CustomButton` params — it does NOT reimplement button
/// internals. In particular the loading presentation belongs to `CustomButton`
/// (which already shows its own spinner + "loading" text); this widget never
/// substitutes its own loading text.
class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final IconData? icon;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      buttonText: text,
      onPressed: onPressed,
      isLoading: isLoading,
      radius: Dimensions.radiusLarge,
      width: width,
      height: height ?? 54,
      icon: icon,
    );
  }
}
