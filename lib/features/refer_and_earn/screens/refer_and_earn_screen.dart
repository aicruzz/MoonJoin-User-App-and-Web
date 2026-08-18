import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:share_plus/share_plus.dart';
import 'package:moonjoin/features/refer_and_earn/widgets/bottom_sheet_view_widget.dart';
import 'package:moonjoin/features/refer_and_earn/widgets/bottomsheet_for_mobile.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/price_converter.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/not_logged_in_screen.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/common/widgets/web_page_title_widget.dart';

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {

  @override
  void initState() {
    super.initState();

    _initCall();
  }

  void _initCall(){
    if(AuthHelper.isLoggedIn() && Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
  }

  // Preserved: exact SharePlus content (app name + referral code + download link).
  void _shareCode(ProfileController profileController) {
    SharePlus.instance.share(
      ShareParams(
        text: Get.find<SplashController>().configModel?.appUrlAndroid != null
            ? '${AppConstants.appName} ${'referral_code'.tr}: ${profileController.userInfoModel!.refCode} \n${'download_app_from_this_link'.tr}: ${Get.find<SplashController>().configModel?.appUrlAndroid}'
            : '${AppConstants.appName} ${'referral_code'.tr}: ${profileController.userInfoModel!.refCode}',
      ),
    );
  }

  // Preserved: exact clipboard copy + snackbar.
  void _copyCode(ProfileController profileController) {
    if(profileController.userInfoModel!.refCode!.isNotEmpty){
      Clipboard.setData(ClipboardData(text: '${profileController.userInfoModel != null ? profileController.userInfoModel!.refCode : ''}'));
      showCustomSnackBar('referral_code_copied'.tr, isError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      appBar: isDesktop ? const WebMenuBar() : null,
      body: Column(children: [

        if(!isDesktop) ProfilePageHeader(
          title: 'refer_and_earn'.tr,
          trailing: InkWell(
            onTap: () => Get.bottomSheet(BottomSheetForMobile()),
            borderRadius: BorderRadius.circular(30),
            child: Icon(Icons.info_outline_rounded, color: Theme.of(context).cardColor, size: 22),
          ),
        ),

        Expanded(child: isLoggedIn ? _content(context, isDesktop) : NotLoggedInScreen(callBack: (value){
          _initCall();
          setState(() {});
        })),

      ]),
    );
  }

  Widget _content(BuildContext context, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : Dimensions.paddingSizeDefault),
      child: Column(children: [
        WebScreenTitleWidget(title: 'refer_and_earn'.tr),
        FooterView(
          child: Center(child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: GetBuilder<ProfileController>(builder: (profileController) {
              return Column(children: [
                const SizedBox(height: Dimensions.paddingSizeLarge),

                Image.asset(
                  Images.referImage, width: 500,
                  height: isDesktop ? 250 : 180, fit: BoxFit.contain,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                _rewardCard(context, profileController, isDesktop),

                if(isDesktop) const Padding(
                  padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraLarge),
                  child: BottomSheetViewWidget(),
                ),

                const SizedBox(height: Dimensions.paddingSizeLarge),
              ]);
            }),
          )),
        ),
      ]),
    );
  }

  // MoonJoin reward/referral card.
  Widget _rewardCard(BuildContext context, ProfileController profileController, bool isDesktop) {
    final Color green = Theme.of(context).primaryColor;
    final String? refCode = profileController.userInfoModel?.refCode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.all(isDesktop ? Dimensions.paddingSizeExtraLarge : Dimensions.paddingSizeLarge),
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? Dimensions.paddingSizeLarge : 0),
      child: Column(children: [

        // Reward rate chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${'one_referral'.tr} = ', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: green)),
            Text(
              PriceConverter.convertPrice(Get.find<SplashController>().configModel != null
                  ? Get.find<SplashController>().configModel!.refEarningExchangeRate!.toDouble() : 0.0),
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: green), textDirection: TextDirection.ltr,
            ),
          ]),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Text('invite_friends_and_business'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge), textAlign: TextAlign.center),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        Text('copy_your_code_share_it_with_your_friends'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Align(
          alignment: Alignment.centerLeft,
          child: Text('your_personal_code'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // Green dashed code box + copy
        DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: green,
            strokeWidth: 1,
            dashPattern: const [8, 5],
            padding: const EdgeInsets.all(0),
            radius: const Radius.circular(Dimensions.radiusDefault),
          ),
          child: SizedBox(
            height: 54,
            child: (profileController.userInfoModel != null) ? Row(children: [
              Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Text(refCode ?? '', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: green)),
              )),
              InkWell(
                onTap: () => _copyCode(profileController),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
                  margin: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).cardColor),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text('copy'.tr, style: robotoMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeDefault)),
                  ]),
                ),
              ),
            ]) : const Center(child: Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: CircularProgressIndicator(),
            )),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Text('or_share'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        if(profileController.userInfoModel != null) CustomButton(
          buttonText: 'share'.tr,
          icon: Icons.share,
          width: isDesktop ? 260 : null,
          onPressed: () => _shareCode(profileController),
        ),
      ]),
    );
  }
}
