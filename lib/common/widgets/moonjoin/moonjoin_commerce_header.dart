import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// THE single MoonJoin **Commerce Header** — the approved flat green header of the
/// frozen Your Cart page, extracted **verbatim** so every commerce screen (Cart,
/// Checkout, …) shares ONE implementation. This is the single source of truth for
/// the commerce header; **do not fork, duplicate, or restyle it.**
///
/// Rendering is pixel-identical to the frozen Cart header: primary-green fill,
/// `SafeArea(bottom:false)` top inset, a circular white@18% back button, a bold
/// white title with an optional white@90% subtitle, and an optional trailing
/// action. Presentation only — no business logic.
class MoonjoinCommerceHeader extends StatelessWidget {
  final String title;
  /// Optional secondary line under the title (e.g. Cart's "3 items"). When null,
  /// only the title renders (used by Checkout).
  final String? subtitle;
  /// Optional back handler; defaults to `Get.back()` (identical to the frozen Cart).
  final VoidCallback? onBack;
  /// Optional trailing action on the right (e.g. Cart's clear-cart button).
  final Widget? trailing;
  const MoonjoinCommerceHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
          child: Row(children: [
            InkWell(
              onTap: onBack ?? () => Get.back(),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                height: 40, width: 40,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge)),
              if (subtitle != null) Text(subtitle!, style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
            ])),
            ?trailing,
          ]),
        ),
      ),
    );
  }
}
