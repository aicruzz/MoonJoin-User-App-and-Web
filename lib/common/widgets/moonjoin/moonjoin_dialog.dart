import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_button.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// A styled MoonJoin dialog: rounded card with an optional icon, title,
/// message and up to two actions (confirm + cancel). Pure presentation — pass
/// it to `showDialog` / `Get.dialog`.
class MoonjoinDialog extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;
  final String? confirmText;
  final VoidCallback? onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;
  final Widget? content;

  const MoonjoinDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.confirmText,
    this.onConfirm,
    this.cancelText,
    this.onCancel,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = iconColor ?? Theme.of(context).primaryColor;
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Container(
              height: 72, width: 72,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: accent),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
          Text(title, textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          if (message != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(message!, textAlign: TextAlign.center, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
          ],
          if (content != null) ...[const SizedBox(height: Dimensions.paddingSizeDefault), content!],
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Row(children: [
            if (cancelText != null)
              Expanded(child: MoonjoinButton(text: cancelText!, type: MoonjoinButtonType.outline, onPressed: onCancel)),
            if (cancelText != null && confirmText != null) const SizedBox(width: Dimensions.paddingSizeSmall),
            if (confirmText != null)
              Expanded(child: MoonjoinButton(text: confirmText!, onPressed: onConfirm)),
          ]),
        ]),
      ),
    );
  }
}
