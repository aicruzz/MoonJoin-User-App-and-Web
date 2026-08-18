import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/custom_text_field.dart';
import 'package:moonjoin/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/widgets/social_login_widget.dart';
import 'package:moonjoin/features/language/controllers/language_controller.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/validate_check.dart';
import 'package:moonjoin/util/dimensions.dart';

class OtpLoginWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final String? countryDialCode;
  final Function(CountryCode countryCode)? onCountryChanged;
  final Function() onClickLoginButton;
  final bool socialEnable;
  final bool backFromThis;
  const OtpLoginWidget({super.key, required this.phoneController, required this.phoneFocus, required this.onCountryChanged, required this.countryDialCode,
    required this.onClickLoginButton, this.socialEnable = false, required this.backFromThis});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<AuthController>(builder: (authController) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? Dimensions.paddingSizeLarge : 0),
        // Welcome heading now lives in AuthHero above; omitted here.
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          CustomTextField(
            titleText: 'xxx-xxx-xxxxx'.tr,
            controller: phoneController,
            focusNode: phoneFocus,
            inputAction: TextInputAction.done,
            inputType: TextInputType.phone,
            isPhone: true,
            onCountryChanged: onCountryChanged,
            countryDialCode: countryDialCode ?? Get.find<LocalizationController>().locale.countryCode,
            labelText: 'phone'.tr,
            required: true,
            validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_phone_number".tr),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          // Remember-me checkbox removed (MoonJoin 9C-2).
          AuthPrimaryButton(
            text: 'login'.tr,
            isLoading: authController.isLoading,
            onPressed: () => onClickLoginButton(),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          socialEnable ? SocialLoginWidget(onlySocialLogin: false, backFromThis: backFromThis) : const SizedBox(),

          socialEnable && isDesktop ? const SizedBox(height: Dimensions.paddingSizeLarge) : const SizedBox(),

          !socialEnable ? const SizedBox(height: 100) : const SizedBox(),

        ]),
      );
    });
  }
}
