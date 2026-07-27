import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/foundation/auth_foundation.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/features/auth/screens/new_user_setup_screen.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/existing_user_bottom_sheet.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class SocialLoginWidget extends StatelessWidget {
  final bool onlySocialLogin;
  final bool showWelcomeText;
  final Function()? onOtpViewClick;
  final bool backFromThis;
  const SocialLoginWidget({super.key, this.onlySocialLogin = false, this.showWelcomeText = true, this.onOtpViewClick, required this.backFromThis});

  @override
  Widget build(BuildContext context) {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    bool canAppleLogin = Get.find<SplashController>().configModel!.appleLogin!.isNotEmpty && Get.find<SplashController>().configModel!.appleLogin![0].status!
    && !GetPlatform.isAndroid;

    bool canGoogleAndFacebookLogin = Get.find<SplashController>().configModel!.socialLogin!.isNotEmpty && (Get.find<SplashController>().configModel!.socialLogin![0].status!
        || Get.find<SplashController>().configModel!.socialLogin![1].status!);

    bool googleLoginActive = Get.find<SplashController>().configModel!.socialLogin![0].status! && Get.find<SplashController>().configModel!.centralizeLoginSetup!.socialLoginStatus!
    && Get.find<SplashController>().configModel!.centralizeLoginSetup!.googleLoginStatus!;

    bool facebookLoginActive = Get.find<SplashController>().configModel!.socialLogin![1].status! && Get.find<SplashController>().configModel!.centralizeLoginSetup!.socialLoginStatus!
    && Get.find<SplashController>().configModel!.centralizeLoginSetup!.facebookLoginStatus!;

    bool appleLoginActive = canAppleLogin && Get.find<SplashController>().configModel!.centralizeLoginSetup!.socialLoginStatus!
    && Get.find<SplashController>().configModel!.centralizeLoginSetup!.appleLoginStatus!;

    if(onlySocialLogin) {
      // MoonJoin 9C-2: full-width AuthSocialButton pills (frozen foundation).
      // SDK calls, config gates and OTP link behavior preserved exactly.
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          canGoogleAndFacebookLogin ? Column(children: [

            showWelcomeText ? Text('${'welcome_to'.tr} ${AppConstants.appName}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)) : const SizedBox(),
            SizedBox(height: showWelcomeText ? Dimensions.paddingSizeLarge : 0),

            if(googleLoginActive) ...[
              AuthSocialButton(iconPath: Images.google, label: 'continue_with_google'.tr, fullWidth: true, onTap: () => _googleLogin(googleSignIn)),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],

            if(facebookLoginActive) ...[
              AuthSocialButton(iconPath: Images.socialFacebook, label: 'continue_with_facebook'.tr, fullWidth: true, onTap: () => _facebookLogin()),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],

            if(appleLoginActive) ...[
              AuthSocialButton(iconPath: Images.appleLogo, label: 'continue_with_apple'.tr, fullWidth: true, onTap: () => _appleLogin()),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],

          ]) : const SizedBox(),

          onOtpViewClick != null ? Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtremeLarge),
            child: AuthSocialButton(iconPath: Images.otp, label: 'otp_sign_in'.tr, fullWidth: true, onTap: onOtpViewClick!),
          ) : const SizedBox(),
        ],
      );
    }

    // MoonJoin 9C-2: divider + horizontal AuthSocialButton pills (frozen
    // foundation). Provider order Google · Apple · Facebook (approved design);
    // each only renders when its admin config gate is active. SDK calls and the
    // desktop Get.back() behavior are preserved exactly.
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final List<Widget> socialButtons = [
      if(googleLoginActive)
        AuthSocialButton(iconPath: Images.google, label: 'google'.tr, fullWidth: true, onTap: () {
          if(isDesktop) { Get.back(); }
          _googleLogin(googleSignIn);
        }),
      if(appleLoginActive)
        AuthSocialButton(iconPath: Images.appleLogo, label: 'apple'.tr, fullWidth: true, onTap: () {
          if(isDesktop) { Get.back(); }
          _appleLogin();
        }),
      if(facebookLoginActive)
        AuthSocialButton(iconPath: Images.facebook2, label: 'facebook'.tr, fullWidth: true, onTap: () {
          if(isDesktop) { Get.back(); }
          _facebookLogin();
        }),
    ];

    return canGoogleAndFacebookLogin || canAppleLogin ? Column(children: [

      AuthDivider(label: 'or_continue_with'.tr),
      const SizedBox(height: Dimensions.paddingSizeDefault),

      Row(children: [
        for(int i = 0; i < socialButtons.length; i++) ...[
          if(i > 0) const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: socialButtons[i]),
        ],
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),

    ]) : const SizedBox();
  }

  void _googleLogin(GoogleSignIn googleSignIn) async {
    if(kIsWeb) {
      await _googleWebSignIn();

    }else{
      try{
        if(googleSignIn.supportsAuthenticate()) {
          await googleSignIn.initialize(serverClientId: AppConstants.googleServerClientId).then((_) async {

            googleSignIn.signOut();
            GoogleSignInAccount googleAccount = await googleSignIn.authenticate();
            const List<String> scopes = <String>['email'];
            GoogleSignInClientAuthorization? auth = await googleAccount.authorizationClient.authorizationForScopes(scopes);

            SocialLogInBody googleBodyModel = SocialLogInBody(
              email: googleAccount.email, token: auth?.accessToken, uniqueId: googleAccount.id,
              medium: 'google', accessToken: 1, loginType: CentralizeLoginType.social.name,
            );

            Get.find<AuthController>().loginWithSocialMedia(googleBodyModel).then((response) {
              if (response.isSuccess) {
                _processSocialSuccessSetup(response, googleBodyModel, null, null);
              } else {
                showCustomSnackBar(response.message);
              }
            });
          });
        }else {
          debugPrint("Google Sign-In not supported on this device.");
        }
      }catch(e){
        debugPrint('Error in google sign in: $e');
      }
    }
  }

  Future<void> _googleWebSignIn() async {
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await auth.signInWithPopup(googleProvider);

      SocialLogInBody googleBodyModel =  SocialLogInBody(
        uniqueId: userCredential.credential?.accessToken,
        token: userCredential.credential?.accessToken,
        accessToken: 1,
        medium: 'google',
        email: userCredential.user?.email,
        loginType: CentralizeLoginType.social.name,
      );

      Get.find<AuthController>().loginWithSocialMedia(googleBodyModel).then((response) {
        if (response.isSuccess) {
          _processSocialSuccessSetup(response, googleBodyModel, null, null);
        } else {
          showCustomSnackBar(response.message);
        }
      });

    } catch (e) {
      showCustomSnackBar(e.toString());
    }
  }

  void _facebookLogin() async {
    LoginResult result = await FacebookAuth.instance.login(permissions: ["public_profile", "email"]);
    if (result.status == LoginStatus.success) {
      Map userData = await FacebookAuth.instance.getUserData();

      SocialLogInBody facebookBodyModel = SocialLogInBody(
        email: userData['email'], token: result.accessToken!.tokenString, uniqueId: userData['id'],
        medium: 'facebook', loginType: CentralizeLoginType.social.name,
      );

      Get.find<AuthController>().loginWithSocialMedia(facebookBodyModel).then((response) {
        if (response.isSuccess) {
          _processSocialSuccessSetup(response, null, null, facebookBodyModel);
        } else {
          showCustomSnackBar(response.message);
        }
      });
    }
  }

  void _appleLogin() async {
    String clientID = Get.find<SplashController>().configModel!.appleLogin![0].clientId!;
    String redirectURL = Get.find<SplashController>().configModel!.appleLogin![0].redirectUrl!;

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: GetPlatform.isIOS ? null : WebAuthenticationOptions(
        clientId: clientID,
        redirectUri: Uri.parse(redirectURL),
      ),
    );

    SocialLogInBody appleBodyModel = SocialLogInBody(
      email: credential.email, token: credential.authorizationCode, uniqueId: credential.authorizationCode,
      medium: 'apple', loginType: CentralizeLoginType.social.name, platform: GetPlatform.isIOS ? 'flutter_app' : 'flutter_web',
    );

    Get.find<AuthController>().loginWithSocialMedia(appleBodyModel).then((response) {
      if (response.isSuccess) {
        _processSocialSuccessSetup(response, null, appleBodyModel, null);
      } else {
        showCustomSnackBar(response.message);
      }
    });
  }

  Future<void> _processSocialSuccessSetup(ResponseModel response, SocialLogInBody? googleBodyModel, SocialLogInBody? appleBodyModel, SocialLogInBody? facebookBodyModel) async {
    String? email = googleBodyModel != null ? googleBodyModel.email : appleBodyModel != null ? appleBodyModel.email : facebookBodyModel?.email;
    if(response.isSuccess && response.authResponseModel != null && response.authResponseModel!.isExistUser != null) {
      if(appleBodyModel != null) {
        email = response.authResponseModel!.email;
        appleBodyModel.email = email;
      }
      if(ResponsiveHelper.isDesktop(Get.context)) {
        Get.back();
        Get.dialog(Center(
          child: ExistingUserBottomSheet(
            userModel: response.authResponseModel!.isExistUser!, email: email, loginType: CentralizeLoginType.social.name,
            socialLogInBodyModel: googleBodyModel ?? appleBodyModel ?? facebookBodyModel, backFromThis: backFromThis,
          ),
        ));
      } else {
        Get.bottomSheet(ExistingUserBottomSheet(
          userModel: response.authResponseModel!.isExistUser!, loginType: CentralizeLoginType.social.name,
          socialLogInBodyModel: googleBodyModel ?? appleBodyModel ?? facebookBodyModel, email: email, backFromThis: backFromThis,
        ));
      }
    } else if(response.isSuccess && response.authResponseModel != null && !response.authResponseModel!.isPersonalInfo!) {

      String? displayName = googleBodyModel != null ? googleBodyModel.email?.split('@')[0] : appleBodyModel != null ? appleBodyModel.email?.split('@')[0] : facebookBodyModel?.email?.split('@')[0];

      if(appleBodyModel != null) {
        email = response.authResponseModel!.email;
      }
      if(ResponsiveHelper.isDesktop(Get.context)){
        Get.back();
        Get.dialog(NewUserSetupScreen(name: displayName ?? '', loginType: CentralizeLoginType.social.name, phone: '', email: email, backFromThis: backFromThis));
      } else {
        Get.toNamed(RouteHelper.getNewUserSetupScreen(name: displayName ?? '', loginType: CentralizeLoginType.social.name, phone: '', email: email, backFromThis: backFromThis));
      }
    } else {
      if(backFromThis) {
        await Get.find<LocationController>().syncZoneData();
        if(ResponsiveHelper.isDesktop(Get.context)){
          Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: false));
        } else {
          Get.back();
        }
      } else {
        Get.find<LocationController>().navigateToLocationScreen('sign-in', offNamed: true);
      }
    }
  }
}
