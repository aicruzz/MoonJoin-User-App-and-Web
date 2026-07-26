import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';

/// The single, shared MoonJoin Guest Foundation (Phase 9B). Redesigned in place —
/// used by ~14 guarded surfaces; one change updates them all. Presentation only:
/// the Login behavior and the `callBack(bool)` contract are preserved verbatim.
class NotLoggedInScreen extends StatelessWidget {
  final Function(bool success) callBack;
  const NotLoggedInScreen({super.key, required this.callBack});

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: FooterView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtremeLarge),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [

              // Illustration in a soft-green MoonJoin halo — welcoming, not error-like.
              Container(
                height: 168, width: 168, alignment: Alignment.center,
                decoration: BoxDecoration(color: green.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Image.asset(Images.guest, height: 110, width: 110),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              Text(
                'you_are_not_logged_in'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text(
                'please_login_to_continue'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),

              // Login — behavior preserved EXACTLY (route/dialog/OrderController/callBack).
              SizedBox(
                width: 240,
                child: CustomButton(
                  buttonText: 'login'.tr,
                  radius: Dimensions.radiusLarge,
                  icon: Icons.login_rounded,
                  onPressed: () async {

                    if(!ResponsiveHelper.isDesktop(context)) {
                      await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                    }else{
                      Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: true)), barrierDismissible: false).then((value) => callBack(true));
                    }
                    if(Get.find<OrderController>().showBottomSheet) {
                      Get.find<OrderController>().showRunningOrders();
                    }
                    callBack(true);

                  },
                ),
              ),

            ]),
          ),
        ),
      ),
    );
  }
}
