import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin form input: rounded field with an optional label, prefix/suffix
/// icons, obscure toggle support and validation error text. Pure presentation —
/// no controllers/services; wire behaviour through the standard callbacks.
class MoonjoinTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final bool enabled;
  final String? errorText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const MoonjoinTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null) ...[
        Text(label!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      ],
      TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        enabled: enabled,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        inputFormatters: inputFormatters,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Theme.of(context).hintColor) : null,
          suffixIcon: suffix,
          errorText: errorText,
          contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        ),
      ),
    ]);
  }
}
