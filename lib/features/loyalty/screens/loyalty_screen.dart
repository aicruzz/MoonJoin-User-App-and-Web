import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:moonjoin/features/loyalty/controllers/loyalty_controller.dart';
import 'package:moonjoin/features/loyalty/widgets/loyalty_bottom_sheet_widget.dart';
import 'package:moonjoin/features/loyalty/widgets/loyalty_card_widget.dart';
import 'package:moonjoin/features/loyalty/widgets/loyalty_history_widget.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/not_logged_in_screen.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/common/widgets/web_page_title_widget.dart';

class LoyaltyScreen extends StatefulWidget {
  final bool fromNotification;
  const LoyaltyScreen({super.key, required this.fromNotification});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final ScrollController scrollController = ScrollController();
  final tooltipController = JustTheController();

  @override
  void initState() {
    super.initState();

    initCall();

  }

  void initCall(){
    if(AuthHelper.isLoggedIn()){

      Get.find<ProfileController>().getUserInfo();

      Get.find<LoyaltyController>().getLoyaltyTransactionList('1', false);

      Get.find<LoyaltyController>().setOffset(1);

      scrollController.addListener(() {
        if (scrollController.position.pixels == scrollController.position.maxScrollExtent
            && Get.find<LoyaltyController>().transactionList != null
            && !Get.find<LoyaltyController>().isLoading) {
          int pageSize = (Get.find<LoyaltyController>().popularPageSize! / 10).ceil();
          if (Get.find<LoyaltyController>().offset < pageSize) {
            Get.find<LoyaltyController>().setOffset(Get.find<LoyaltyController>().offset + 1);
            if (kDebugMode) {
              print('end of the page');
            }
            Get.find<LoyaltyController>().showBottomLoader();
            Get.find<LoyaltyController>().getLoyaltyTransactionList(Get.find<LoyaltyController>().offset.toString(), false);
          }
        }
      });
    }
  }
  @override
  void dispose() {
    super.dispose();

    scrollController.dispose();
  }

  void _handleBack() {
    if(widget.fromNotification) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else {
      Get.back();
    }
  }

  void _showConvertDialog() {
    Get.dialog(Dialog(backgroundColor: Colors.transparent, child: LoyaltyBottomSheetWidget(
      amount: Get.find<ProfileController>().userInfoModel!.loyaltyPoint == null ? '0' : Get.find<ProfileController>().userInfoModel!.loyaltyPoint.toString(),
    )));
  }

  Future<void> _refresh() async {
    Get.find<LoyaltyController>().getLoyaltyTransactionList('1', true);
    Get.find<ProfileController>().getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return PopScope(
      canPop:  Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if(widget.fromNotification) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        }else {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
        appBar: isDesktop ? const WebMenuBar() : null,
        body: GetBuilder<ProfileController>(
            builder: (profileController) {
              if(!isLoggedIn) {
                return NotLoggedInScreen(callBack: (value){ initCall(); setState(() {}); });
              }
              if(profileController.userInfoModel == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return isDesktop ? _desktopBody(context) : _mobileBody(context, profileController);
            }
        ),
      ),
    );
  }

  // ── Mobile (MoonJoin) — ProfilePageHeader + points card + history + bottom
  // convert button. Pagination/refresh/back behavior preserved. ──
  Widget _mobileBody(BuildContext context, ProfileController profileController) {
    return Column(children: [
      ProfilePageHeader(title: 'loyalty_points'.tr, onBack: _handleBack),
      Expanded(child: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Column(children: [
            const SizedBox(height: Dimensions.paddingSizeDefault),
            LoyaltyCardWidget(tooltipController: tooltipController),
            const LoyaltyHistoryWidget(),
          ]),
        ),
      )),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: CustomButton(
          buttonText: 'convert_to_wallet_money'.tr,
          icon: Icons.account_balance_wallet_outlined,
          onPressed: _showConvertDialog,
        ),
      )),
    ]);
  }

  // ── Desktop — 2-column (card + stepper | history) preserved; cards aligned to
  // MoonJoin radius. WebMenuBar app bar. ──
  Widget _desktopBody(BuildContext context) {
    return SafeArea(child: RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(children: [
          WebScreenTitleWidget(title: 'loyalty_points'.tr),
          FooterView(child: SizedBox(width: Dimensions.webMaxWidth,
            child: GetBuilder<LoyaltyController>(builder: (loyaltyController) {
              return Padding(
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 4, child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: LoyaltyCardWidget(tooltipController: tooltipController),
                  )),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(flex: 6, child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: const LoyaltyHistoryWidget(),
                  )),
                ]),
              );
            }),
          )),
        ]),
      ),
    ));
  }
}