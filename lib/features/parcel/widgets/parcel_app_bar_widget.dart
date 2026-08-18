import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/moonjoin/wavy_header.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/notification/controllers/notification_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/helper/address_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// Parcel-specific green wavy header (Package Delivery home). Reuses the frozen
/// [WavyHeader] motif; the controls (back · module glyph · title/subtitle ·
/// search · cart) sit on the green and a white location pill (address + bell)
/// straddles the wave. Presentation only — all taps route through existing
/// controllers/routes.
class ParcelAppBarWidget extends StatelessWidget {
  const ParcelAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    final double topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: topInset + 168,
      child: Stack(clipBehavior: Clip.none, children: [

        // Green wave motif (frozen WavyHeader)
        Positioned(top: 0, left: 0, right: 0, child: WavyHeader(height: topInset + 128, color: green)),

        // Top controls row
        Positioned(
          top: topInset + Dimensions.paddingSizeSmall,
          left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault,
          child: Row(children: [
            _circleButton(
              context, icon: Icons.arrow_back,
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Get.back();
                } else {
                  Get.find<SplashController>().removeModule();
                }
              },
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            GetBuilder<SplashController>(builder: (splashController) {
              return Container(
                height: 46, width: 46, padding: const EdgeInsets.all(3),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                // cover so the glyph fills almost the whole yellow card (crops the
                // transparent PNG margins); container clips to the rounded square.
                child: (splashController.module?.iconFullUrl != null)
                    ? CustomImage(image: splashController.module!.iconFullUrl!, height: 40, width: 40, fit: BoxFit.cover)
                    : const Icon(Icons.local_shipping, color: Colors.white, size: 32),
              );
            }),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(Get.find<SplashController>().module?.moduleName ?? 'package_delivery'.tr,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
              Text('send_packages_to_your_loved_ones'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
            ])),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            _circleButton(context, icon: Icons.search, onTap: () => Get.toNamed(RouteHelper.getSearchRoute())),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            GetBuilder<CartController>(builder: (cartController) {
              return _circleButton(
                context, icon: CupertinoIcons.cart, badge: cartController.cartList.length,
                onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
              );
            }),
          ]),
        ),

        // Location pill straddling the wave
        Positioned(
          left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Expanded(child: InkWell(
                onTap: () => Get.find<LocationController>().navigateToLocationScreen('home'),
                child: Row(children: [
                  Container(
                    height: 34, width: 34, alignment: Alignment.center,
                    decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                    child: Icon(Icons.location_on, color: green, size: 20),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(child: GetBuilder<LocationController>(builder: (locationController) {
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(AddressHelper.getUserAddressFromSharedPref()!.addressType!.tr,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      Row(children: [
                        Flexible(child: Text(AddressHelper.getUserAddressFromSharedPref()!.address ?? '',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall))),
                        Icon(Icons.keyboard_arrow_down, color: Theme.of(context).disabledColor, size: 18),
                      ]),
                    ]);
                  })),
                ]),
              )),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              InkWell(
                onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                child: GetBuilder<NotificationController>(builder: (notificationController) {
                  return Stack(clipBehavior: Clip.none, children: [
                    Icon(CupertinoIcons.bell, size: 24, color: Theme.of(context).textTheme.bodyLarge!.color),
                    if (notificationController.hasNotification) Positioned(top: 0, right: 0, child: Container(
                      height: 9, width: 9,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle,
                          border: Border.all(width: 1, color: Theme.of(context).cardColor)),
                    )),
                  ]);
                }),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _circleButton(BuildContext context, {required IconData icon, required VoidCallback onTap, int badge = 0}) {
    final Color green = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 42, width: 42, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: green, size: 20),
        ),
        if (badge > 0) Positioned(
          top: -3, right: -3,
          child: Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle,
                border: Border.all(width: 1.2, color: green)),
            child: Text(badge > 99 ? '99+' : '$badge',
                style: robotoBold.copyWith(color: Colors.white, fontSize: 9)),
          ),
        ),
      ]),
    );
  }
}
