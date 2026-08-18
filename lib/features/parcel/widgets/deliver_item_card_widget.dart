import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';

class DeliverItemCardWidget extends StatelessWidget {
  final String image;
  final String itemName;
  final String description;
  final bool isDeliverItem;
  final Function? onTap;
  const DeliverItemCardWidget({super.key, required this.image, required this.itemName, required this.description, this.isDeliverItem = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDeliverItem ? 0 : Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: isDeliverItem ? 0.15 : 1), width: 0.5),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: isDeliverItem ? [BoxShadow(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
          spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1), // changes position of shadow
        )] : null,
      ),
      child: isDeliverItem ? CustomInkWell(
        onTap: onTap,
        radius: Dimensions.radiusDefault,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeSmall),
        child: Column(children: [
          // Illustration fills the upper portion of the (unchanged) card. Full
          // image, no cropping (BoxFit.contain = complete art, no distortion),
          // sized to the largest the locked card height allows.
          Expanded(child: Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: CustomImage(image: image, fit: BoxFit.contain),
          )),

          Text(itemName, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: robotoBold),
          const SizedBox(height: 2),

          Text(
            description,
            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
          ),
        ]),
      ) : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        CustomImage(
          image: image,
          height: 40, width: 40,
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
            Text(itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium),
            SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeSmall : 0),

            Text(
              description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
            ),
          ]),
        ),

      ]),
    );
  }
}
