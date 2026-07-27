import 'dart:async';
import 'dart:io';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/sign_in_view.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromNotification;
  final bool fromResetPassword;
  const SignInScreen({super.key, required this.exitFromApp, required this.backFromThis, this.fromNotification = false, this.fromResetPassword = false});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  bool _canExit = GetPlatform.isWeb ? true : false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if(widget.fromNotification || widget.fromResetPassword) {
          Navigator.pushNamed(context, RouteHelper.getInitialRoute());
        } else if(widget.exitFromApp) {
          if (_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            } else {
              Navigator.pushNamed(context, RouteHelper.getInitialRoute());
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ));
            _canExit = true;
            Timer(const Duration(seconds: 2), () {
              _canExit = false;
            });
          }
        } else {
          if(Get.find<AuthController>().isOtpViewEnable){
            Get.find<AuthController>().enableOtpView(enable: false);
          }else{
            // Get.back();
          }
        }
      },
      child: ResponsiveHelper.isDesktop(context) ? _desktopBody(context) : _mobileBody(context),
    );
  }

  // MoonJoin 9C-2: mobile Sign In composed from the frozen Auth Foundation.
  // AuthHero carries the branding/welcome; the AuthCard hosts the existing
  // SignInView (all config-driven login logic preserved). The back affordance
  // mirrors the previous AppBar back behavior exactly.
  Widget _mobileBody(BuildContext context) {
    return AuthScaffold(
      showBack: !widget.exitFromApp,
      onBack: () {
        if(widget.fromNotification || widget.fromResetPassword) {
          Navigator.pushNamed(context, RouteHelper.getInitialRoute());
        } else if(Get.find<AuthController>().isOtpViewEnable){
          Get.find<AuthController>().enableOtpView(enable: false);
        } else {
          Get.back(result: false);
        }
      },
      hero: AuthHero(
        title: 'welcome_back_to_moonjoin'.tr,
        subtitle: 'your_world_of_services_awaits'.tr,
      ),
      child: AuthCard(
        child: SignInView(
          exitFromApp: widget.exitFromApp,
          backFromThis: widget.backFromThis,
          fromResetPassword: widget.fromResetPassword,
          isOtpViewEnable: (v) {},
        ),
      ),
    );
  }

  // Desktop / web layout preserved as before.
  Widget _desktopBody(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: context.width > 700 ? 500 : context.width,
            padding: context.width > 700 ? const EdgeInsets.all(50) : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
            margin: context.width > 700 ? const EdgeInsets.all(50) : EdgeInsets.zero,
            decoration: context.width > 700 ? BoxDecoration(
              color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ) : null,
            child: SingleChildScrollView(
              child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [

                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.clear),
                  ),
                ),

                Image.asset(Images.logo, width: 125),
                const SizedBox(height: Dimensions.paddingSizeExtremeLarge),

                SignInView(exitFromApp: widget.exitFromApp, backFromThis: widget.backFromThis, fromResetPassword: widget.fromResetPassword, isOtpViewEnable: (v){},),

              ]),
            ),
          ),
        ),
      ),
    );
  }

}
