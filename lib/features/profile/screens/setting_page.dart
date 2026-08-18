import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/controllers/theme_controller.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/language/controllers/language_controller.dart';
import 'package:moonjoin/features/language/widgets/language_bottom_sheet_widget.dart';
import 'package:moonjoin/features/profile/widgets/notification_status_change_bottom_sheet.dart';
import 'package:moonjoin/features/profile/widgets/profile_button_widget.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isDesktop ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      key: UniqueKey(),
      body: Column(children: [

        if(!isDesktop) ProfilePageHeader(title: 'settings'.tr, showBack: true),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(children: [

            // Rows reuse the FROZEN ProfileButtonWidget (already MoonJoin) — unchanged.
            ProfileButtonWidget(icon: Icons.language, title: 'language'.tr, languageName: AppConstants.languages[Get.find<LocalizationController>().selectedLanguageIndex].languageName, onTap: () {
              _manageLanguageFunctionality();
            }),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            GetBuilder<ThemeController>(
              builder: (themeController) {
                return ProfileButtonWidget(icon: Icons.tonality_outlined, title: 'dark_mode'.tr, isButtonActive: themeController.darkTheme, onTap: () {
                  themeController.toggleTheme();
                });
              }
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            isLoggedIn ? GetBuilder<AuthController>(builder: (authController) {
              return ProfileButtonWidget(
                icon: Icons.notifications, title: 'notification'.tr,
                isButtonActive: authController.notification,
                onTap: () {
                  Get.bottomSheet(const NotificationStatusChangeBottomSheet(moonjoin: true));
                },
              );
            }) : const SizedBox(),
            SizedBox(height: isLoggedIn ? Dimensions.paddingSizeLarge : 0),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${'version'.tr}:', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(AppConstants.appVersion.toStringAsFixed(1), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
            ]),

          ]),
        )),

      ]),
    );
  }

  void _manageLanguageFunctionality() {
    Get.find<LocalizationController>().saveCacheLanguage(null);
    Get.find<LocalizationController>().searchSelectedLanguage();

    showModalBottomSheet(
      isScrollControlled: true, useRootNavigator: true, context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: const LanguageBottomSheetWidget(),
        );
      },
    ).then((value) => Get.find<LocalizationController>().setLanguage(Get.find<LocalizationController>().getCacheLocaleFromSharedPref()));
  }
}
