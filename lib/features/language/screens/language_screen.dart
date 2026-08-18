import 'package:moonjoin/common/widgets/custom_asset_image_widget.dart';
import 'package:moonjoin/features/language/screens/web_language_screen.dart';
import 'package:moonjoin/features/language/widgets/language_card_widget.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:moonjoin/features/language/controllers/language_controller.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:get/get.dart';

class ChooseLanguageScreen extends StatefulWidget {
  final bool fromMenu;
  const ChooseLanguageScreen({super.key, this.fromMenu = false});

  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {

  // Preserved exactly: apply + persist the selected language, then navigate
  // (menu → pop, first-run → onboarding). No logic change.
  void _onNext(LocalizationController localizationController) {
    if(localizationController.languages.isNotEmpty && localizationController.selectedLanguageIndex != -1) {
      localizationController.setLanguage(Locale(
        AppConstants.languages[localizationController.selectedLanguageIndex].languageCode!,
        AppConstants.languages[localizationController.selectedLanguageIndex].countryCode,
      ));
      if (widget.fromMenu) {
        Navigator.pop(context);
      } else {
        Get.offNamed(RouteHelper.getOnBoardingRoute());
      }
    } else {
      showCustomSnackBar('select_a_language'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      appBar: isDesktop ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      backgroundColor: widget.fromMenu ? Theme.of(context).colorScheme.surface : Theme.of(context).cardColor,
      body: GetBuilder<LocalizationController>(builder: (localizationController) {
        if(isDesktop) {
          return const WebLanguageScreen();
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Menu experience (Profile): MoonJoin ProfilePageHeader.
          if(widget.fromMenu) ProfilePageHeader(title: 'language'.tr, showBack: true),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // First-run experience (onboarding): illustration-first identity preserved.
            if(!widget.fromMenu) ...[
              const SizedBox(height: 40),
              const Align(
                alignment: Alignment.center,
                child: CustomAssetImageWidget(Images.languageBg, height: 210, width: 210, fit: BoxFit.contain),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ] else
              const SizedBox(height: Dimensions.paddingSizeLarge),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: Text('choose_your_language'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: Text('choose_your_language_to_proceed'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Expanded(
              child: ListView.builder(
                itemCount: localizationController.languages.length,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    child: LanguageCardWidget(
                      languageModel: localizationController.languages[index],
                      localizationController: localizationController,
                      index: index,
                    ),
                  );
                },
              ),
            ),

          ])),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 0)],
              ),
              child: CustomButton(
                buttonText: 'next'.tr,
                onPressed: () => _onNext(localizationController),
              ),
            ),
          ),

        ]);
      }),
    );
  }
}
