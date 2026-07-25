import 'package:flutter/material.dart';
import 'package:sixam_mart/features/checkout/widgets/virtual_account_details_widget.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/menu/widgets/portion_widget.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {

  /// Returns true if 9PSB is in the active payment methods list
  bool get _is9PSBActive {
    final list = Get.find<SplashController>().configModel!.activePaymentMethodList;
    if (list == null) return false;
    return list.any((m) => m.getWay?.toLowerCase() == '9psb');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).cardColor,
      body: GetBuilder<ProfileController>(builder: (profileController) {
        final bool isLoggedIn = AuthHelper.isLoggedIn();

        return Column(children: [

          ClipPath(
            clipper: _HeaderWaveClipper(),
            child: Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Padding(
              padding: EdgeInsets.only(
                left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeLarge,
                top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeSmall,
                bottom: Dimensions.paddingSizeLarge,
              ),
              child: Column(
                children: [
                  Row(children: [

                    // Avatar + edit badge → Edit Profile (existing route, unchanged)
                    GestureDetector(
                      onTap: isLoggedIn ? () => Get.toNamed(RouteHelper.getUpdateProfileRoute()) : null,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).cardColor, width: 2),
                          ),
                          padding: const EdgeInsets.all(1),
                          child: ClipOval(child: CustomImage(
                            placeholder: Images.guestIconLight,
                            image: '${(profileController.userInfoModel != null && isLoggedIn) ? profileController.userInfoModel!.imageFullUrl : ''}',
                            height: 52, width: 52, fit: BoxFit.cover,
                          )),
                        ),
                        if(isLoggedIn) Positioned(
                          bottom: -2, right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                            ),
                            child: Icon(Icons.edit, size: 11, color: Theme.of(context).cardColor),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        isLoggedIn && profileController.userInfoModel == null ? Shimmer(
                          child: Container(
                            height: 15, width: 150,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ) : Text(
                          isLoggedIn ? '${profileController.userInfoModel?.fName ?? ''} ${profileController.userInfoModel?.lName ?? ''}' : 'guest_user'.tr,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                        ),
                        SizedBox(height: isLoggedIn && profileController.userInfoModel == null ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeExtraSmall),

                        isLoggedIn && profileController.userInfoModel == null ? Shimmer(
                          child: Container(
                            height: 15, width: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ) : isLoggedIn ? Text(
                          '${'joined'.tr} ${profileController.userInfoModel != null ? DateConverter.containTAndZToUTCFormat(profileController.userInfoModel!.createdAt!) : ''}',
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor),
                        ) : SizedBox(),

                      ]),
                    ),

                    // Notification bell (with unread dot) → Notifications (existing route)
                    if(isLoggedIn) ...[
                      _headerCircleButton(
                        context,
                        onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                        child: Stack(clipBehavior: Clip.none, children: [
                          Icon(Icons.notifications_none_rounded, color: Theme.of(context).primaryColor, size: 24),
                          Positioned(
                            top: -1, right: -1,
                            child: Container(
                              height: 8, width: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).cardColor, width: 1),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                    ],

                    // Dark-mode toggle (existing behavior, unchanged)
                    _headerCircleButton(
                      context,
                      onTap: () => Get.find<ThemeController>().toggleTheme(),
                      child: Get.find<ThemeController>().darkTheme
                          ? Icon(Icons.wb_sunny_rounded, color: Theme.of(context).primaryColor, size: 22)
                          : Image.asset(Images.moon, height: 22, color: Theme.of(context).primaryColor),
                    ),

                  ]),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  !isLoggedIn ? Column(children: [
                    Divider(
                      thickness: 0.2, color: Theme.of(context).cardColor,
                    ),

                    Row(children: [
                      Expanded(child: Text(
                        'for_more_personalised_and_smooth_experience'.tr,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor),
                      )),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      TextButton(
                        style:  TextButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.8),
                          minimumSize: Size(130, 30),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            side: BorderSide.none,
                          ),
                        ),
                        onPressed: () async {
                          if(!ResponsiveHelper.isDesktop(context)) {
                            await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                            if(AuthHelper.isLoggedIn()) {
                              profileController.getUserInfo();
                            }
                          }else{
                            Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: true, backFromThis: true)));
                          }
                          },
                        child: Text('login_signup'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color),),
                      ),

                    ]),
                  ]) : const SizedBox(),
                ],
              ),
            ),
          ),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
            child: Column(children: [

              if(isLoggedIn && profileController.userInfoModel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Row(children: [
                    infoCard(profileController, context, Images.loyaltyIcon, double.tryParse(profileController.userInfoModel!.loyaltyPoint.toString()) ?? 0, 'loyalty_points'.tr,
                      actionLabel: 'view_rewards'.tr, route: RouteHelper.getLoyaltyRoute()),
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                    infoCard(profileController, context, Images.orderProfile, double.tryParse(profileController.userInfoModel!.orderCount.toString()) ?? 0, 'orders'.tr,
                      actionLabel: 'my_orders'.tr, route: RouteHelper.getOrderRoute(fromNavigation: true)),
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                    infoCard(profileController, context, Images.walletProfile, double.tryParse(profileController.userInfoModel!.walletBalance.toString()) ?? 0, 'wallet_balance'.tr, isAmount: true,
                      actionLabel: 'my_wallet'.tr, route: RouteHelper.getWalletRoute()),
                  ]),
                ),

              if(isLoggedIn && _is9PSBActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
                  child: const VirtualAccountDetailsWidget(showInstructions: false),
                ),

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeSmall),
                  child: Text(
                    'general'.tr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
                  margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    PortionWidget(icon: Images.profileIcon, title: 'edit_profile'.tr, subtitle: 'update_your_personal_information'.tr, route: RouteHelper.getUpdateProfileRoute()),
                    PortionWidget(icon: Images.addressIcon, title: 'my_address'.tr, subtitle: 'manage_your_saved_addresses'.tr, route: RouteHelper.getAddressRoute()),
                    // PortionWidget(icon: Images.languageIcon, title: 'language'.tr, hideDivider: true, onTap: ()=> _manageLanguageFunctionality(), route: ''),
                    PortionWidget(icon: Images.settings, title: 'settings'.tr, subtitle: 'app_preferences_and_security'.tr, hideDivider: true, route: RouteHelper.getSettingScreen()),
                  ]),
                )

              ]),

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                  child: Text(
                    'promotional_activity'.tr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
                  margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    PortionWidget(
                      icon: Images.couponIcon, title: 'coupon'.tr, subtitle: 'view_and_manage_your_coupons'.tr, route: RouteHelper.getCouponRoute(),
                      hideDivider: Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 || Get.find<SplashController>().configModel!.customerWalletStatus == 1 ? false : true,
                    ),

                    (Get.find<SplashController>().configModel!.loyaltyPointStatus == 1) ? PortionWidget(
                        icon: Images.pointIcon, title: 'loyalty_points'.tr, subtitle: 'check_points_and_rewards'.tr, route: RouteHelper.getLoyaltyRoute(),
                      hideDivider: Get.find<SplashController>().configModel!.customerWalletStatus == 1 ? false : true,
                      // suffix: !isLoggedIn ? null : '${profileController.userInfoModel?.loyaltyPoint != null ? profileController.userInfoModel!.loyaltyPoint.toString() : '0'} ${'points'.tr}' ,
                    ) : const SizedBox(),

                    (Get.find<SplashController>().configModel!.customerWalletStatus == 1) ? PortionWidget(
                        icon: Images.walletIcon, title: 'my_wallet'.tr, subtitle: 'manage_your_wallet_balance'.tr, hideDivider: true, route: RouteHelper.getWalletRoute(),
                      // suffix: !isLoggedIn ? null : PriceConverter.convertPrice(profileController.userInfoModel != null ? profileController.userInfoModel!.walletBalance : 0),
                    ) : const SizedBox(),
                  ]),
                )
              ]),

              (Get.find<SplashController>().configModel!.refEarningStatus == 1 ) || (Get.find<SplashController>().configModel!.toggleDmRegistration! && !ResponsiveHelper.isDesktop(context)) ||
                  (Get.find<SplashController>().configModel!.toggleStoreRegistration! && !ResponsiveHelper.isDesktop(context)) ?
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                  child: Text(
                    'earnings'.tr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
                  margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [

                    (Get.find<SplashController>().configModel!.refEarningStatus == 1 ) ? PortionWidget(
                        icon: Images.referIcon, title: 'refer_and_earn'.tr, subtitle: 'invite_friends_and_earn_rewards'.tr, route: RouteHelper.getReferAndEarnRoute(),
                      hideDivider: (Get.find<SplashController>().configModel!.toggleDmRegistration! && !ResponsiveHelper.isDesktop(context)) ||
                          (Get.find<SplashController>().configModel!.toggleStoreRegistration! && !ResponsiveHelper.isDesktop(context)) ? false : true,
                    ) : const SizedBox(),

                    (Get.find<SplashController>().configModel!.toggleDmRegistration! && !ResponsiveHelper.isDesktop(context)) ? PortionWidget(
                        icon: Images.dmIcon, title: 'join_as_a_delivery_man'.tr, subtitle: 'earn_by_delivering_orders'.tr, route: RouteHelper.getDeliverymanRegistrationRoute(),
                      hideDivider: (Get.find<SplashController>().configModel!.toggleStoreRegistration! && !ResponsiveHelper.isDesktop(context)) ? false : true,
                    ) : const SizedBox(),

                    (Get.find<SplashController>().configModel!.toggleStoreRegistration! && !ResponsiveHelper.isDesktop(context)) ? PortionWidget(
                        icon: Images.storeIcon, title: 'open_vendor'.tr, subtitle: 'list_your_restaurant_or_shop'.tr, hideDivider: true, route: RouteHelper.getRestaurantRegistrationRoute(),
                    ) : const SizedBox(),
                  ]),
                )
              ]) : const SizedBox(),

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                  child: Text(
                    'help_and_support'.tr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
                  margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [
                    PortionWidget(icon: Images.chatIcon, title: 'live_chat'.tr, subtitle: 'chat_with_our_support_team'.tr, route: RouteHelper.getConversationRoute()),
                    PortionWidget(icon: Images.helpIcon, title: 'help_and_support'.tr, subtitle: 'find_answers_to_common_questions'.tr, route: RouteHelper.getSupportRoute()),
                    PortionWidget(icon: Images.aboutIcon, title: 'about_us'.tr, subtitle: 'learn_more_about_moonjoin'.tr, route: RouteHelper.getHtmlRoute('about-us')),
                    PortionWidget(icon: Images.termsIcon, title: 'terms_conditions'.tr, subtitle: 'read_our_terms_and_conditions'.tr, route: RouteHelper.getHtmlRoute('terms-and-condition')),
                    PortionWidget(icon: Images.privacyIcon, title: 'privacy_policy'.tr, subtitle: 'how_we_protect_your_data'.tr, route: RouteHelper.getHtmlRoute('privacy-policy')),

                    (Get.find<SplashController>().configModel!.refundPolicyStatus == 1 ) ? PortionWidget(
                        icon: Images.refundIcon, title: 'refund_policy'.tr, subtitle: 'view_our_refund_policy'.tr, route: RouteHelper.getHtmlRoute('refund-policy'),
                      hideDivider: (Get.find<SplashController>().configModel!.cancellationPolicyStatus == 1 ) ||
                          (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1 ) ? false : true,
                    ) : const SizedBox(),

                    (Get.find<SplashController>().configModel!.cancellationPolicyStatus == 1 ) ? PortionWidget(
                        icon: Images.cancelationIcon, title: 'cancellation_policy'.tr, subtitle: 'review_our_cancellation_policy'.tr, route: RouteHelper.getHtmlRoute('cancellation-policy'),
                      hideDivider: (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1 ) ? false : true,
                    ) : const SizedBox(),

                    (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1 ) ? PortionWidget(
                        icon: Images.shippingIcon, title: 'shipping_policy'.tr, subtitle: 'review_our_shipping_policy'.tr, hideDivider: true, route: RouteHelper.getHtmlRoute('shipping-policy'),
                    ) : const SizedBox(),
                  ]),
                )
              ]),

              InkWell(
                onTap: () async {
                  if(AuthHelper.isLoggedIn()) {
                    Get.dialog(ConfirmationDialog(icon: Images.support, description: 'are_you_sure_to_logout'.tr, isLogOut: true, moonjoin: true, onYesPressed: () async {
                      Get.find<AuthController>().resetOtpView();
                      Get.find<ProfileController>().clearUserInfo();
                      Get.find<AuthController>().socialLogout();
                      Get.find<CartController>().clearCartList(canRemoveOnline: false);
                      Get.find<FavouriteController>().removeFavourite();
                      await Get.find<AuthController>().clearSharedData();
                      Get.find<HomeController>().forcefullyNullCashBackOffers();
                      if(Get.find<SplashController>().module != null) {
                        Get.find<TaxiCartController>().getCarCartList();
                      }
                      // Get.offAllNamed(RouteHelper.getInitialRoute());
                      Get.back();
                      showCustomSnackBar('logout_successful'.tr, isError: false);
                    }), useSafeArea: false);
                  }else {
                    Get.find<FavouriteController>().removeFavourite();
                    await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                    if(AuthHelper.isLoggedIn()) {
                      await Get.find<FavouriteController>().getFavouriteList();
                      profileController.getUserInfo();
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                      child: Icon(Icons.power_settings_new_sharp, size: 18, color: Theme.of(context).cardColor),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    Text(AuthHelper.isLoggedIn() ? 'logout'.tr : 'sign_in'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge))
                  ]),
                ),
              ),

              SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtremeLarge : 100),

            ]),
          )),
        ]);
      }),
    );
  }

  Widget infoCard(ProfileController profileController, BuildContext context, String image, double value, String title, {bool isAmount = false, String? actionLabel, String? route}) {
    return Expanded(
      child: InkWell(
        onTap: route != null ? () => Get.toNamed(route) : null,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: Theme.of(context).disabledColor, width: 0.2),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Column(children: [
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Image.asset(image, height: 30, width: 30),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isAmount ? PriceConverter.convertPrice(value, forMenuWallet: true) : value.toStringAsFixed(0),
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ),
            const SizedBox(height: 2),

            Text(
              title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5)),
            ),

            if(actionLabel != null) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Flexible(child: Text(
                    actionLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor),
                  )),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Theme.of(context).primaryColor),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // White circular header action button (bell / dark-mode) on the green header.
  Widget _headerCircleButton(BuildContext context, {required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(height: 40, width: 40, child: Center(child: child)),
      ),
    );
  }

}

/// Gentle wave bottom for the green Profile header (matches profile.png): the
/// green dips lower at the sides while the white crests upward toward the centre.
class _HeaderWaveClipper extends CustomClipper<Path> {
  static const double _amp = 20;
  @override
  Path getClip(Size size) {
    final path = Path();
    final h = size.height;
    final w = size.width;
    path.lineTo(0, h - _amp * 0.35);
    path.cubicTo(w * 0.30, h, w * 0.52, h - _amp, w * 0.72, h - _amp * 0.85);
    path.cubicTo(w * 0.88, h - _amp * 0.72, w * 0.96, h - _amp * 0.15, w, h - _amp * 0.35);
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
