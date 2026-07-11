import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Centered error-state placeholder with a retry action. Use for failed loads /
/// no-connection screens. Pure presentation — [onRetry] carries the action.
class MoonjoinErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String? assetImage;
  final IconData icon;
  final String retryText;
  final VoidCallback? onRetry;

  const MoonjoinErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.assetImage,
    this.icon = Icons.error_outline,
    this.retryText = 'Try Again',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final Color error = Theme.of(context).colorScheme.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (assetImage != null)
            Image.asset(assetImage!, height: 140, width: 140)
          else
            Container(
              height: 110, width: 110,
              decoration: BoxDecoration(color: error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 52, color: error),
            ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(title, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          if (message != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(message!, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
              label: Text(retryText, style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeSmall),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
