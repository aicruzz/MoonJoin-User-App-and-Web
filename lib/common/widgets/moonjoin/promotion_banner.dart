import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A promotional offer card ("20% OFF — On all drinks"), used in the home
/// "Special Offers" carousel and elsewhere. Green surface by default with an
/// optional trailing image. Pure presentation.
class PromotionBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const PromotionBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.backgroundColor,
    this.onTap,
    this.width = 280,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(subtitle!, style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            SizedBox(width: height, height: height, child: CustomImage(image: imageUrl!, fit: BoxFit.cover)),
        ]),
      ),
    );
  }
}
