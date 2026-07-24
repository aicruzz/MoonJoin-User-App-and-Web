import 'package:flutter/cupertino.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';

/// MoonJoin Setting / Toggle / Action Row (shared Account-ecosystem component).
///
/// A standalone premium card row in the approved MoonJoin design language:
/// circular soft-accent icon chip · title (+ optional grey subtitle) · trailing
/// control that adapts to the row type — Cupertino toggle (`isButtonActive`),
/// language selector (`languageName`), or a chevron (navigation/action). A red
/// accent (`color`/`isDanger`) drives the danger treatment (e.g. Delete Account).
/// All onTap / toggle behavior is UNCHANGED — presentation only.
class ProfileButtonWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool? isButtonActive;
  final Function onTap;
  final Color? color;
  final String? iconImage;
  final String? languageName;
  final bool isDanger;
  const ProfileButtonWidget({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isButtonActive,
    this.color,
    this.iconImage,
    this.languageName,
    this.isDanger = false,
  });

  static const double _chipSize = 44;

  @override
  Widget build(BuildContext context) {
    final Color accent = isDanger
        ? Theme.of(context).colorScheme.error
        : (color ?? Theme.of(context).primaryColor);

    return InkWell(
      onTap: onTap as void Function()?,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: isDanger ? accent.withValues(alpha: 0.06) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: (isDanger ? accent : Theme.of(context).disabledColor).withValues(alpha: 0.12), width: 0.6),
          boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.10), spreadRadius: 1, blurRadius: 5)],
        ),
        child: Row(children: [

          // Circular soft-accent icon chip
          Container(
            height: _chipSize, width: _chipSize, alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: iconImage != null
                ? Image.asset(iconImage!, height: 20, width: 20, color: accent)
                : Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: isDanger ? accent : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if(subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ],
          ])),

          _trailing(context),
        ]),
      ),
    );
  }

  Widget _trailing(BuildContext context) {
    if(isButtonActive != null) {
      return Transform.scale(
        scale: 0.7,
        child: CupertinoSwitch(
          value: isButtonActive!,
          activeTrackColor: Theme.of(context).primaryColor,
          onChanged: (bool? value) => onTap(),
          inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        ),
      );
    }
    if(languageName != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        child: Row(children: [
          Text(languageName!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          const Icon(Icons.keyboard_arrow_down, size: 15),
        ]),
      );
    }
    return Icon(
      Icons.chevron_right_rounded,
      size: 22,
      color: isDanger ? Theme.of(context).colorScheme.error : Theme.of(context).hintColor,
    );
  }
}
