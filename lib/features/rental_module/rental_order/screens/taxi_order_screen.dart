import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/notification/controllers/notification_controller.dart';
import 'package:moonjoin/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:moonjoin/features/rental_module/rental_order/widgets/taxi_guest_track_order_input_view_widget.dart';
import 'package:moonjoin/features/rental_module/rental_order/widgets/trip_order_view_widget.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// Rental **Trips / Stay** list (Car design `my_trip.png`, Apartment
/// `my_booking_history.png` — same page, wording differs). Presentation-only
/// redesign: same controller, same `getTripList` calls, same guest-track fallback.
/// `fromApartment` (additive, default false → Car wording) is passed by the
/// module-aware bottom nav so the SAME page reads "My Bookings / Upcoming Stays /
/// Booking History" without any duplicate screen.
class TaxiOrderScreen extends StatefulWidget {
  final bool fromApartment;
  const TaxiOrderScreen({super.key, this.fromApartment = false});

  @override
  State<TaxiOrderScreen> createState() => _TaxiOrderScreenState();
}

class _TaxiOrderScreenState extends State<TaxiOrderScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
    _tabController!.addListener(() => setState(() => _tab = _tabController!.index));
    if(AuthHelper.isLoggedIn()) {
      Get.find<TaxiOrderController>().getTripList(1, isRunning: true);
      Get.find<TaxiOrderController>().getTripList(1, isRunning: false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool apt = widget.fromApartment;
    return Scaffold(
      backgroundColor: Color.alphaBlend(
        Theme.of(context).disabledColor.withValues(alpha: 0.06), Theme.of(context).cardColor),
      body: AuthHelper.isLoggedIn() ? SafeArea(child: Column(children: [

        // Header — title, subtitle, notification bell
        Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
          child: Row(children: [
            Expanded(child: Column(children: [
              Text((apt ? 'my_bookings' : 'my_trips').tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
              const SizedBox(height: 2),
              Text((apt ? 'view_and_manage_your_bookings' : 'view_and_manage_your_trips').tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ])),
            GetBuilder<NotificationController>(builder: (nc) => InkWell(
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
            )),
          ]),
        ),

        // Segmented control — Running / History with live counts
        _segmented(context, apt),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Expanded(child: TabBarView(
          controller: _tabController,
          children: const [
            TripOrderViewWidget(isRunning: true),
            TripOrderViewWidget(isRunning: false),
          ],
        )),

      ])) : const TaxiGuestTrackOrderInputViewWidget(),
    );
  }

  Widget _segmented(BuildContext context, bool apt) {
    return GetBuilder<TaxiOrderController>(builder: (c) {
      final int runningCount = c.tripModel?.totalSize ?? 0;
      final int historyCount = c.tripHistoryModel?.totalSize ?? 0;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(children: [
          _segTab(context, 0, Icons.speed_outlined, (apt ? 'upcoming_stays' : 'running_trips').tr, runningCount),
          _segTab(context, 1, Icons.history, (apt ? 'booking_history' : 'trip_history').tr, historyCount),
        ]),
      );
    });
  }

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
}
