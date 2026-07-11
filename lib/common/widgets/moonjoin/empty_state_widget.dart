import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Centered empty-state placeholder: illustration/icon + title + message and an
/// optional action button. Pure presentation. Provide [assetImage] for a
/// bespoke illustration or fall back to [icon].
class MoonjoinEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final String? assetImage;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const MoonjoinEmptyState({
    super.key,
    required this.title,
    this.message,
    this.assetImage,
    this.icon = Icons.inbox_outlined,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (assetImage != null)
            Image.asset(assetImage!, height: 140, width: 140)
          else
            Container(
              height: 110, width: 110,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 52, color: Theme.of(context).primaryColor),
            ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(title, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          if (message != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(message!, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
          ],
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeSmall),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text(actionText!, style: robotoBold.copyWith(color: Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }
}
