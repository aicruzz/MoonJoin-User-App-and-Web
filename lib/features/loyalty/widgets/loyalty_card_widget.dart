import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:moonjoin/features/loyalty/widgets/loyalty_bottom_sheet_widget.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';

class LoyaltyCardWidget extends StatelessWidget {
  final JustTheController tooltipController;
  const LoyaltyCardWidget({super.key, required this.tooltipController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MoonJoin premium points card (green surface, white content).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.85)],
                ),
                boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Row(children: [

                Container(
                  height: 64, width: 64, alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), shape: BoxShape.circle),
                  child: Image.asset(Images.loyal, height: 38, width: 38),
                ),
                const SizedBox(width: Dimensions.paddingSizeLarge),

                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    '${'convertible_points'.tr} !',
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    profileController.userInfoModel!.loyaltyPoint == null ? '0' : profileController.userInfoModel!.loyaltyPoint.toString(),
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Colors.white),
                  ),
                ])),
              ]),
            ),

            ResponsiveHelper.isDesktop(context) ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            ResponsiveHelper.isDesktop(context) ? Text('how_to_use'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)) : const SizedBox(),
            ResponsiveHelper.isDesktop(context) ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            !ResponsiveHelper.isDesktop(context) ? const SizedBox() : const LoyaltyStepper(),
          ],
        );
      }
    );
  }
}



class LoyaltyStepper extends StatelessWidget {
  const LoyaltyStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                    ),
                  ),

                  Expanded(
                    child: VerticalDivider(
                      thickness: 3,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.30),
                    ),
                  ),

                  Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('convert_your_loyalty_point_to_wallet_money'.tr, style: robotoRegular),
                    Text('${'minimun'.tr} ${Get.find<SplashController>().configModel!.loyaltyPointExchangeRate} ${'points_required_to_convert_into_currency'.tr}', style: robotoRegular),
                  ],
                ),
              ),

            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        CustomButton(
          radius: Dimensions.radiusSmall,
          isBold: true,
          buttonText: 'convert_to_currency_now'.tr,
          onPressed: () {
            Get.dialog(
              Dialog(backgroundColor: Colors.transparent, child: LoyaltyBottomSheetWidget(
                amount: Get.find<ProfileController>().userInfoModel!.loyaltyPoint == null
                  ? '0' : Get.find<ProfileController>().userInfoModel!.loyaltyPoint.toString(),
              )),
            );
          },
        ),
      ],
    );
  }
}

