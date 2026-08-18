import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/moonjoin/module_icon.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// A rounded card representing a MoonJoin module (icon + label, optional
/// subtitle). Use as an alternative to [CategoryTile] where a card surface is
/// wanted (e.g. a list row or a 2-up grid). Pure presentation.
class ModuleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? assetImage;
  final IconData? icon;
  final VoidCallback? onTap;

  const ModuleCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.assetImage,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          ModuleIcon(imageUrl: imageUrl, assetImage: assetImage, icon: icon, size: 54),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
