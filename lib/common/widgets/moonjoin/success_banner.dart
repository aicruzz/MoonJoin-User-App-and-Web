import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// A success confirmation block: a green check badge, title, message and an
/// optional primary action — for order/booking success screens and dialogs.
/// Pure presentation.
class SuccessBanner extends StatelessWidget {
  final String title;
  final String? message;
  final String? assetImage;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const SuccessBanner({
    super.key,
    required this.title,
    this.message,
    this.assetImage,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (assetImage != null)
          Image.asset(assetImage!, height: 140, width: 140)
        else
          Container(
            height: 96, width: 96,
            decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.check_circle, size: 64, color: primary),
          ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Text(title, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
        if (message != null) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(message!, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
        ],
        if (actionText != null && onAction != null) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text(actionText!, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
            ),
          ),
        ],
        if (secondaryActionText != null && onSecondaryAction != null) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          TextButton(
            onPressed: onSecondaryAction,
            child: Text(secondaryActionText!, style: robotoMedium.copyWith(color: primary)),
          ),
        ],
      ]),
    );
  }
}
