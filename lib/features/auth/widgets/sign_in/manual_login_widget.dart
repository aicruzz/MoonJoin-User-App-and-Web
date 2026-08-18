import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/common/widgets/custom_text_field.dart';
import 'package:moonjoin/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/widgets/condition_check_box_widget.dart';
import 'package:moonjoin/features/auth/widgets/sign_up_widget.dart';
import 'package:moonjoin/features/auth/widgets/social_login_widget.dart';
import 'package:moonjoin/features/verification/screens/forget_pass_screen.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/helper/validate_check.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';

class ManualLoginWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final FocusNode phoneFocus;
  final FocusNode passwordFocus;
  final Function() onClickLoginButton;
  final Function()? onWebSubmit;
  final bool socialEnable;
  final Function()? onOtpViewClick;
  final bool backFromThis;
  const ManualLoginWidget({
    super.key, required this.phoneController, required this.phoneFocus, required this.onClickLoginButton, required this.passwordController,
    required this.passwordFocus, this.onWebSubmit, this.socialEnable = false, this.onOtpViewClick, required this.backFromThis,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<AuthController>(builder: (authController) {
      
      if(isDesktop) {
        return webView(isDesktop, context, authController);
      }
      
      // Mobile Sign In card body. The welcome heading now lives in AuthHero
      // (the hero above this card), so it is intentionally omitted here.
      return Column(mainAxisSize: MainAxisSize.min, children: [

        CustomTextField(
          onCountryChanged: (countryCode) => authController.countryDialCode = countryCode.dialCode!,
          countryDialCode: authController.isNumberLogin ? authController.countryDialCode : null,
          labelText: 'email_or_phone'.tr,
          titleText: 'enter_email_or_phone'.tr,
          controller: phoneController,
          focusNode: phoneFocus,
          nextFocus: passwordFocus,
          inputType: TextInputType.emailAddress,
          prefixImage: authController.isNumberLogin ? null : Images.emailWithPhoneIcon,
          onChanged: (String text){
            final numberRegExp = RegExp(r'^[+]?[0-9]+$');
            final notNumberRegExp = RegExp(r'[^0-9+]');

            if(text.isEmpty && authController.isNumberLogin){
              authController.toggleIsNumberLogin();
            }
            if(text.startsWith(numberRegExp) && !text.contains(notNumberRegExp) && !authController.isNumberLogin ){
              authController.toggleIsNumberLogin();

              if(GetPlatform.isWeb) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  phoneController.text = text.replaceAll("+", "");
                  phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: phoneController.text.length),
                  );
                });
              } else {
                phoneController.text = text.replaceAll("+", "");
              }
            }
            final emailRegExp = RegExp(r'@');
            if((text.contains(emailRegExp) || text.contains(notNumberRegExp)) && authController.isNumberLogin){
              authController.toggleIsNumberLogin();
            }

          },
          validator: (String? value){

            if(authController.isNumberLogin && ValidateCheck.getValidPhone(authController.countryDialCode+value!) == ""){
              return "enter_valid_phone_number".tr;
            }
            return (GetUtils.isPhoneNumber(authController.countryDialCode+value!.tr) || GetUtils.isEmail(value.tr)) ? null : 'enter_email_address_or_phone_number'.tr;
          },
        ),

        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

        CustomTextField(
          titleText: '8_character'.tr,
          controller: passwordController,
          focusNode: passwordFocus,
          inputAction: TextInputAction.done,
          inputType: TextInputType.visiblePassword,
          prefixIcon: Icons.lock,
          isPassword: true,
          onSubmit: (text) => (GetPlatform.isWeb) ? onWebSubmit : null,
          labelText: 'password'.tr,
          required: true,
          validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_password".tr),
        ),
        SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall),


        // Remember-me checkbox removed (MoonJoin 9C-2: the email/phone is always
        // remembered and auto-filled; the password is never stored). Only the
        // Forgot Password affordance remains, right-aligned.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () {
              Get.toNamed(RouteHelper.getForgotPassRoute());
            },
            child: Text('${'forgot_password'.tr}?', style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        AuthPrimaryButton(
          text: 'login'.tr,
          isLoading: authController.isLoading,
          onPressed: () => onClickLoginButton(),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        // OTP affordance — shown only when the admin Login Setup enables OTP
        // alongside manual (onOtpViewClick != null). Behavior preserved.
        onOtpViewClick != null ? Column(children: [
          Text('or'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('sign_in_with'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            InkWell(
              onTap: onOtpViewClick,
              child: Text('otp'.tr, style: robotoRegular.copyWith(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ]) : const SizedBox(),

        socialEnable ? SocialLoginWidget(onlySocialLogin: false, backFromThis: backFromThis) : const SizedBox(),

        AuthFooter(
          leadingText: '${'do_not_have_account'.tr} ',
          actionText: 'sign_up'.tr,
          enabled: !authController.isLoading,
          onAction: () {
            Get.toNamed(RouteHelper.getSignUpRoute());
          },
        ),

      ]);
    });
  }

  Widget webView(bool isDesktop, BuildContext context, AuthController authController) {
    bool onlyManualLoginEnable = onOtpViewClick == null && !socialEnable;
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

        Expanded(
          flex: 6,
          child: Column(children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text('login'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            CustomTextField(
              onCountryChanged: (countryCode) => authController.countryDialCode = countryCode.dialCode!,
              countryDialCode: authController.isNumberLogin ? authController.countryDialCode : null,
              labelText: 'email_or_phone'.tr,
              titleText: 'enter_email_or_phone'.tr,
              controller: phoneController,
              focusNode: phoneFocus,
              nextFocus: passwordFocus,
              prefixImage: authController.isNumberLogin ? null : Images.emailWithPhoneIcon,
              inputType: TextInputType.emailAddress,
              onChanged: (String text){
                final numberRegExp = RegExp(r'^[+]?[0-9]+$');

                // Toggle isNumberLogin flag based on input
                if (text.isEmpty && authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                } else if (text.startsWith(numberRegExp) && !authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                  // Store the cleaned number temporarily
                  final cleanedText = text.replaceAll("+", "");
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    phoneController.text = cleanedText;
                    phoneController.selection = TextSelection.fromPosition(
                      TextPosition(offset: phoneController.text.length),
                    );
                  });
                } else if (text.contains('@') && authController.isNumberLogin) {
                  authController.toggleIsNumberLogin();
                }

              },
              validator: (String? value){

                if(authController.isNumberLogin && ValidateCheck.getValidPhone(authController.countryDialCode+value!) == ""){
                  return "enter_valid_phone_number".tr;
                }
                return (GetUtils.isPhoneNumber(value!.tr) || GetUtils.isEmail(value.tr)) ? null : 'enter_email_address_or_phone_number'.tr;
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            CustomTextField(
              titleText: '8_character'.tr,
              controller: passwordController,
              focusNode: passwordFocus,
              inputAction: TextInputAction.done,
              inputType: TextInputType.visiblePassword,
              prefixIcon: Icons.lock,
              isPassword: true,
              onSubmit: (text) => (GetPlatform.isWeb) ? onWebSubmit : null,
              labelText: 'password'.tr,
              required: true,
              validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_password".tr),
            ),
            SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall),


            // Remember-me checkbox removed (MoonJoin 9C-2). Forgot Password only.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  if(isDesktop) {
                    Get.back();
                    Get.dialog(const Center(child: ForgetPassScreen(fromDialog: true)));
                  } else {
                    Get.toNamed(RouteHelper.getForgotPassRoute());
                  }
                },
                child: Text('${'forgot_password'.tr}?', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeLarge),

            const ConditionCheckBoxWidget(forSignUp: true),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            CustomButton(
              buttonText: 'login'.tr,
              radius: Dimensions.radiusDefault,
              isBold: isDesktop ? false : true,
              isLoading: authController.isLoading,
              onPressed: onClickLoginButton,
              fontSize: Dimensions.fontSizeSmall,
            ),

            onlyManualLoginEnable ? Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('do_not_have_account'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

                InkWell(
                  onTap: () {
                    Get.back();
                    Get.dialog(
                      SizedBox(
                        width: 700,
                        child: Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
                          backgroundColor: Theme.of(context).cardColor,
                          insetPadding: EdgeInsets.zero,
                          child: const SignUpWidget(),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Text('sign_up'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                  ),
                ),
              ]),
            ) : const SizedBox(),
            const SizedBox(height: Dimensions.paddingSizeLarge),
          ]),
        ),

        !onlyManualLoginEnable ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraOverLarge, vertical: Dimensions.paddingSizeLarge),
            child: RotatedBox(
              quarterTurns: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 1,
                    child: Container(
                      color: Theme.of(context).disabledColor,
                      width: 100,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'or_login_with'.tr,
                      style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                    ),
                  ),
                  SizedBox(
                    height: 1,
                    child: Container(
                      color: Theme.of(context).disabledColor,
                      width: 100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) : const SizedBox(),

        !onlyManualLoginEnable ? Expanded(flex: 5, child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [

          socialEnable ? SocialLoginWidget(onlySocialLogin: true, showWelcomeText: false, backFromThis: backFromThis) : const SizedBox(),

          onOtpViewClick != null ? Container(
            height: 50,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
              boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(2, 2))],
            ),
            child: CustomInkWell(
              onTap: onOtpViewClick!,
              radius: Dimensions.radiusDefault,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset(Images.otp, height: 20, width: 20),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Text('otp_sign_in'.tr, style: robotoMedium.copyWith()),
                ]),
              ),
            ),
          ) : const SizedBox(),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('do_not_have_account'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

            InkWell(
              onTap: () {
                Get.back();
                Get.dialog(
                  SizedBox(
                    width: 700,
                    child: Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                      backgroundColor: Theme.of(context).cardColor,
                      insetPadding: EdgeInsets.zero,
                      child: const SignUpWidget(),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                child: Text('sign_up'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
              ),
            ),
          ]),
        ])) : const SizedBox(),

      ]),
    );
  }
}
