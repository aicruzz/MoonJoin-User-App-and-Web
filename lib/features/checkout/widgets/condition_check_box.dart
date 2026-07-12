import 'package:flutter/gestures.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckoutCondition extends StatelessWidget {
  final bool isParcel;
  const CheckoutCondition({super.key,  this.isParcel = false});

  @override
  Widget build(BuildContext context) {
    bool activeRefund = Get.find<SplashController>().configModel!.refundPolicyStatus == 1;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // MoonJoin terms checkbox (Figma). Terms are auto-accepted (acceptTerms defaults true).
      Container(
        margin: const EdgeInsets.only(top: 2, right: Dimensions.paddingSizeSmall),
        height: 22, width: 22,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      ),

      Expanded(
        child: RichText(text: TextSpan(children: [
          TextSpan(
            text: '${'i_have_read_and_agreed_with'.tr} ',
            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
          ),
          TextSpan(
            text: 'privacy_policy'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('privacy-policy')),
          ),
          !isParcel && activeRefund ? TextSpan(
            text: ', ',
            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
          ) : TextSpan(
            text: ' ${'and'.tr} ',
            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
          ),
          TextSpan(
            text: 'terms_conditions'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('terms-and-condition')),
          ),
          !isParcel && activeRefund ? TextSpan(text: ' ${'and'.tr} ', style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color)) : const TextSpan(),

          !isParcel && activeRefund ? TextSpan(
            text: 'refund_policy'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('refund-policy')),
          ) : const TextSpan(),
        ]), textAlign: TextAlign.start, maxLines: 3),
      ),
    ]);
  }
}
