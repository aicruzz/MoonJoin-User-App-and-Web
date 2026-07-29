import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_page_header.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/favourite/widgets/fav_item_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  FavouriteScreenState createState() => FavouriteScreenState();
}

class FavouriteScreenState extends State<FavouriteScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);

    initCall();
  }

  void initCall(){
    if(AuthHelper.isLoggedIn()) {
      Get.find<FavouriteController>().getFavouriteList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      // Mobile → premium MoonJoin ProfilePageHeader inside the body; desktop keeps
      // the legacy CustomAppBar. Bottom-nav tab → no back button.
      appBar: isDesktop ? CustomAppBar(title: 'favourite'.tr, backButton: false) : null,
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: AuthHelper.isLoggedIn()
          ? (isDesktop ? _desktopBody(context) : _mobileBody(context))
          : NotLoggedInScreen(callBack: (value){
              initCall();
              setState(() {});
            }),
    );
  }

  // MoonJoin Premium Favorites (mobile). Presentation only: green
  // ProfilePageHeader + MoonJoin segmented pill (Items / Stores|Restaurants) +
  // the frozen FavItemViewWidget list. TabController / TabBarView semantics,
  // pull-to-refresh, wishlist loading and guest guard all preserved.
  Widget _mobileBody(BuildContext context) {
    return Column(children: [

      ProfilePageHeader(title: 'favourite'.tr, showBack: false),

      Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall),
        child: _segmentedControl(context),
      ),

      Expanded(child: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          FavItemViewWidget(isStore: false),
          FavItemViewWidget(isStore: true),
        ],
      )),

    ]);
  }

  // MoonJoin segmented pill built on the existing TabBar → identical TabController
  // wiring, premium look (rounded green selected segment).
  Widget _segmentedControl(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).hintColor,
        labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
        unselectedLabelStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
        tabs: [
          Tab(text: 'item'.tr),
          Tab(text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
              ? 'restaurants'.tr : 'stores'.tr),
        ],
      ),
    );
  }

  // Desktop / web layout — legacy presentation preserved.
  Widget _desktopBody(BuildContext context) {
    return SafeArea(child: Column(children: [

      WebScreenTitleWidget(title: 'favourite'.tr),

      SizedBox(
        width: Dimensions.webMaxWidth,
        child: Container(
          width: Dimensions.webMaxWidth,
          color: Theme.of(context).cardColor,
          alignment: Alignment.bottomLeft,
          child: TabBar(
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            controller: _tabController,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).disabledColor,
            unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
            labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
            tabs: [
              Tab(text: 'item'.tr),
              Tab(text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                  ? 'restaurants'.tr : 'stores'.tr),
            ],
          ),
        ),
      ),

      Expanded(child: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          FavItemViewWidget(isStore: false),
          FavItemViewWidget(isStore: true),
        ],
      )),

    ]));
  }
}
