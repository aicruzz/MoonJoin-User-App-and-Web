import 'package:moonjoin/features/order/controllers/order_controller.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class ConfirmationDialog extends StatelessWidget {
  final String icon;
  final String? title;
  final String description;
  final Function onYesPressed;
  final bool isLogOut;
  final Function? onNoPressed;
  /// Presentation-only MoonJoin variant (Phase 8D). When true the dialog renders in
  /// the premium MoonJoin language. Default false keeps the existing dialog used by
  /// all other 20 call sites unchanged. Callbacks/behaviour are identical.
  final bool moonjoin;
  const ConfirmationDialog({super.key, required this.icon, this.title, required this.description, required this.onYesPressed,
    this.isLogOut = false, this.onNoPressed, this.moonjoin = false});

  @override
  Widget build(BuildContext context) {
    if(moonjoin) {
      return _moonjoinDialog(context);
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      insetPadding: const EdgeInsets.all(30),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: PointerInterceptor(
        child: SizedBox(width: 500, child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Image.asset(icon, width: 50, height: 50, color: Theme.of(context).primaryColor),
            ),

            title != null ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: Text(
                title!, textAlign: TextAlign.center,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Colors.red),
              ),
            ) : const SizedBox(),

            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Text(description, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge), textAlign: TextAlign.center),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            GetBuilder<OrderController>(builder: (orderController) {
              return !orderController.isLoading ? Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => isLogOut ? onYesPressed() : onNoPressed != null ? onNoPressed!() : Get.back(),
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.3), minimumSize: const Size(Dimensions.webMaxWidth, 50), padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                  ),
                  child: Text(
                    isLogOut ? 'yes'.tr : 'no'.tr, textAlign: TextAlign.center,
                    style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                  ),
                )),
                const SizedBox(width: Dimensions.paddingSizeLarge),

                Expanded(child: CustomButton(
                  buttonText: isLogOut ? 'no'.tr : 'yes'.tr,
                  onPressed: () => isLogOut ? Get.back() : onYesPressed(),
                  radius: Dimensions.radiusSmall, height: 50,
                )),
              ]) : const Center(child: CircularProgressIndicator());
            }),

          ]),
        )),
      ),
    );
  }

  // ── MoonJoin premium confirmation dialog (isolated variant) ──
  // Same callbacks: primary green = onYesPressed (Logout); secondary = cancel
  // (onNoPressed ?? Get.back()). Presentation only.
  Widget _moonjoinDialog(BuildContext context) {
    final Color accent = isLogOut ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;
    final Color green = Theme.of(context).primaryColor;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      insetPadding: const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge),
      backgroundColor: Theme.of(context).cardColor,
      child: PointerInterceptor(
        child: SizedBox(width: 400, child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Icon chip
            Container(
              height: 64, width: 64, alignment: Alignment.center,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(isLogOut ? Icons.logout_rounded : Icons.help_outline_rounded, color: accent, size: 30),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text(
              title ?? (isLogOut ? 'logout'.tr : 'confirm'.tr),
              textAlign: TextAlign.center,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Text(
              description, textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            GetBuilder<OrderController>(builder: (orderController) {
              return !orderController.isLoading ? Row(children: [

                // Cancel (secondary)
                Expanded(child: TextButton(
                  onPressed: () => onNoPressed != null ? onNoPressed!() : Get.back(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 52), padding: EdgeInsets.zero,
                    side: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                  ),
                  child: Text('cancel'.tr, style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
                )),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                // Confirm (primary green) — Logout / Yes
                Expanded(child: CustomButton(
                  buttonText: isLogOut ? 'logout'.tr : 'yes'.tr,
                  color: green,
                  onPressed: () => onYesPressed(),
                  radius: Dimensions.radiusDefault, height: 52,
                )),

              ]) : const Center(child: Padding(padding: EdgeInsets.all(Dimensions.paddingSizeSmall), child: CircularProgressIndicator()));
            }),

          ]),
        )),
      ),
    );
  }
}
