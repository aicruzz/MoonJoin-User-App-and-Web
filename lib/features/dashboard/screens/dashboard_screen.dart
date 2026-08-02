import 'dart:async';
import 'dart:io';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/common/widgets/login_suggestion_bottomsheet.dart';
import 'package:sixam_mart/features/dashboard/widgets/payment_incomplete_bottomsheet.dart';
import 'package:sixam_mart/features/dashboard/widgets/store_registration_success_bottom_sheet.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/address/screens/address_screen.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/dashboard/widgets/bottom_nav_item_widget.dart';
import 'package:sixam_mart/common/widgets/moonjoin/notifications/moonjoin_unavailable_watcher.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/screens/vehicle_favourite_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_dialog.dart';
import 'package:sixam_mart/features/checkout/widgets/congratulation_dialogue.dart';
import 'package:sixam_mart/features/dashboard/widgets/address_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/favourite/screens/favourite_screen.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/menu/screens/menu_screen.dart';
import 'package:sixam_mart/features/order/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/running_order_view_widget.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final bool fromSplash;
  const DashboardScreen({super.key, required this.pageIndex, this.fromSplash = false});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  PageController? _pageController;
  int _pageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  bool _canExit = GetPlatform.isWeb ? true : false;

  GlobalKey<ExpandableBottomSheetState> key = GlobalKey();


  late bool _isLogin;
  bool active = false;

  @override
  void initState() {
    super.initState();

    _isLogin = AuthHelper.isLoggedIn();

    _showRegistrationSuccessBottomSheet();
    if(!_isLogin && Get.find<SplashController>().showLoginSuggestion() && (GetPlatform.isAndroid || GetPlatform.isIOS)) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        Get.bottomSheet(LoginSuggestionBottomSheet(), isScrollControlled: true).then((v) {
          Get.find<SplashController>().disableLoginSuggestion();
        });
      });
    }

    if(_isLogin){
      if(Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 && Get.find<AuthController>().getEarningPint().isNotEmpty
          && !ResponsiveHelper.isDesktop(Get.context)){
        Future.delayed(const Duration(seconds: 1), () => showAnimatedDialog(Get.context!, const CongratulationDialogue()));
      }
      suggestAddressBottomSheet();
      Get.find<OrderController>().getRunningOrders(1, fromDashboard: true);

      Get.find<SplashController>().getPaymentIncompleteSheetStatus();
      if((Get.find<SplashController>().showPaymentIncompleteBottomSheet && !GetPlatform.isWeb) || (GetPlatform.isWeb && !Get.find<SplashController>().getPaymentIncompleteSheetStatus())) {
        Get.find<OrderController>().getPaymentFailedDetails(null).then((paymentModel) {
          if (paymentModel != null) {
            if(ResponsiveHelper.isDesktop(Get.context)) {
              Get.dialog(Center(child: PaymentIncompleteBottomSheet(paymentModel: paymentModel, fromHome: true)));
            } else {
              Get.bottomSheet(PaymentIncompleteBottomSheet(paymentModel: paymentModel, fromHome: true), isScrollControlled: true);
            }
          }
        });
      }
    }

    _pageIndex = widget.pageIndex;

    _pageController = PageController(initialPage: widget.pageIndex);

    // MoonJoin 4-tab shell: Home · Orders · Favorites · Account.
    // (Cart moved to the header; old Menu relocated into Account = MenuScreen.)
    _screens = [
      const HomeScreen(),
      const OrderScreen(),
      const FavouriteScreen(),
      const MenuScreen(),
    ];
  }

  void _showRegistrationSuccessBottomSheet() {
    bool canShowBottomSheet = Get.find<HomeController>().getRegistrationSuccessfulSharedPref();
    if(canShowBottomSheet) {
      Future.delayed(const Duration(seconds: 1), () {
        ResponsiveHelper.isDesktop(Get.context) ? Get.dialog(const Dialog(child: StoreRegistrationSuccessBottomSheet())).then((value) {
          Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<HomeController>().saveIsStoreRegistrationSharedPref(false);
          setState(() {});
        }) : showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const StoreRegistrationSuccessBottomSheet(),
        ).then((value) {
          Get.find<HomeController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<HomeController>().saveIsStoreRegistrationSharedPref(false);
          setState(() {});
        });
      });
    }
  }

  Future<void> suggestAddressBottomSheet() async {
    active = await Get.find<LocationController>().checkLocationActive();
    if(widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) {
      Future.delayed(const Duration(seconds: 1), () {
        showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const AddressBottomSheetWidget(),
        ).then((value) {
          Get.find<LocationController>().showSuggestedLocation(false);
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return GetBuilder<SplashController>(
      builder: (splashController) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (_pageIndex != 0) {
              _setPage(0);
            } else {
              if(!ResponsiveHelper.isDesktop(context) && Get.find<SplashController>().module != null && Get.find<SplashController>().configModel!.module == null && splashController.moduleList != null && splashController.moduleList!.length != 1) {
                Get.find<SplashController>().setModule(null);
                Get.find<StoreController>().resetStoreData();
              }else {
                if(_canExit) {
                  if (GetPlatform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (GetPlatform.isIOS) {
                    exit(0);
                  }
                }else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  ));
                  _canExit = true;
                  Timer(const Duration(seconds: 2), () {
                    _canExit = false;
                  });
                }
              }
            }
          },
          child: GetBuilder<OrderController>(
            builder: (orderController) {
              List<OrderModel> runningOrder = orderController.runningOrderModel != null ? orderController.runningOrderModel!.orders! : [];

              List<OrderModel> reversOrder =  List.from(runningOrder.reversed);

              return SafeArea(
                top: false, bottom: GetPlatform.isAndroid,
                child: Scaffold(
                  key: _scaffoldKey,
                  body: ExpandableBottomSheet(
                    background: Stack(children: [
                      // Invisible: state-reactive MoonJoin unavailable notification —
                      // presents the frozen banner off the SAME OrderController data as
                      // the Home unavailable card (single source of truth). Zero layout.
                      const MoonJoinUnavailableWatcher(),
                      PageView.builder(
                          controller: _pageController,
                          itemCount: _screens.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _screens[index];
                          },
                        ),

                        ResponsiveHelper.isDesktop(context) || keyboardVisible ? const SizedBox() : Align(
                          alignment: Alignment.bottomCenter,
                          child: GetBuilder<SplashController>(
                            builder: (splashController) {
                              bool isParcel = splashController.module != null && splashController.configModel!.moduleConfig!.module!.isParcel!;
                              bool isTaxiWithCache = ((splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.taxi) || (splashController.cacheModule != null && splashController.cacheModule!.moduleType.toString() == AppConstants.taxi)) && TaxiHelper.haveTaxiModule();
                              bool isTaxi = (splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.taxi);
                              isParcel = isParcel && !isTaxiWithCache;

                              // MoonJoin 4-tab order: Home(0) · Orders(1) · Favorites(2) · Account(3).
                              // Module-aware content is preserved: taxi shows Trips/Wishlist,
                              // parcel keeps its Address manager under the Favorites slot.
                              _screens = [
                                const HomeScreen(),
                                OrderScreen(index: isTaxi ? 1 : 0),
                                isTaxi ? const VehicleFavouriteScreen()
                                    : isParcel ? const AddressScreen(fromDashboard: true)
                                    : const FavouriteScreen(),
                                const MenuScreen(),
                              ];
                              return Container(
                                width: size.width, height: GetPlatform.isIOS ? 80 : 65,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                                ),
                                child: ResponsiveHelper.isDesktop(context) ? const SizedBox() : (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) ? const SizedBox()
                                  : (orderController.showBottomSheet && orderController.runningOrderModel != null && orderController.runningOrderModel!.orders!.isNotEmpty && _isLogin) ? const SizedBox() : Center(
                                    child: SizedBox(
                                        width: size.width, height: 80,
                                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                          BottomNavItemWidget(
                                            title: 'home'.tr, selectedIcon: Icons.home_rounded,
                                            unselectedIcon: Icons.home_outlined, isSelected: _pageIndex == 0,
                                            onTap: () => _setPage(0),
                                          ),
                                          BottomNavItemWidget(
                                            title: isTaxi ? 'trips'.tr : 'orders'.tr, selectedIcon: Icons.shopping_bag, unselectedIcon: Icons.shopping_bag_outlined,
                                            isSelected: _pageIndex == 1, onTap: () => _setPage(1),
                                          ),
                                          BottomNavItemWidget(
                                            title: isTaxi ? 'wishlist'.tr : isParcel ? 'address'.tr : 'favorites'.tr,
                                            selectedIcon: isParcel ? Icons.location_on : Icons.favorite,
                                            unselectedIcon: isParcel ? Icons.location_on_outlined : Icons.favorite_border,
                                            isSelected: _pageIndex == 2, onTap: () => _setPage(2),
                                          ),
                                          BottomNavItemWidget(
                                            title: 'account'.tr, selectedIcon: Icons.person, unselectedIcon: Icons.person_outline,
                                            isSelected: _pageIndex == 3, onTap: () => _setPage(3),
                                          ),
                                        ]),
                                    ),
                                  ),
                              );
                            }
                          ),
                        ),
                      ]),

                    persistentContentHeight: (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active) ? 0 : GetPlatform.isIOS ? 110 : 100,

                    onIsContractedCallback: () {
                      if(!orderController.showOneOrder) {
                        orderController.showOrders();
                      }
                    },
                    onIsExtendedCallback: () {
                      if(orderController.showOneOrder) {
                        orderController.showOrders();
                      }
                    },

                    enableToggle: true,

                    expandableContent: (widget.fromSplash && Get.find<LocationController>().showLocationSuggestion && active && !ResponsiveHelper.isDesktop(context)) ?  const SizedBox()
                    : (ResponsiveHelper.isDesktop(context) || !_isLogin || orderController.runningOrderModel == null
                    || orderController.runningOrderModel!.orders!.isEmpty || !orderController.showBottomSheet) ? const SizedBox()
                    : Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        if(orderController.showBottomSheet){
                          orderController.showRunningOrders();
                        }
                      },
                      child: RunningOrderViewWidget(reversOrder: reversOrder, onOrderTap: () {
                        _setPage(1);
                        if(orderController.showBottomSheet){
                          orderController.showRunningOrders();
                        }
                      }),
                    ),
                  ),
                ),
              );
            }
          ),
        );
      }
    );
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageController!.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });
  }

  Widget trackView(BuildContext context, {required bool status}) {
    return Container(height: 3, decoration: BoxDecoration(color: status ? Theme.of(context).primaryColor
        : Theme.of(context).disabledColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)));
  }


}

