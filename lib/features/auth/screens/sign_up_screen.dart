import 'package:moonjoin/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:moonjoin/features/auth/widgets/sign_up_widget.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpScreen extends StatefulWidget {
  final bool exitFromApp;
  const SignUpScreen({super.key, this.exitFromApp = false});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return _desktopBody(context);

    // MoonJoin 9C-3: mobile Sign Up composed from the frozen Auth Foundation.
    // AuthHero carries branding; SignUpWidget hosts the existing form + logic.
    return AuthScaffold(
      showBack: !widget.exitFromApp,
      onBack: () => Get.back(),
      hero: AuthHero(
        title: 'create_your_moonjoin_account'.tr,
        subtitle: 'your_world_of_services_awaits'.tr,
      ),
      child: const AuthCard(child: SignUpWidget()),
    );
  }

  // Desktop / web layout preserved as before.
  Widget _desktopBody(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: Center(
          child: Container(
            width: context.width > 700 ? 700 : context.width,
            padding: context.width > 700 ? const EdgeInsets.all(0) : const EdgeInsets.all(Dimensions.paddingSizeLarge),
            margin: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
            decoration: context.width > 700 ? BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ) : null,
            child: SingleChildScrollView(
              child: Column(children: [

                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.clear),
                  ),
                ),

                Image.asset(Images.logo, width: 125),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                Align(
                  alignment: Alignment.topLeft,
                  child: Text('sign_up'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                const SignUpWidget(),

              ]),
            ),

          ),
        ),
      ),
    );
  }
}
