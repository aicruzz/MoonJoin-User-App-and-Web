import 'dart:math';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class CouponCardWidget extends StatelessWidget {
  final CouponModel coupon;
  final int index;
  final List<JustTheController>? toolTipController;
  /// Presentation-only variant flag. When true (the My Coupons list) the card
  /// renders in the MoonJoin design language. Default false keeps the existing
  /// design used by the Checkout coupon bottom sheet — Checkout is UNCHANGED.
  final bool fromCouponScreen;
  const CouponCardWidget({super.key, required this.coupon, required this.index, this.toolTipController, this.fromCouponScreen = false});

  @override
  Widget build(BuildContext context) {
    if(fromCouponScreen) {
      return _moonjoinCard(context);
    }
    Size size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        boxShadow: [BoxShadow(color: Get.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 1))],
      ),
      child: Stack(children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Transform.rotate(
            angle: Get.find<LocalizationController>().isLtr ? 0 : pi,
            child: Image.asset(
              Get.find<ThemeController>().darkTheme ? Images.couponBgDark : Images.couponBgLight,
              height: ResponsiveHelper.isMobilePhone() ? 160 : 150, width: size.width,
              fit: ResponsiveHelper.isMobilePhone() ? BoxFit.cover : BoxFit.contain,
            ),
          ),
        ),

        Container(
          alignment: Alignment.center,
          child: Row(children: [

            Container(
              alignment: Alignment.center,

              width: ResponsiveHelper.isDesktop(context) ? 150 : size.width * 0.3,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(
                  coupon.discountType == 'percent' ? Images.percentCouponOffer : coupon.couponType
                      == 'free_delivery' ? Images.freeDelivery : Images.money,
                  height: 25, width: 25,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text(
                  '${coupon.discount}${coupon.discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} ${'off'.tr}',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                coupon.store == null ?  Flexible(child: Text(
                  coupon.couponType == 'store_wise' ? '${'on'.tr} ${coupon.data}' : 'on_all_store'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )) : Flexible(child: Text(
                  coupon.couponType == 'default' ? '${coupon.store!.name}' : '',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
            SizedBox(width: ResponsiveHelper.isDesktop(context) ? 10 : 20),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [

                JustTheTooltip(
                  backgroundColor: Get.find<ThemeController>().darkTheme ? Theme.of(context).cardColor : Colors.black87,
                  controller: toolTipController?[index],
                  preferredDirection: AxisDirection.up,
                  tailLength: 14,
                  tailBaseWidth: 20,
                  triggerMode: TooltipTriggerMode.manual,
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${'code_copied'.tr} !',style: robotoRegular.copyWith(color: Theme.of(context).cardColor)),
                  ),
                  child: DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      color: Colors.blueAccent,
                      strokeWidth: 1,
                      strokeCap: StrokeCap.butt,
                      dashPattern: const [5, 5],
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                      radius: const Radius.circular(50),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [

                      Text(
                        '${coupon.code}',
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Icon(Icons.copy_rounded, color: Colors.blueAccent, size: 20),

                    ]),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text(
                  '${DateConverter.stringDateTimeToDate(coupon.startDate!)} - ${DateConverter.stringDateTimeToDate(coupon.expireDate!)}',
                  style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                  Text('*', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeSmall)),

                  Text(
                    '${'min_purchase'.tr} ',
                    style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    PriceConverter.convertPrice(coupon.minPurchase),
                    style: robotoMedium.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                  ),

                ]),

              ]),
            ),

          ]),
        ),

      ]),
    );
  }

  // ── MoonJoin coupon card (My Coupons list variant) — presentation only.
  // Same data + copy/tooltip behavior; green MoonJoin language, ticket layout. ──
  Widget _moonjoinCard(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: green.withValues(alpha: 0.15)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 1)],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // Left accent panel: discount + scope
        Container(
          width: ResponsiveHelper.isDesktop(context) ? 130 : 118,
          color: green.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(
              coupon.discountType == 'percent' ? Images.percentCouponOffer : coupon.couponType == 'free_delivery' ? Images.freeDelivery : Images.money,
              height: 28, width: 28,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              '${coupon.discount}${coupon.discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} ${'off'.tr}',
              textAlign: TextAlign.center,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: green),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              coupon.store == null
                  ? (coupon.couponType == 'store_wise' ? '${'on'.tr} ${coupon.data}' : 'on_all_store'.tr)
                  : (coupon.couponType == 'default' ? '${coupon.store!.name}' : ''),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
              maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            ),
          ]),
        ),

        _perforation(context),

        // Right content: code chip + validity + min purchase
        Expanded(child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [

            JustTheTooltip(
              backgroundColor: Get.find<ThemeController>().darkTheme ? Theme.of(context).cardColor : Colors.black87,
              controller: toolTipController?[index],
              preferredDirection: AxisDirection.up,
              tailLength: 14, tailBaseWidth: 20,
              triggerMode: TooltipTriggerMode.manual,
              content: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${'code_copied'.tr} !', style: robotoRegular.copyWith(color: Theme.of(context).cardColor)),
              ),
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: green,
                  strokeWidth: 1,
                  dashPattern: const [5, 5],
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                  radius: const Radius.circular(50),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: Text('${coupon.code}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: green), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Icon(Icons.copy_rounded, color: green, size: 18),
                ]),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Text(
              '${DateConverter.stringDateTimeToDate(coupon.startDate!)} - ${DateConverter.stringDateTimeToDate(coupon.expireDate!)}',
              style: robotoMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Row(children: [
              Text('*', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeSmall)),
              Text('${'min_purchase'.tr} ', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
              Text(
                PriceConverter.convertPrice(coupon.minPurchase),
                style: robotoMedium.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
              ),
            ]),

          ]),
        )),

      ])),
    );
  }

  // Vertical perforation between the coupon stub and its content.
  Widget _perforation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(9, (_) =>
        Container(height: 4, width: 1.5, color: Theme.of(context).disabledColor.withValues(alpha: 0.35)),
      )),
    );
  }
}
