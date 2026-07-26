import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class NotificationStatusChangeBottomSheet extends StatelessWidget {
  /// Presentation-only MoonJoin variant (Phase 8G). When true (Settings only) the
  /// sheet renders in the MoonJoin language. Default false keeps the existing
  /// appearance used by profile_screen + web_profile_widget, unchanged. Callbacks/
  /// controllers/logic are identical.
  final bool moonjoin;
  const NotificationStatusChangeBottomSheet({super.key, this.moonjoin = false});

  @override
  Widget build(BuildContext context) {
    if(moonjoin) {
      return _moonjoinSheet(context);
    }
    return Container(
      width: 500,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveHelper.isDesktop(context) ? BorderRadius.circular(Dimensions.radiusLarge) : const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: GetBuilder<AuthController>(builder: (authController) {
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            ResponsiveHelper.isDesktop(context) ?
                Align(alignment: Alignment.topRight, child: IconButton(onPressed: ()=> Get.back(), icon: const Icon(Icons.clear))) : Container(
              height: 5, width: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
            const SizedBox(height: 35),

            const CustomAssetImageWidget(
              Images.warning, height: 50, width: 50,
            ),
            const SizedBox(height: 35),

            Text('are_you_sure'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge), textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: Text(
                !authController.notification ? 'you_want_to_enable_notification'.tr : 'you_want_to_disable_notification'.tr,
                style: robotoRegular.copyWith(color: Theme.of(context).hintColor), textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),

            Row(children: [

              Expanded(
                child: CustomButton(
                  isLoading: authController.notificationLoading,
                  onPressed: () async {
                    await authController.setNotificationActive(!authController.notification);
                    Get.back();
                  },
                  buttonText: 'yes'.tr,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: CustomButton(
                  onPressed: () {
                    Get.back();
                  },
                  buttonText: 'no'.tr,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                  textColor: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),

            ]),

          ]),
        );
      }),
    );
  }

  // ── MoonJoin premium notification-toggle sheet (isolated Settings variant) ──
  // Same callbacks: Confirm → setNotificationActive(!notification); Cancel → back.
  Widget _moonjoinSheet(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Container(
      width: 500,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: isDesktop ? BorderRadius.circular(Dimensions.radiusExtraLarge) : const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: GetBuilder<AuthController>(builder: (authController) {
        final bool enabling = !authController.notification;
        final Color accent = enabling ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.error;
        return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [

          isDesktop
              ? Align(alignment: Alignment.topRight, child: InkWell(
                  onTap: () => Get.back(), borderRadius: BorderRadius.circular(30),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.clear, size: 20)),
                ))
              : Container(
                  height: 5, width: 40,
                  decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Container(
            height: 64, width: 64, alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(enabling ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: accent, size: 30),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Text('are_you_sure'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge), textAlign: TextAlign.center),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Text(
            enabling ? 'you_want_to_enable_notification'.tr : 'you_want_to_disable_notification'.tr,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor), textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          Row(children: [
            Expanded(child: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 52), padding: EdgeInsets.zero,
                side: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text('cancel'.tr, style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
            )),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(child: CustomButton(
              buttonText: 'confirm'.tr,
              color: accent,
              isLoading: authController.notificationLoading,
              radius: Dimensions.radiusDefault, height: 52,
              onPressed: () async {
                await authController.setNotificationActive(!authController.notification);
                Get.back();
              },
            )),
          ]),

        ]));
      }),
    );
  }
}
