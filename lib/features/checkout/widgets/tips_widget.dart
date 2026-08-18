import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

class TipsWidget extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Function onTap;
  final bool isSuggested;
  const TipsWidget({super.key, required this.title, required this.isSelected, required this.onTap, required this.isSuggested});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeExtraSmall, bottom: 0),
      child: Column(children: [

        InkWell(
          onTap: onTap as void Function()?,
          child: Container(
            padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // MoonJoin tip chip (Figma): white pill, green border + green text when selected.
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(
                color: ResponsiveHelper.isDesktop(context) ? Theme.of(context).primaryColor
                    : isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.35),
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Column(children: [
              Padding(
                padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.only(
                    top: !isSuggested ? Dimensions.fontSizeSmall : Dimensions.paddingSizeExtraSmall,
                    left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                ) : EdgeInsets.zero,
                child: Text(
                  title, textDirection: TextDirection.ltr,
                  style: (isSelected ? robotoBold : robotoRegular).copyWith(
                    color: isSelected ? Theme.of(context).primaryColor : ResponsiveHelper.isDesktop(context)
                        ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              isSuggested && ResponsiveHelper.isDesktop(context) ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusSmall)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 3),
                child: Text(
                  'most_tipped'.tr, style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeOverSmall),
                ),
              ) : SizedBox(height: ResponsiveHelper.isDesktop(context) ? 10 : 0),
            ]),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall -1),

        isSuggested && !ResponsiveHelper.isDesktop(context) ? Text(
          'most_tipped'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraSmall),
        ) : const SizedBox(),
      ]),
    );
  }
}
