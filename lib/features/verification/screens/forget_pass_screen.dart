import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:moonjoin/features/language/controllers/language_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:moonjoin/features/verification/controllers/verification_controller.dart';
import 'package:moonjoin/features/verification/screens/verification_screen.dart';
import 'package:moonjoin/helper/custom_validator.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/helper/validate_check.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPassScreen extends StatefulWidget {
  final bool fromDialog;
  const ForgetPassScreen({super.key, this.fromDialog = false});

  @override
  State<ForgetPassScreen> createState() => _ForgetPassScreenState();
}

class _ForgetPassScreenState extends State<ForgetPassScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  String? _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  GlobalKey<FormState>? _formKeyLogin;
  bool isEmail = false;
  bool isPhone = false;

  @override
  void initState() {
    super.initState();

    isPhone = (Get.find<SplashController>().configModel!.isSmsActive! || Get.find<SplashController>().configModel!.firebaseOtpVerification!);
    isEmail = Get.find<SplashController>().configModel!.isMailActive!;

    _formKeyLogin = GlobalKey<FormState>();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          FocusScope.of(Get.context!).requestFocus(_numberFocusNode);
        });
      });
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _numberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) return _desktopBody(context);
    return _mobileBody(context);
  }

  // MoonJoin 9C-5: mobile Forgot Password composed from the frozen Auth
  // Foundation (AuthScaffold + AuthHero + AuthCard + AuthInputGroup +
  // AuthPrimaryButton + AuthFooter), matching frozen Sign In / Sign Up /
  // Verification. Both original states are preserved: the request form (when a
  // channel is enabled) and the "channels disabled" fallback. All routing /
  // validation / OTP-request logic lives in _onPressedForgetPass, untouched.
  Widget _mobileBody(BuildContext context) {
    final bool hasChannel = isPhone || isEmail;
    return AuthScaffold(
      onBack: () => Get.back(),
      hero: AuthHero(
        title: hasChannel ? 'forgot_your_password'.tr : 'sorry_something_went_wrong'.tr,
        subtitle: hasChannel
            ? (isPhone ? 'please_enter_the_registered_phone_where_you_want'.tr : 'please_enter_the_registered_email_where_you_want'.tr)
            : 'please_try_again_after_some_time_or_contact_with_our_support_team'.tr,
      ),
      child: AuthCard(
        child: hasChannel ? _requestForm(context) : _fallbackContent(context),
      ),
    );
  }

  // Request-OTP form — the phone / email field, request button, and back-to-login link.
  Widget _requestForm(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [

      Form(
        key: _formKeyLogin,
        child: AuthInputGroup(children: [
          isPhone ? CustomTextField(
            titleText: 'xxx-xxx-xxxxx'.tr,
            controller: _numberController,
            focusNode: _numberFocusNode,
            inputType: TextInputType.phone,
            inputAction: TextInputAction.done,
            isPhone: true,
            onCountryChanged: (CountryCode countryCode) {
              _countryDialCode = countryCode.dialCode;
            },
            countryDialCode: CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code ?? Get.find<LocalizationController>().locale.countryCode,
            onSubmit: (text) => GetPlatform.isWeb ? _onPressedForgetPass(_countryDialCode!) : null,
            labelText: 'phone'.tr,
            validator: (value) => ValidateCheck.validateEmptyText(value, null),
          ) : CustomTextField(
            titleText: 'enter_email'.tr,
            labelText: 'email'.tr,
            showLabelText: true,
            required: true,
            controller: _emailController,
            focusNode: _emailFocusNode,
            inputType: TextInputType.emailAddress,
            inputAction: TextInputAction.done,
            prefixIcon: CupertinoIcons.mail_solid,
            validator: (value) => ValidateCheck.validateEmail(value),
          ),
        ]),
      ),
      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

      GetBuilder<VerificationController>(builder: (verificationController) {
        return GetBuilder<AuthController>(builder: (authController) {
          return AuthPrimaryButton(
            text: 'request_otp'.tr,
            isLoading: verificationController.isLoading || authController.isLoading,
            onPressed: () => _onPressedForgetPass(_countryDialCode!),
          );
        });
      }),
      const SizedBox(height: Dimensions.paddingSizeLarge),

      Text('or'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      AuthFooter(
        leadingText: '${'back_to'.tr} ',
        actionText: 'login_in'.tr,
        onAction: () => Get.back(),
      ),
    ]);
  }

  // "Both SMS and email disabled" fallback — Help & Support + continue-as-guest.
  Widget _fallbackContent(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [

      AuthPrimaryButton(
        text: 'help_and_support'.tr,
        onPressed: () => Get.toNamed(RouteHelper.getSupportRoute()),
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      AuthFooter(
        leadingText: '${'continue_as'.tr} ',
        actionText: 'guest'.tr,
        onAction: () => Get.offAllNamed(RouteHelper.getInitialRoute()),
      ),
    ]);
  }

  // Desktop / web layout — legacy presentation preserved.
  Widget _desktopBody(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: Center(
          child: Container(
            height: widget.fromDialog ? 600 : null,
            width: widget.fromDialog ? 475 : context.width > 700 ? 700 : context.width,
            decoration: context.width > 700 ? BoxDecoration(
              color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ) : null,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.clear),
                  ),
                ),

                (isPhone || isEmail) ? Padding(
                  padding: widget.fromDialog ? const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge) : const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [

                    Image.asset(Images.logo, width: 135),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                      child: Text('forgot_your_password'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge), textAlign: TextAlign.center),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                      child: Text(
                        isPhone ? 'please_enter_the_registered_phone_where_you_want'.tr : 'please_enter_the_registered_email_where_you_want'.tr,
                        style: robotoRegular.copyWith(fontSize: widget.fromDialog ? Dimensions.fontSizeSmall : null, color: Theme.of(context).hintColor), textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtremeLarge),

                    Form(
                      key: _formKeyLogin,
                      child: isPhone ? CustomTextField(
                        titleText: 'xxx-xxx-xxxxx'.tr,
                        controller: _numberController,
                        focusNode: _numberFocusNode,
                        inputType: TextInputType.phone,
                        inputAction: TextInputAction.done,
                        isPhone: true,
                        onCountryChanged: (CountryCode countryCode) {
                          _countryDialCode = countryCode.dialCode;
                        },
                        countryDialCode: CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code ?? Get.find<LocalizationController>().locale.countryCode,
                        onSubmit: (text) => GetPlatform.isWeb ? _onPressedForgetPass(_countryDialCode!) : null,
                        labelText: 'phone'.tr,
                        validator: (value) => ValidateCheck.validateEmptyText(value, null),
                      ) : CustomTextField(
                        titleText: 'enter_email'.tr,
                        labelText: 'email'.tr,
                        showLabelText: true,
                        required: true,
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        inputType: TextInputType.emailAddress,
                        inputAction: TextInputAction.done,
                        prefixIcon: CupertinoIcons.mail_solid,
                        validator: (value) => ValidateCheck.validateEmail(value),
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeExtremeLarge),

                    GetBuilder<VerificationController>(builder: (verificationController) {
                      return GetBuilder<AuthController>(builder: (authController) {
                        return CustomButton(
                          radius: Dimensions.radiusDefault,
                          buttonText: 'request_otp'.tr,
                          isLoading: verificationController.isLoading || authController.isLoading,
                          onPressed: () => _onPressedForgetPass(_countryDialCode!),
                        );
                      });
                    }),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Text('or'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    RichText(text: TextSpan(children: [
                      TextSpan(
                        text: '${'back_to'.tr} ',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),
                      ),
                      TextSpan(
                        text: 'login_in'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Get.back(),
                      ),
                    ]), textAlign: TextAlign.center, maxLines: 3),

                  ]),
                ) : Padding(
                  padding: widget.fromDialog ? const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge) : const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  child: Column(children: [

                    Image.asset(Images.forgot, height:  widget.fromDialog ? 160 : 220),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                      child: Text('sorry_something_went_wrong'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge), textAlign: TextAlign.center),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                      child: Text(
                        'please_try_again_after_some_time_or_contact_with_our_support_team'.tr,
                        style: robotoRegular.copyWith(fontSize: widget.fromDialog ? Dimensions.fontSizeSmall : null, color: Theme.of(context).hintColor), textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtremeLarge),

                    CustomButton(
                      buttonText: 'help_and_support'.tr,
                      onPressed: () {
                        Get.toNamed(RouteHelper.getSupportRoute());
                      }
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    RichText(text: TextSpan(children: [
                      TextSpan(
                        text: '${'continue_as'.tr} ',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                      ),
                      TextSpan(
                        text: 'guest'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Get.offAllNamed(RouteHelper.getInitialRoute()),
                      ),
                    ]), textAlign: TextAlign.center, maxLines: 3),

                  ]),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  void _onPressedForgetPass(String countryCode) async {
    String phone = _numberController.text.trim();
    String email = _emailController.text.trim();

    String numberWithCountryCode = countryCode+phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(_formKeyLogin!.currentState!.validate()) {
      if (!phoneValid.isValid && !isEmail) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        Get.find<VerificationController>().forgetPassword(email: email, phone: numberWithCountryCode).then((status) async {
          if (status.isSuccess) {
            if(Get.find<SplashController>().configModel!.centralizeLoginSetup!.phoneVerificationStatus! && Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
              Get.find<AuthController>().firebaseVerifyPhoneNumber(numberWithCountryCode, status.message, '', fromSignUp: false);
            } else {
              if(ResponsiveHelper.isDesktop(Get.context)) {
                Get.back();
                Get.dialog(VerificationScreen(
                  number: numberWithCountryCode, email: email, token: '', fromSignUp: false,
                  fromForgetPassword: true, loginType: '', password: '',
                ));
              } else {
                Get.toNamed(RouteHelper.getVerificationRoute(numberWithCountryCode, email, '', RouteHelper.forgotPassword, '', ''));
              }
            }
          }else {
            showCustomSnackBar(status.message);
          }
        });
      }
    }
  }
}
