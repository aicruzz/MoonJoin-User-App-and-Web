import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — a MoonJoin THEME wrapper over the
/// existing `PinCodeTextField` (`pin_code_fields`). Theme only: the OTP
/// verification architecture, `beforeTextPaste`, and verify logic are NOT
/// changed here. All behavior enters via passthrough params.
class AuthOtpField extends StatelessWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final StreamController<ErrorAnimationType>? errorController;
  final bool hasError;
  final bool autoFocus;

  const AuthOtpField({
    super.key,
    required this.onChanged,
    this.length = 6,
    this.controller,
    this.errorController,
    this.hasError = false,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    const double borderWidth = 0.7;
    return PinCodeTextField(
      length: length,
      appContext: context,
      controller: controller,
      autoFocus: autoFocus,
      keyboardType: TextInputType.number,
      animationType: AnimationType.slide,
      animationDuration: const Duration(milliseconds: 300),
      backgroundColor: Colors.transparent,
      enableActiveFill: true,
      onChanged: onChanged,
      beforeTextPaste: (text) => true,
      errorAnimationController: errorController,
      errorTextSpace: 20,
      errorTextMargin: const EdgeInsets.only(top: 10),
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        fieldHeight: 60,
        fieldWidth: 50,
        borderWidth: borderWidth,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        selectedColor: Theme.of(context).primaryColor,
        selectedFillColor: Theme.of(context).cardColor,
        inactiveFillColor: Theme.of(context).cardColor,
        inactiveColor: Theme.of(context).disabledColor.withValues(alpha: 0.6),
        activeColor: hasError ? Colors.orange : Theme.of(context).primaryColor.withValues(alpha: 0.5),
        activeFillColor: Theme.of(context).cardColor,
        inactiveBorderWidth: borderWidth,
        selectedBorderWidth: borderWidth,
        disabledBorderWidth: borderWidth,
        errorBorderWidth: borderWidth,
        activeBorderWidth: borderWidth,
      ),
    );
  }
}
