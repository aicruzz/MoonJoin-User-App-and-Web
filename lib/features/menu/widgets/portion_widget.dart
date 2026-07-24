import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin Navigation Row (shared Account-ecosystem component).
///
/// Renders one tappable list row in the approved MoonJoin design language:
/// a circular soft-green icon chip · bold title (+ optional grey subtitle) ·
/// trailing chevron (or a count badge), with an inset divider. A `isDanger`
/// variant provides the red treatment (e.g. Logout). Navigation / route / onTap
/// behavior is UNCHANGED — presentation only.
class PortionWidget extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final bool hideDivider;
  final String route;
  final String? suffix;
  final bool isDanger;
  final Function()? onTap;
  const PortionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.route,
    this.subtitle,
    this.hideDivider = false,
    this.suffix,
    this.isDanger = false,
    this.onTap,
  });

  static const double _chipSize = 46;

  @override
  Widget build(BuildContext context) {
    final Color accent = isDanger ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap ?? () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: Row(children: [

            // Circular soft-accent icon chip
            Container(
              height: _chipSize, width: _chipSize, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Image.asset(icon, height: 22, width: 22, color: accent),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: isDanger ? accent : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              if(subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                ),
              ],
            ])),

            if(suffix != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall),
                child: Text(suffix!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white), textDirection: TextDirection.ltr),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
            ],

            Icon(Icons.chevron_right_rounded, size: 24, color: Theme.of(context).hintColor.withValues(alpha: 0.7)),
          ]),
        ),

        if(!hideDivider) Padding(
          padding: const EdgeInsets.only(left: _chipSize + Dimensions.paddingSizeDefault),
          child: Divider(height: 1, thickness: 0.6, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        ),
      ]),
    );
  }
}
