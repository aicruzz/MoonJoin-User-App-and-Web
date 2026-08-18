import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/support/widgets/web_help_support_widget.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {

  // Preserved actions — config values + tel/mailto launches unchanged.
  void _call() async {
    final String? phone = Get.find<SplashController>().configModel!.phone;
    if(await canLaunchUrlString('tel:$phone')) {
      launchUrlString('tel:$phone');
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $phone');
    }
  }

  void _email() async {
    final String? email = Get.find<SplashController>().configModel!.email;
    final String mailto = Uri(scheme: 'mailto', path: email).toString();
    // Robust + graceful: open the external mail app when a handler exists (real
    // devices with Gmail/Mail); otherwise show a fallback (e.g. iOS Simulator has
    // no Mail app installed, so mailto has no handler). Same pattern as _call.
    if(await canLaunchUrlString(mailto)) {
      await launchUrlString(mailto, mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isDesktop ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: Column(children: [

        if(!isDesktop) ProfilePageHeader(title: 'help_support'.tr),

        Expanded(child: SingleChildScrollView(
          padding: isDesktop ? EdgeInsets.zero : const EdgeInsets.all(Dimensions.paddingSizeDefault),
          physics: const BouncingScrollPhysics(),
          child: Center(child: FooterView(
            child: isDesktop ? const SizedBox(
              width: double.infinity, height: 650,
              child: WebSupportScreen(),
            ) : SizedBox(width: Dimensions.webMaxWidth, child: Column(children: [

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Hero
              Image.asset(Images.supportImage, height: 120),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text('we_are_here_to_help'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text('contact_us'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              _contactCard(context, icon: Icons.mail_outline_rounded, title: 'email_us'.tr,
                  info: Get.find<SplashController>().configModel!.email, onTap: _email),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              _contactCard(context, icon: Icons.call_outlined, title: 'call'.tr,
                  info: Get.find<SplashController>().configModel!.phone, onTap: _call),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              _contactCard(context, icon: Icons.location_on_outlined, title: 'address'.tr,
                  info: Get.find<SplashController>().configModel!.address, onTap: null),

              const SizedBox(height: Dimensions.paddingSizeLarge),
            ])),
          )),
        )),

      ]),
    );
  }

  // MoonJoin contact card — green icon chip · title · info · action chevron.
  Widget _contactCard(BuildContext context, {required IconData icon, required String title, String? info, VoidCallback? onTap}) {
    final Color green = Theme.of(context).primaryColor;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.12)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(children: [

            Container(
              height: 46, width: 46, alignment: Alignment.center,
              decoration: BoxDecoration(color: green.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(icon, color: green, size: 22),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 3),
              Text(info ?? '', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),

            if(onTap != null) ...[
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Icon(Icons.chevron_right_rounded, size: 22, color: Theme.of(context).hintColor.withValues(alpha: 0.7)),
            ],

          ]),
        ),
      ),
    );
  }
}
