import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/checkout/screens/digital_payment_failed_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_button.dart';
import 'package:sixam_mart/common/widgets/moonjoin/wavy_header.dart';
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

  late AnimationController _checkController;
  late AnimationController _slideController;
  late AnimationController _staggerController;

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
        backgroundColor: const Color(0xFFF6F8F0),
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

  // ─── Success layout (matches Active Figma `order_success`) ───────────────────
  Widget _buildSuccessContent({
    required double total,
    required bool parcel,
    required bool takeAway,
    required bool success,
  }) {
    if (!success) return _buildFailureContent();

    final Color primaryColor = Theme.of(context).primaryColor;
    final OrderModel? order = Get.find<OrderController>().trackModel;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
          child: Column(children: [

            _buildHero(primaryColor: primaryColor, parcel: parcel, takeAway: takeAway),

            Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(children: [

                  _buildOrderSummaryCard(order: order, primaryColor: primaryColor),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  MoonjoinButton(
                    text: 'track_order'.tr,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Get.toNamed(RouteHelper.getOrderTrackingRoute(
                        int.tryParse(orderId ?? ''), widget.contactPersonNumber)),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  MoonjoinButton(
                    text: 'continue_shopping'.tr,
                    type: MoonjoinButtonType.outline,
                    icon: Icons.shopping_bag_outlined,
                    onPressed: () {
                      if (AuthHelper.isLoggedIn()) {
                        Get.find<AuthController>()
                            .saveEarningPoint(total.toStringAsFixed(0));
                      }
                      Get.offAllNamed(RouteHelper.getInitialRoute());
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  if (widget.createAccount!) _buildCreateAccountNotice(primaryColor),

                  _buildInviteBanner(primaryColor: primaryColor),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  _buildTrustBadges(primaryColor: primaryColor),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Green hero: illustration + title + subtitle over a wavy header ──────────
  Widget _buildHero({
    required Color primaryColor,
    required bool parcel,
    required bool takeAway,
  }) {
    final double topPad = MediaQuery.of(context).padding.top;
    final double heroHeight = topPad + 396;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(children: [
        WavyHeader(height: heroHeight, color: primaryColor),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(
                top: topPad + Dimensions.paddingSizeSmall,
                left: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeDefault),
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Get.offAllNamed(RouteHelper.getInitialRoute()),
                  borderRadius: BorderRadius.circular(30),
                  child: const Padding(
                    padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              ScaleTransition(
                scale: _checkAnimation,
                child: Image.asset(Images.orderSuccessHero,
                    height: 168, fit: BoxFit.contain),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _slideController,
                  child: Column(children: [
                    Text(
                      parcel
                          ? 'you_placed_the_parcel_request_successfully'.tr
                          : 'order_placed_successfully'.tr,
                      style: robotoBold.copyWith(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text(
                      parcel
                          ? 'your_parcel_request_is_placed_successfully'.tr
                          : takeAway
                              ? 'thank_you_for_your_order'.tr
                              : 'your_order_is_placed_successfully'.tr,
                      style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.4),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── Order Summary card ──────────────────────────────────────────────────────
  Widget _buildOrderSummaryCard(
      {required OrderModel? order, required Color primaryColor}) {
    final String dateStr =
        (order?.createdAt != null && order!.createdAt!.isNotEmpty)
            ? _safeDate(order.createdAt!)
            : '';
    final String methodStr =
        (order?.paymentMethod != null && order!.paymentMethod!.isNotEmpty)
            ? order.paymentMethod!.tr
            : '';
    // Only a genuinely scheduled order shows a delivery time; instant orders read "As soon as possible".
    final String deliveryStr =
        (order?.scheduled == 1 && order?.scheduleAt != null && order!.scheduleAt!.isNotEmpty)
            ? _safeDate(order.scheduleAt!)
            : 'as_soon_as_possible'.tr;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [
          BoxShadow(color: primaryColor.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('order_summary'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Divider(
              height: 1,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        ),

        if (orderId != null) _summaryRow('order_id'.tr, '#$orderId', primaryColor),
        if (dateStr.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _summaryRow('date'.tr, dateStr, null),
        ],
        if (methodStr.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _summaryRow('payment_method'.tr, methodStr, null),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Divider(
              height: 1,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        ),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('total_amount'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          Flexible(
            child: Text(
              PriceConverter.convertPrice(order?.orderAmount ?? 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge, color: primaryColor),
            ),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Estimated Delivery sub-card
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(children: [
            Image.asset(Images.orderSuccessScooter,
                width: 52, height: 44, fit: BoxFit.contain),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('estimated_delivery'.tr,
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor)),
                    const SizedBox(height: 2),
                    Text(deliveryStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault)),
                  ]),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            InkWell(
              onTap: () => Get.toNamed(RouteHelper.getOrderTrackingRoute(
                  int.tryParse(orderId ?? ''), widget.contactPersonNumber)),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('track_order'.tr,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall, color: primaryColor)),
                  const SizedBox(width: 3),
                  Icon(Icons.location_on_outlined, size: 14, color: primaryColor),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _summaryRow(String label, String value, Color? valueColor) {
    return Row(children: [
      Text(label,
          style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).disabledColor)),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
          style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    ]);
  }

  String _safeDate(String iso) {
    try {
      return DateConverter.isoStringToReadableString(iso);
    } catch (_) {
      return iso;
    }
  }

  // ─── Invite / refer banner ───────────────────────────────────────────────────
  Widget _buildInviteBanner({required Color primaryColor}) {
    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.getReferAndEarnRoute()),
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(children: [
          Image.asset(Images.orderSuccessGift,
              width: 52, height: 52, fit: BoxFit.contain),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('invite_your_friends_and_get_rewards'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault)),
                  const SizedBox(height: 2),
                  Text('share_and_earn_exciting_rewards'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).disabledColor)),
                ]),
          ),
          Icon(Icons.chevron_right, color: Theme.of(context).disabledColor),
        ]),
      ),
    );
  }

  // ─── Trust badges row ────────────────────────────────────────────────────────
  Widget _buildTrustBadges({required Color primaryColor}) {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.verified_user_outlined, 'l1': 'safe'.tr, 'l2': 'payments'.tr},
      {'icon': Icons.headset_mic_outlined, 'l1': '24_7'.tr, 'l2': 'support'.tr},
      {'icon': Icons.workspace_premium_outlined, 'l1': 'best'.tr, 'l2': 'quality'.tr},
      {'icon': Icons.access_time_rounded, 'l1': 'on_time'.tr, 'l2': 'delivery'.tr},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [
          BoxShadow(color: primaryColor.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeDefault,
          horizontal: Dimensions.paddingSizeExtraSmall),
      child: Row(
          children: List.generate(items.length, (i) {
        final it = items[i];
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(it['icon'] as IconData, color: primaryColor, size: 22),
                const SizedBox(height: 6),
                Text(it['l1'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall)),
                Text(it['l2'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor)),
              ]),
            ),
            if (i != items.length - 1)
              Container(
                  width: 1,
                  height: 34,
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
          ]),
        );
      })),
    );
  }

  // ─── Guest "create account" notice (reused from the original flow) ───────────
  Widget _buildCreateAccountNotice(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('and_create_account_successfully'.tr, style: robotoMedium),
        InkWell(
          onTap: () {
            if (ResponsiveHelper.isDesktop(context)) {
              Get.dialog(const Center(
                  child: AuthDialogWidget(
                      exitFromApp: false, backFromThis: false)));
            } else {
              Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Text('sign_in'.tr,
                style: robotoMedium.copyWith(color: primaryColor)),
          ),
        ),
      ]),
    );
  }

  // ─── Failure state (payment not completed) ──────────────────────────────────
  Widget _buildFailureContent() {
    const Color err = Color(0xFFE84D4F);
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 80),
            ScaleTransition(
              scale: _checkAnimation,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: err.withValues(alpha: 0.12)),
                child: const Icon(Icons.close_rounded, color: err, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Text('your_order_is_failed_to_place'.tr,
                style: robotoBold.copyWith(fontSize: 22, color: err),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('your_order_is_failed_to_place_because'.tr,
                style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).disabledColor,
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            MoonjoinButton(
              text: 'back_to_home'.tr,
              icon: Icons.home_rounded,
              onPressed: () => Get.offAllNamed(RouteHelper.getInitialRoute()),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}
