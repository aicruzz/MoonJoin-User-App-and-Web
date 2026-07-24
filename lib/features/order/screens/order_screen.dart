import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/provider_adapter/rental_apartment_adapter.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/trip_order_view_widget.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/order/widgets/guest_track_order_input_view_widget.dart';
import 'package:sixam_mart/features/order/widgets/order_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// **Shared Orders / Trips / Stay wrapper** — ONE premium MoonJoin page for every
/// module. Module-aware wording only (business logic untouched):
///   • storefront modules (Food/Grocery/Pharmacy/Ecommerce) → **Orders**
///   • Rental module, car bookings → **Trips**
///   • Rental module, apartment bookings → **Stay** (auto-derived from the real
///     trips' category — Car & Apt share ONE rental module)
/// Running/History, pagination, refresh, empty states, navigation, controllers and
/// APIs are all the pre-existing production implementation. No duplicate page, no
/// duplicate controller.
class OrderScreen extends StatefulWidget {
  final int? index;
  /// True when the screen is pushed as its own route (e.g. from Profile → My
  /// Orders) rather than shown as the bottom-nav tab — enables a back button.
  final bool fromNavigation;
  const OrderScreen({super.key, this.index = 0, this.fromNavigation = false});

  @override
  OrderScreenState createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoggedIn = AuthHelper.isLoggedIn();
  final List<String> type = ['orders', 'trips'];
  int selectTypeIndex = 0;
  bool haveTaxiModule = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
    _tabController!.addListener(() => setState(() => _tab = _tabController!.index));
    selectTypeIndex = widget.index!;
    haveTaxiModule = TaxiHelper.haveTaxiModule();
    initCall();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void initCall() {
    if(AuthHelper.isLoggedIn()) {
      if(selectTypeIndex == 0) {
        Get.find<OrderController>().getRunningOrders(1);
        Get.find<OrderController>().getHistoryOrders(1);
      } else {
        Get.find<TaxiOrderController>().getTripList(1, isRunning: true);
        Get.find<TaxiOrderController>().getTripList(1, isRunning: false);
      }
    }
  }

  /// Trips vs Stay — derived from the REAL loaded trips (Car & Apt share one
  /// module): predominantly-apartment content reads "Stay"/"My Bookings".
  bool get _isApartmentContext {
    final c = Get.find<TaxiOrderController>();
    final int? aptCatId = RentalApartmentAdapter.apartmentCategoryId(Get.find<TaxiHomeController>().vehicleCategoryModel);
    if(aptCatId == null) return false;
    final List<TripDetailsModel> trips = [...(c.tripModel?.trips ?? []), ...(c.tripHistoryModel?.trips ?? [])];
    if(trips.isEmpty) return false;
    int apt = 0;
    for(final t in trips) {
      final d = t.tripDetails ?? [];
      if(d.isNotEmpty && d.where((x) => x.vehicleDetails?.categoryId == aptCatId).length * 2 > d.length) apt++;
    }
    return apt * 2 > trips.length;
  }

  @override
  Widget build(BuildContext context) {
    _isLoggedIn = AuthHelper.isLoggedIn();

    // Desktop keeps its existing layout untouched.
    if(ResponsiveHelper.isDesktop(context)) return _desktop(context);

    final bool apt = haveTaxiModule && selectTypeIndex == 1 && _isApartmentContext;
    final String pageTitle = selectTypeIndex == 0 ? 'my_orders'.tr : apt ? 'my_bookings'.tr : 'my_trips'.tr;
    final String pageSub = selectTypeIndex == 0 ? 'view_and_manage_your_orders'.tr
        : apt ? 'view_and_manage_your_bookings'.tr : 'view_and_manage_your_trips'.tr;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F0),
      appBar: haveTaxiModule ? null : CustomAppBar(title: 'my_orders'.tr, backButton: widget.fromNavigation),
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(child: GetBuilder<OrderController>(builder: (orderController) {
        return Column(children: [

          // Premium header (rental only shows title/subtitle + module toggle;
          // storefront modules keep the standard app bar above).
          if(haveTaxiModule) Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
            child: Row(children: [
              if(widget.fromNavigation) ...[
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: Icon(Icons.arrow_back_ios_new, size: 20, color: Theme.of(context).textTheme.bodyLarge!.color),
                  ),
                ),
              ],
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pageTitle, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
                const SizedBox(height: 2),
                Text(pageSub, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
              ])),
              _bell(context),
            ]),
          ),

          // Module toggle (Orders / Trips|Stay) — only for the rental module.
          if(haveTaxiModule) Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Row(children: [
              _moduleChip(context, 0, 'orders'.tr),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _moduleChip(context, 1, (_isApartmentContext ? 'stay' : 'trips').tr),
            ]),
          ),

          _isLoggedIn ? Expanded(child: Column(children: [

            const SizedBox(height: Dimensions.paddingSizeSmall),
            _segmented(context, apt),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            selectTypeIndex == 0
                ? Expanded(child: TabBarView(controller: _tabController, children: const [
                    OrderViewWidget(isRunning: true),
                    OrderViewWidget(isRunning: false),
                  ]))
                : Expanded(child: TabBarView(controller: _tabController, children: const [
                    TripOrderViewWidget(isRunning: true),
                    TripOrderViewWidget(isRunning: false),
                  ])),
          ])) : GuestTrackOrderInputViewWidget(selectType: selectTypeIndex),
        ]);
      })),
    );
  }

  Widget _bell(BuildContext context) {
    return GetBuilder<NotificationController>(builder: (nc) => InkWell(
      onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 42, width: 42, alignment: Alignment.center,
        decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
        child: Stack(clipBehavior: Clip.none, children: [
          Icon(Icons.notifications_none, color: Theme.of(context).textTheme.bodyLarge!.color, size: 22),
          if((nc.notificationList?.length ?? 0) > 0) Positioned(right: -1, top: -1, child: Container(
            height: 8, width: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle))),
        ]),
      ),
    ));
  }

  Widget _moduleChip(BuildContext context, int index, String label) {
    final bool selected = selectTypeIndex == index;
    final Color green = Theme.of(context).primaryColor;
    return InkWell(
      onTap: () { setState(() => selectTypeIndex = index); initCall(); },
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: selected ? green : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: selected ? green : Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color)),
      ),
    );
  }

  // Segmented Running/History with live counts (Orders or Trips depending on tab).
  Widget _segmented(BuildContext context, bool apt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(children: [
          _segTab(context, 0, Icons.pending_actions_outlined, (apt ? 'upcoming_stays' : 'running').tr, _runningCount()),
          _segTab(context, 1, Icons.history, (apt ? 'booking_history' : 'history').tr, _historyCount()),
        ]),
      ),
    );
  }

  int _runningCount() => selectTypeIndex == 0
      ? (Get.find<OrderController>().runningOrderModel?.totalSize ?? 0)
      : (Get.find<TaxiOrderController>().tripModel?.totalSize ?? 0);
  int _historyCount() => selectTypeIndex == 0
      ? (Get.find<OrderController>().historyOrderModel?.totalSize ?? 0)
      : (Get.find<TaxiOrderController>().tripHistoryModel?.totalSize ?? 0);

  Widget _segTab(BuildContext context, int index, IconData icon, String label, int count) {
    final bool selected = _tab == index;
    final Color green = Theme.of(context).primaryColor;
    return Expanded(child: InkWell(
      onTap: () => _tabController!.animateTo(index),
      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: selected ? green.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: selected ? green : Theme.of(context).hintColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: (selected ? robotoBold : robotoRegular).copyWith(fontSize: Dimensions.fontSizeSmall, color: selected ? green : Theme.of(context).hintColor))),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Container(
            height: 20, width: 20, alignment: Alignment.center,
            decoration: BoxDecoration(color: selected ? green : Theme.of(context).disabledColor.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Text('$count', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverSmall, color: selected ? Colors.white : Theme.of(context).hintColor)),
          ),
        ]),
      ),
    ));
  }

  // ── Desktop layout preserved (existing behaviour) ──
  Widget _desktop(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(title: 'my_orders'.tr, backButton: true),
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(child: GetBuilder<OrderController>(builder: (orderController) {
        return _isLoggedIn ? Column(children: [
          Container(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Center(child: SizedBox(width: Dimensions.webMaxWidth,
              child: Align(alignment: Alignment.centerLeft,
                child: SizedBox(width: 300,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Theme.of(context).primaryColor, indicatorWeight: 3,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Theme.of(context).disabledColor,
                    unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                    labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                    tabs: [Tab(text: 'running'.tr), Tab(text: 'history'.tr)],
                  ),
                ),
              ),
            )),
          ),
          selectTypeIndex == 0
              ? Expanded(child: TabBarView(controller: _tabController, children: const [
                  OrderViewWidget(isRunning: true), OrderViewWidget(isRunning: false)]))
              : Expanded(child: TabBarView(controller: _tabController, children: const [
                  TripOrderViewWidget(isRunning: true), TripOrderViewWidget(isRunning: false)])),
        ]) : GuestTrackOrderInputViewWidget(selectType: selectTypeIndex);
      })),
    );
  }
}
