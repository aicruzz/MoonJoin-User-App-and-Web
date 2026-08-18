import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/common/widgets/moonjoin/onboarding/moonjoin_onboarding_art.dart';
import 'package:moonjoin/common/widgets/moonjoin/onboarding/moonjoin_moon_phase_progress.dart';
import 'package:moonjoin/helper/address_helper.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A single onboarding story beat — an original MoonJoin "One Orbit" scene
/// (drawn programmatically, no assets) plus its calm headline/support copy.
class _Beat {
  final MoonJoinOnboardingScene scene;
  final String titleKey;
  final String bodyKey;
  const _Beat(this.scene, this.titleKey, this.bodyKey);
}

const List<_Beat> _beats = [
  _Beat(MoonJoinOnboardingScene.arrival, 'onboarding_arrival_title', 'onboarding_arrival_body'),
  _Beat(MoonJoinOnboardingScene.ecosystem, 'onboarding_ecosystem_title', 'onboarding_ecosystem_body'),
  _Beat(MoonJoinOnboardingScene.delivery, 'onboarding_delivery_title', 'onboarding_delivery_body'),
  _Beat(MoonJoinOnboardingScene.resolution, 'onboarding_resolution_title', 'onboarding_resolution_body'),
];

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _ambient;
  int _index = 0;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    // ONE shared calm ambient ticker for every scene (battery friendly).
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 9));
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageController.hasClients && _pageController.page != null) {
      setState(() => _page = _pageController.page!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect Reduce Motion — hold a calm frame instead of looping.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _ambient.value = 0.5;
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _ambient.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _beats.length - 1;

  @override
  Widget build(BuildContext context) {
    final bool desktop = ResponsiveHelper.isDesktop(context);
    final Widget content = Stack(children: [

      // ── Full-bleed living-city art; swiping pages the scene ──
      PageView.builder(
        controller: _pageController,
        itemCount: _beats.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => MoonJoinOnboardingArt(scene: _beats[i].scene, ambient: _ambient),
      ),

      // ── Overlay: Skip (top), copy + progress + CTA (bottom) ──
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _isLast ? 0.0 : 1.0,
                child: TextButton(
                  onPressed: _isLast ? null : _configureToRouteInitialPage,
                  child: Text('skip'.tr, style: robotoMedium.copyWith(color: Colors.white.withValues(alpha: 0.75))),
                ),
              ),
            ),

            const Spacer(),

            // Calm cross-fade of the copy, with a light parallax against the swipe.
            Transform.translate(
              offset: Offset((_index - _page) * 40, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                child: Column(
                  key: ValueKey<int>(_index),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _beats[_index].titleKey.tr,
                      style: robotoBold.copyWith(fontSize: 30, color: Colors.white, height: 1.15, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      _beats[_index].bodyKey.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            MoonJoinMoonPhaseProgress(count: _beats.length, active: _index),

            const SizedBox(height: Dimensions.paddingSizeLarge),

            CustomButton(
              buttonText: _isLast ? 'get_started'.tr : 'next'.tr,
              radius: Dimensions.radiusDefault,
              onPressed: () {
                if (_isLast) {
                  _configureToRouteInitialPage();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 550), curve: Curves.easeInOutCubic,
                  );
                }
              },
            ),

            const SizedBox(height: Dimensions.paddingSizeLarge),
          ]),
        ),
      ),
    ]);

    return Scaffold(
      backgroundColor: MoonJoinOnboardingPalette.bgTop,
      appBar: desktop ? const WebMenuBar() : null,
      body: desktop
          ? Center(child: SizedBox(width: Dimensions.webMaxWidth, child: content))
          : content,
    );
  }

  /// PRESERVED business logic (first-launch gating + exit sequence): disable the
  /// intro so onboarding shows only once, guest-login, then route to the initial
  /// page (if an address exists) or the location screen. Unchanged behaviour.
  void _configureToRouteInitialPage() async {
    Get.find<SplashController>().disableIntro();
    await Get.find<AuthController>().guestLogin();
    if (AddressHelper.getUserAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<LocationController>().navigateToLocationScreen(RouteHelper.onBoarding, offNamed: true).then((v) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_beats.length - 1);
        }
      });
    }
  }
}
