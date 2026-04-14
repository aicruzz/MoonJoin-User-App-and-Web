import 'dart:math' as math;

import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/checkout/screens/digital_payment_failed_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderSuccessfulScreen extends StatefulWidget {
  final String? orderID;
  final String? contactPersonNumber;
  final bool? createAccount;
  final String guestId;
  const OrderSuccessfulScreen(
      {super.key,
      required this.orderID,
      this.contactPersonNumber,
      this.createAccount = false,
      required this.guestId});

  @override
  State<OrderSuccessfulScreen> createState() => _OrderSuccessfulScreenState();
}

class _OrderSuccessfulScreenState extends State<OrderSuccessfulScreen>
    with TickerProviderStateMixin {
  String? orderId;

  late AnimationController _pulseController;
  late AnimationController _checkController;
  late AnimationController _slideController;
  late AnimationController _staggerController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _checkAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    orderId = widget.orderID!;
    if (widget.orderID != null) {
      if (widget.orderID!.contains('?')) {
        var parts = widget.orderID!.split('?');
        String id = parts[0].trim();
        orderId = id;
      }
    }

    if (GetPlatform.isWeb) {
      Get.find<OrderController>().getPaymentFailedDetails(orderId);
    } else if (!widget.createAccount! && !GetPlatform.isWeb) {
      OrderController orderController = Get.find<OrderController>();

      Get.find<OrderController>()
          .trackOrder(orderId.toString(), null, false,
              contactNumber: widget.contactPersonNumber)
          .then((v) {
        if (orderController.trackModel != null) {
          bool success = orderController.trackModel!.paymentStatus == 'paid' ||
              orderController.trackModel!.paymentMethod == 'cash_on_delivery' ||
              orderController.trackModel!.paymentMethod == 'partial_payment' ||
              orderController.trackModel!.paymentMethod == 'wallet';

          if (!success &&
              !Get.isDialogOpen! &&
              orderController.trackModel!.orderStatus != 'canceled' &&
              Get.currentRoute.startsWith(RouteHelper.orderSuccess)) {
            Get.find<OrderController>().getPaymentFailedDetails(orderId);
          }
        }
      });
    }

    // Pulsing ring animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Check-mark draw animation
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    // Slide-up animation for content
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Stagger fade for bottom content
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeIn,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _checkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await Get.offAllNamed(RouteHelper.getInitialRoute());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: ResponsiveHelper.isDesktop(context)
            ? const WebMenuBar()
            : null,
        endDrawer: const MenuDrawer(),
        endDrawerEnableOpenDragGesture: false,
        body: GetBuilder<OrderController>(builder: (orderController) {
          double total = 0;
          bool success = true;
          bool parcel = false;
          bool takeAway = false;

          if (orderController.trackModel != null) {
            total = ((orderController.trackModel!.orderAmount! / 100) *
                Get.find<SplashController>()
                    .configModel!
                    .loyaltyPointItemPurchasePoint!);
            success =
                orderController.trackModel!.paymentStatus == 'paid' ||
                    orderController.trackModel!.paymentMethod ==
                        'cash_on_delivery' ||
                    orderController.trackModel!.paymentMethod ==
                        'partial_payment' ||
                    orderController.trackModel!.paymentMethod == 'wallet';
            parcel = orderController.trackModel!.orderType == 'parcel';
            takeAway = orderController.trackModel!.orderType == 'take_away';
          }

          if (orderController.paymentModel != null && GetPlatform.isWeb) {
            success =
                orderController.paymentModel!.paymentStatus == 'paid' ||
                    orderController.paymentModel!.paymentMethod ==
                        'cash_on_delivery' ||
                    orderController.paymentModel!.paymentMethod == 'wallet';
            total = ((orderController.paymentModel!.orderAmount! / 100) *
                Get.find<SplashController>()
                    .configModel!
                    .loyaltyPointItemPurchasePoint!);
            parcel = orderController.paymentModel!.orderType == 'parcel';
            takeAway =
                orderController.paymentModel!.orderType == 'take_away';
          }

          if (GetPlatform.isWeb) {
            return orderController.paymentModel != null
                ? SingleChildScrollView(
                    child: FooterView(
                      child: SizedBox(
                        width: Dimensions.webMaxWidth,
                        child: success
                            ? _buildSuccessContent(
                                total: total,
                                parcel: parcel,
                                takeAway: takeAway,
                                success: success)
                            : PaymentIncompleteView(),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator());
          }

          return orderController.trackModel != null || widget.createAccount!
              ? _buildSuccessContent(
                  total: total,
                  parcel: parcel,
                  takeAway: takeAway,
                  success: success)
              : const Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }

  Widget _buildSuccessContent({
    required double total,
    required bool parcel,
    required bool takeAway,
    required bool success,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Get.find<ThemeController>().darkTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1A2E22),
                  const Color(0xFF0F1A14),
                ]
              : [
                  primaryColor.withValues(alpha: 0.06),
                  Colors.white,
                  Colors.white,
                ],
        ),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ── Animated Success Badge ──────────────────────────────
                  _buildSuccessIcon(success: success, primaryColor: primaryColor),

                  const SizedBox(height: 32),

                  // ── Title & Subtitle ────────────────────────────────────
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _slideController,
                      child: Column(
                        children: [
                          Text(
                            success
                                ? parcel
                                    ? 'you_placed_the_parcel_request_successfully'.tr
                                    : 'order_placed_successfully'.tr
                                : 'your_order_is_failed_to_place'.tr,
                            style: robotoBold.copyWith(
                              fontSize: 22,
                              color: success ? primaryColor : const Color(0xFFE84D4F),
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            success
                                ? parcel
                                    ? 'your_parcel_request_is_placed_successfully'.tr
                                    : takeAway
                                        ? 'thank_you_for_your_order'.tr
                                        : 'your_order_is_placed_successfully'.tr
                                : 'your_order_is_failed_to_place_because'.tr,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).disabledColor,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Order ID Card ───────────────────────────────────────
                  if (orderId != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildOrderIdCard(
                          primaryColor: primaryColor, isDark: isDark),
                    ),

                  const SizedBox(height: 24),

                  // ── Delivery Steps ──────────────────────────────────────
                  if (success)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildDeliverySteps(
                            primaryColor: primaryColor, isDark: isDark),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Loyalty Points Banner ───────────────────────────────
                  if (success &&
                      Get.find<SplashController>()
                              .configModel!
                              .loyaltyPointStatus ==
                          1 &&
                      total.floor() > 0 &&
                      AuthHelper.isLoggedIn())
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildLoyaltyBanner(
                          total: total,
                          primaryColor: primaryColor,
                          isDark: isDark),
                    ),

                  // ── Create Account Notice ────────────────────────────────
                  if (widget.createAccount!)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: Dimensions.paddingSizeSmall),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'and_create_account_successfully'.tr,
                              style: robotoMedium,
                            ),
                            InkWell(
                              onTap: () {
                                if (ResponsiveHelper.isDesktop(context)) {
                                  Get.dialog(const Center(
                                      child: AuthDialogWidget(
                                          exitFromApp: false,
                                          backFromThis: false)));
                                } else {
                                  Get.toNamed(RouteHelper.getSignInRoute(
                                      RouteHelper.splash));
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeExtraSmall),
                                child: Text('sign_in'.tr,
                                    style: robotoMedium.copyWith(
                                        color: primaryColor)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Action Buttons ──────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildActionButtons(
                        success: success,
                        total: total,
                        primaryColor: primaryColor,
                        isDark: isDark),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Animated Success / Failure Icon ────────────────────────────────────────
  Widget _buildSuccessIcon(
      {required bool success, required Color primaryColor}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (success ? primaryColor : const Color(0xFFE84D4F))
                      .withValues(alpha: 0.08),
                ),
              ),
            ),
            // Mid ring
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (success ? primaryColor : const Color(0xFFE84D4F))
                    .withValues(alpha: 0.14),
              ),
            ),
            // Core circle
            ScaleTransition(
              scale: _checkAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: success
                        ? [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.75),
                          ]
                        : [
                            const Color(0xFFE84D4F),
                            const Color(0xFFFF6B6B),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (success ? primaryColor : const Color(0xFFE84D4F))
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  success ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Order ID Info Card ──────────────────────────────────────────────────────
  Widget _buildOrderIdCard(
      {required Color primaryColor, required bool isDark}) {
    final bg = isDark
        ? const Color(0xFF1E2D24)
        : primaryColor.withValues(alpha: 0.04);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_rounded,
                color: primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'order_id'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  '#$orderId',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'confirmed'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delivery Step Tracker ───────────────────────────────────────────────────
  Widget _buildDeliverySteps(
      {required Color primaryColor, required bool isDark}) {
    final steps = [
      {'icon': Icons.check_circle_rounded, 'label': 'order_placed'.tr},
      {'icon': Icons.restaurant_rounded, 'label': 'preparing'.tr},
      {'icon': Icons.delivery_dining_rounded, 'label': 'on_the_way'.tr},
      {'icon': Icons.home_rounded, 'label': 'delivered'.tr},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A20) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'delivery_status'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index == 0;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? primaryColor
                                      : isDark
                                          ? const Color(0xFF2A3D30)
                                          : const Color(0xFFF0F0F0),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: primaryColor.withValues(
                                                alpha: 0.35 *
                                                    _pulseAnimation.value),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  steps[index]['icon'] as IconData,
                                  color: isActive
                                      ? Colors.white
                                      : Theme.of(context).disabledColor,
                                  size: 18,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            steps[index]['label'] as String,
                            style: robotoRegular.copyWith(
                              fontSize: 10,
                              color: isActive
                                  ? primaryColor
                                  : Theme.of(context).disabledColor,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withValues(alpha: 0.7),
                                primaryColor.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Loyalty Points Banner ───────────────────────────────────────────────────
  Widget _buildLoyaltyBanner(
      {required double total,
      required Color primaryColor,
      required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            isDark ? Images.congratulationDark : Images.congratulationLight,
            width: 48,
            height: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'congratulations'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${'you_have_earned'.tr} ${total.floor()} ${'points_it_will_add_to'.tr}',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────────────────────
  Widget _buildActionButtons({
    required bool success,
    required double total,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Column(
      children: [
        // Primary CTA – Back to Home
        SizedBox(
          width: ResponsiveHelper.isDesktop(context)
              ? 360
              : double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              if (AuthHelper.isLoggedIn()) {
                Get.find<AuthController>()
                    .saveEarningPoint(total.toStringAsFixed(0));
              }
              Get.offAllNamed(RouteHelper.getInitialRoute());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: primaryColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'back_to_home'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary CTA – Track Order (only if guest and has order ID)
        if (AuthHelper.isGuestLoggedIn() && orderId != null)
          SizedBox(
            width: ResponsiveHelper.isDesktop(context)
                ? 360
                : double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                Get.toNamed(
                  RouteHelper.getOrderTrackingRoute(int.tryParse(orderId ?? ''), widget.contactPersonNumber),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(
                  color: primaryColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'track_order'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
