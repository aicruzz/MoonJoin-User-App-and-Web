import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/rental_module/common/enums/trip_status_enum.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/provider_adapter/rental_apartment_adapter.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/additional_note.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/deliveryman_view.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/vendor_detail_screen.dart';
import 'package:sixam_mart/features/rental_module/widgets/booking_cancel_bottomsheet.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/taxi_payment_bottom_sheet.dart';
import 'package:sixam_mart/features/rental_module/widgets/confirm_booking_request_bottom_sheet.dart';
import 'package:sixam_mart/features/rental_module/widgets/review_bottom_sheet.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../util/dimensions.dart';
import '../../../../util/styles.dart';

/// **Rental Trip / Booking Details** (Car design `ui-designs/Car_Rental/trip_details.png`
/// + `trip_details_scroll_down.png` — ONE page). Presentation-only redesign: every
/// controller call, API, navigation branch, cancel/pay/review flow and the
/// post-checkout booking-success popup are the pre-existing production logic,
/// unchanged. Apartment mode auto-activates from the booked item's REAL category
/// (Trip → Stay, Pickup → Check-in, Dropoff → Check-out, Vehicle → Apartment,
/// Driver → Apartment Provider); car presentation stays exactly as approved.
class TaxiOrderDetailsScreen extends StatefulWidget {
  final int tripId;
  final bool? fromCheckout;
  final String? phone;
  const TaxiOrderDetailsScreen({super.key, required this.tripId, this.fromCheckout = false, this.phone});

  @override
  State<TaxiOrderDetailsScreen> createState() => _TaxiOrderDetailsScreenState();
}

class _TaxiOrderDetailsScreenState extends State<TaxiOrderDetailsScreen> {

  @override
  void initState() {
    super.initState();

    if(widget.phone == null) {
      Get.find<TaxiOrderController>().getTripDetails(widget.tripId, willUpdate: false);
    }
    if(Get.find<TaxiHomeController>().vehicleCategoryModel == null) {
      Get.find<TaxiHomeController>().getVehicleCategoryList();
    }
    if(widget.fromCheckout!) {
      Future.delayed(const Duration(microseconds: 600), () {
        Get.bottomSheet(const ConfirmBookingRequestBottomSheet(isScheduleBooking: false, isBooking: true));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiOrderController>(builder: (taxiOrderController) {
      final TripDetailsModel? trip = taxiOrderController.tripDetailsModel;

      if(trip == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

      final bool halfCompleted = trip.tripStatus == TripStatusEnum.completed.name && trip.paymentStatus != 'paid';
      final double discount = trip.discountOnTrip ?? 0;
      final double couponDiscount = trip.couponDiscountAmount ?? 0;
      final double tax = trip.taxAmount ?? 0;
      final bool taxInclude = trip.taxStatus == 'included';
      final double additionalCharge = trip.additionalCharge ?? 0;
      final double total = trip.tripAmount ?? 0;
      final double tripCost = _calculateTripCost(trip.tripDetails);
      final double subTotal = tripCost - discount - couponDiscount;

      // Apartment mode — real category of the booked item vs the real Short-Apt
      // category. Never activates for car bookings.
      final int? aptCatId = RentalApartmentAdapter.apartmentCategoryId(Get.find<TaxiHomeController>().vehicleCategoryModel);
      final List<TripDetails> details = trip.tripDetails ?? [];
      final bool isApartment = aptCatId != null && details.isNotEmpty &&
          details.where((d) => d.vehicleDetails?.categoryId == aptCatId).length * 2 > details.length;

      return PopScope(
        canPop: Navigator.canPop(context),
        onPopInvokedWithResult: (didPop, result) async {
          if(widget.fromCheckout!) {
            Future.delayed(const Duration(milliseconds: 100), () => Get.offAllNamed(RouteHelper.getInitialRoute()));
          }
        },
        child: Scaffold(
          // OPAQUE light-grey page background. Must be fully opaque — a translucent
          // colour here lets the route below (e.g. Vehicle Details) show through.
          backgroundColor: Color.alphaBlend(
            Theme.of(context).disabledColor.withValues(alpha: 0.06), Theme.of(context).cardColor),
          appBar: _appBar(context, trip, isApartment),
          body: RefreshIndicator(
            onRefresh: () async => taxiOrderController.getTripDetails(widget.tripId, willUpdate: false),
            child: Column(children: [
              Expanded(child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge),
                child: Column(children: [

                  _statusHero(context, trip, details, isApartment),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Service Completion Code — the customer's REAL verification code
                  // (`trip.otp`, same field Delivery uses). Shown prominently while
                  // the service is in progress (confirmed/ongoing) so the customer
                  // gives it to the provider ONLY after a satisfactory service; the
                  // provider entering it flips the trip to Completed → settlement
                  // eligible (existing production settlement flow). Never faked —
                  // hidden when the backend has not issued a code.
                  if(_showCompletionCode(trip)) ...[
                    _completionCode(context, trip, isApartment),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ],

                  if(!halfCompleted && trip.provider != null) ...[
                    _providerCard(context, trip, isApartment),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ],

                  if(!halfCompleted && details.isNotEmpty) ...[
                    _vehicleSummary(context, trip, details, isApartment),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ],

                  _tripDetailsCard(context, trip, isApartment),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  if(trip.tripNote != null) ...[
                    AdditionalNote(note: trip.tripNote),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ],

                  if(!halfCompleted && trip.vehicleIdentity != null && trip.vehicleIdentity!.isNotEmpty) ...[
                    DeliverymanView(vehicleIdentity: trip.vehicleIdentity),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                  ],

                  _billDetails(context, tripCost, discount, couponDiscount, subTotal, tax, additionalCharge, total, taxInclude),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _paymentMethod(context, trip),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _securePill(context),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _needHelp(context),

                  if(trip.tripStatus == TripStatusEnum.pending.name) ...[
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    _cancelButton(context, trip),
                  ],
                ]),
              )),

              _bottomView(context, trip, total),
            ]),
          ),
        ),
      );
    });
  }

  /// The completion code is relevant while the service is running (confirmed or
  /// ongoing) and the backend has issued a real code.
  bool _showCompletionCode(TripDetailsModel trip) {
    final bool running = trip.tripStatus == TripStatusEnum.confirmed.name || trip.tripStatus == TripStatusEnum.ongoing.name;
    return running && (trip.otp ?? '').isNotEmpty;
  }

  // ── Service Completion Code — very visible, Delivery-style. Real `trip.otp`. ──
  Widget _completionCode(BuildContext context, TripDetailsModel trip, bool isApartment) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [green, green.withValues(alpha: 0.82)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: green.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 20),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text('service_completion_code'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Container(
          width: double.infinity, alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          child: Text(
            trip.otp!,
            style: robotoBold.copyWith(color: green, fontSize: 34, letterSpacing: 8),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text('give_this_code_after_service'.tr,
            style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.95), fontSize: Dimensions.fontSizeSmall, height: 1.4)),
      ]),
    );
  }

  // ── App bar: back (fromCheckout → home), Trip #id, status pill, menu ──
  PreferredSizeWidget _appBar(BuildContext context, TripDetailsModel trip, bool isApartment) {
    final Color statusColor = _statusColor(context, trip.tripStatus);
    return AppBar(
      backgroundColor: Theme.of(context).cardColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => widget.fromCheckout! ? Get.offAllNamed(RouteHelper.getInitialRoute()) : Navigator.pop(context),
      ),
      title: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${(isApartment ? 'booking' : 'trip').tr} #${widget.tripId}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(height: 6, width: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text((trip.tripStatus ?? '').toTitleCase(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: statusColor)),
          ]),
        ),
      ]),
      centerTitle: true,
      toolbarHeight: 72,
    );
  }

  // ── Status hero: "Your booking is <Status>", message, status glyph, item image,
  // estimated-arrival chip (pending), booking date + booking-from. ──
  Widget _statusHero(BuildContext context, TripDetailsModel trip, List<TripDetails> details, bool isApartment) {
    final Color green = Theme.of(context).primaryColor;
    final Color statusColor = _statusColor(context, trip.tripStatus);
    final String? thumb = details.isNotEmpty ? details.first.vehicleDetails?.thumbnailFullUrl : null;
    final bool pending = trip.tripStatus == TripStatusEnum.pending.name;

    return _card(context, padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('your_booking_is'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
            Text((trip.tripStatus ?? '').toTitleCase(), style: robotoBold.copyWith(fontSize: 26, color: statusColor)),
            const SizedBox(height: 4),
            Text(_statusMessage(trip.tripStatus), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          ])),
          Container(
            height: 56, width: 56, alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.25), blurRadius: 12)]),
            child: Container(height: 44, width: 44, alignment: Alignment.center,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              child: Icon(_statusIcon(trip.tripStatus), color: Colors.white, size: 24)),
          ),
        ]),
      ),

      if((thumb ?? '').isNotEmpty) Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: SizedBox(height: 120, width: double.infinity, child: CustomImage(image: thumb!, fit: BoxFit.contain)),
      ),

      if(pending) Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
          child: Row(children: [
            Icon(Icons.access_time, color: green, size: 20),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('estimated_arrival'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
              Text('stay_close_to_pickup'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
            ])),
          ]),
        ),
      ),

      Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
      Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(children: [
          Expanded(child: _heroFact(context, Icons.calendar_today_outlined, 'booking_date'.tr,
              trip.scheduleAt != null ? DateConverter.dateTimeStringToDateTime(trip.scheduleAt!) : '-')),
          Container(width: 1, height: 32, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: _heroFact(context, Icons.location_on_outlined, 'booking_from'.tr,
              trip.pickupLocation?.locationName ?? '-')),
        ]),
      ),
    ]));
  }

  Widget _heroFact(BuildContext context, IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Theme.of(context).primaryColor, size: 18),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ])),
    ]);
  }

  // ── Provider card: logo, name, rating, Verified, View Company Profile,
  // WhatsApp/Call/Chat — all existing production actions. ──
  Widget _providerCard(BuildContext context, TripDetailsModel trip, bool isApartment) {
    final Provider provider = trip.provider!;
    final Color green = Theme.of(context).primaryColor;
    return _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text((isApartment ? 'apartment_provider' : 'provider').tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      InkWell(
        onTap: () => Get.to(() => VendorDetailScreen(vendorId: provider.id)),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(50),
            child: CustomImage(image: provider.logoFullUrl ?? '', height: 48, width: 48, fit: BoxFit.cover)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(provider.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text('${provider.avgRating ?? 0} (${provider.ratingCount ?? 0}+)', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Icon(Icons.verified, size: 14, color: green),
              const SizedBox(width: 2),
              Flexible(child: Text('verified_provider'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: green))),
            ]),
          ])),
          Icon(Icons.chevron_right, color: Theme.of(context).hintColor, size: 20),
        ]),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      InkWell(
        onTap: () => Get.to(() => VendorDetailScreen(vendorId: provider.id)),
        child: Text('view_company_profile'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: green)),
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),
      Row(children: [
        Expanded(child: _contactButton(context, Icons.chat, 'whatsapp'.tr, () => _launchWhatsApp(provider.phone))),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: _contactButton(context, Icons.call, 'call'.tr, () => _launchCall(provider.phone))),
        if(provider.chat == true && AuthHelper.isLoggedIn()) ...[
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: _contactButton(context, Icons.chat_bubble_outline, 'chat'.tr, () => _openChat(provider, trip.id))),
        ],
      ]),
    ]));
  }

  Widget _contactButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final Color green = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(children: [
          Container(height: 36, width: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: green.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(icon, color: green, size: 18)),
          const SizedBox(height: 4),
          Text(label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ]),
      ),
    );
  }

  // ── Vehicle / Apartment summary ──
  Widget _vehicleSummary(BuildContext context, TripDetailsModel trip, List<TripDetails> details, bool isApartment) {
    final VehicleDetails? v = details.first.vehicleDetails;
    final int qty = details.fold(0, (sum, d) => sum + (d.quantity ?? 0));
    return _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text((isApartment ? 'apartment_summary' : 'vehicle_summary').tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: CustomImage(image: v?.thumbnailFullUrl ?? '', height: 90, width: 100, fit: BoxFit.cover)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v?.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Wrap(spacing: Dimensions.paddingSizeExtraSmall, runSpacing: Dimensions.paddingSizeExtraSmall, children: isApartment
              ? [
                  _tag(context, Icons.ac_unit, (v?.airCondition == 1) ? 'ac'.tr : 'non_ac'.tr),
                  ...RentalApartmentAdapter.amenityTags(v?.tag).take(3).map((t) => _tag(context, Icons.check_circle_outline, t)),
                ]
              : [
                  if((v?.seatingCapacity ?? '').isNotEmpty) _tag(context, Icons.person_outline, '${v!.seatingCapacity} ${'seats'.tr}'),
                  if((v?.transmissionType ?? '').isNotEmpty) _tag(context, Icons.settings_outlined, v!.transmissionType!.toTitleCase()),
                  if((v?.fuelType ?? '').isNotEmpty) _tag(context, Icons.local_gas_station_outlined, v!.fuelType!.toTitleCase()),
                  _tag(context, Icons.ac_unit, (v?.airCondition == 1) ? 'ac'.tr : 'non_ac'.tr),
                ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [
            Text('${'quantity'.tr}: ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
            Text('$qty', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
          ]),
        ])),
      ]),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
      ),
      Row(children: [
        Expanded(child: _heroFact(context, Icons.confirmation_number_outlined, 'booking_id'.tr, 'MJ${trip.id}')),
        Expanded(child: _heroFact(context, Icons.calendar_today_outlined, 'booked_on'.tr,
            trip.scheduleAt != null ? DateConverter.dateTimeStringToDateTime(trip.scheduleAt!) : '-')),
      ]),
    ]));
  }

  Widget _tag(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Theme.of(context).textTheme.bodyLarge!.color),
        const SizedBox(width: 3),
        Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
      ]),
    );
  }

  // ── Trip / Stay details: pickup, dropoff, pick-up time, rent type, est distance,
  // est duration — with a dotted connector on the two location rows. ──
  Widget _tripDetailsCard(BuildContext context, TripDetailsModel trip, bool isApartment) {
    final String? pickup = trip.pickupLocation?.locationName;
    final String? dropoff = trip.destinationLocation?.locationName;
    final String pickTime = trip.scheduleAt != null ? DateConverter.dateTimeStringToDateTime(trip.scheduleAt!) : '-';
    final String rentType = trip.tripType == 'hourly'
        ? '${trip.tripType!.tr} (${trip.estimatedHours} ${'hrs'.tr})' : (trip.tripType ?? '').tr;
    final bool distanceWise = trip.tripType == 'distance_wise';
    final double nights = (trip.estimatedHours ?? 0) / 24;

    return _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text((isApartment ? 'booking_details' : 'trip_details').tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      _detailRow(context, Icons.location_on, (isApartment ? 'check_in' : 'pickup_location').tr, pickup ?? '-', connectorBelow: true),
      _detailRow(context, Icons.near_me, (isApartment ? 'check_out' : 'dropoff_location').tr, dropoff ?? '-', connectorBelow: true),
      _detailRow(context, Icons.calendar_today_outlined, (isApartment ? 'check_in' : 'pick_time').tr, pickTime),
      if(!isApartment) _detailRow(context, Icons.hourglass_empty, 'rent_type'.tr, rentType),
      if(isApartment)
        _detailRow(context, Icons.nightlight_outlined, 'nights'.tr, nights.toStringAsFixed(0))
      else if(distanceWise)
        _detailRow(context, Icons.speed_outlined, 'estimated_distance'.tr, '${(trip.distance ?? 0).toStringAsFixed(3)} ${'km'.tr}'),
      _detailRow(context, Icons.access_time, 'estimated_duration'.tr,
          trip.tripType == 'hourly' ? '${trip.estimatedHours} ${'hrs'.tr}' : '${nights.toStringAsFixed(0)} ${'day'.tr}', isLast: true),
    ]));
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {bool connectorBelow = false, bool isLast = false}) {
    final Color green = Theme.of(context).primaryColor;
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(height: 40, width: 40, alignment: Alignment.center,
          decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
          child: Icon(icon, color: green, size: 18)),
        if(connectorBelow) Expanded(child: Container(width: 1.2, color: Theme.of(context).disabledColor.withValues(alpha: 0.4))),
      ]),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(child: Padding(
        padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          const SizedBox(height: 2),
          Text(value, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ]),
      )),
      Icon(Icons.chevron_right, color: Theme.of(context).hintColor, size: 20),
    ]));
  }

  // ── Bill Details (real amounts; existing calculation) ──
  Widget _billDetails(BuildContext context, double tripCost, double discount, double couponDiscount,
      double subTotal, double tax, double serviceFee, double total, bool taxInclude) {
    final Color green = Theme.of(context).primaryColor;
    return _card(context, child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('bill_details'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        Icon(Icons.info, color: green, size: 18),
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      _billRow(context, 'trip_cost'.tr, PriceConverter.convertPrice(tripCost, forTaxi: true)),
      if(discount > 0) _billRow(context, 'trip_discount'.tr, '- ${PriceConverter.convertPrice(discount, forTaxi: true)}', valueColor: green),
      if(couponDiscount > 0) _billRow(context, 'coupon_discount'.tr, '- ${PriceConverter.convertPrice(couponDiscount, forTaxi: true)}', valueColor: green),
      Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall), child: Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2))),
      _billRow(context, 'subtotal'.tr, PriceConverter.convertPrice(subTotal, forTaxi: true), bold: true),
      if(!taxInclude && tax > 0) _billRow(context, 'vat_tax'.tr, '+ ${PriceConverter.convertPrice(tax, forTaxi: true)}'),
      if(serviceFee > 0) _billRow(context, 'service_charge'.tr, '+ ${PriceConverter.convertPrice(serviceFee, forTaxi: true)}'),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(color: green.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('total_amount'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          Text(PriceConverter.convertPrice(total, forTaxi: true), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: green)),
        ]),
      ),
    ]));
  }

  Widget _billRow(BuildContext context, String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: (bold ? robotoBold : robotoRegular).copyWith(fontSize: Dimensions.fontSizeSmall)),
        Text(value, style: (bold ? robotoBold : robotoMedium).copyWith(fontSize: Dimensions.fontSizeSmall, color: valueColor)),
      ]),
    );
  }

  // ── Payment Method ──
  Widget _paymentMethod(BuildContext context, TripDetailsModel trip) {
    final Color green = Theme.of(context).primaryColor;
    final String method = (trip.paymentMethod ?? '').isNotEmpty ? trip.paymentMethod!.toTitleCase() : 'cash_payment'.tr;
    return _card(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('payment_method'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Row(children: [
        Container(height: 44, width: 44, alignment: Alignment.center,
          decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
          child: Icon(Icons.account_balance_wallet_outlined, color: green, size: 20)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text(method, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault))),
      ]),
    ]));
  }

  Widget _securePill(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(color: green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Row(children: [
        Icon(Icons.verified_user, color: green, size: 18),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text('your_payment_is_secure'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
        Text('learn_more'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: green)),
      ]),
    );
  }

  Widget _needHelp(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return _card(context, child: Row(children: [
      Container(height: 44, width: 44, alignment: Alignment.center,
        decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        child: Icon(Icons.support_agent, color: green, size: 22)),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('need_help'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
        Text('support_team_available_247'.tr, maxLines: 2, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
      ])),
      InkWell(
        onTap: () => Get.toNamed(RouteHelper.getSupportRoute()),
        child: Text('contact_support'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: green)),
      ),
    ]));
  }

  // ── Cancel booking (pending) — existing production cancel sheet ──
  Widget _cancelButton(BuildContext context, TripDetailsModel trip) {
    return ElevatedButton(
      onPressed: () => Get.bottomSheet(BookingCancelBottomSheet(tripId: trip.id!)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        elevation: 0,
      ),
      child: Text('cancel_booking'.tr, style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)),
    );
  }

  // ── Bottom bar — Pay Now (completed+unpaid) / Give Review (completed+paid) —
  // exact existing production logic. ──
  Widget _bottomView(BuildContext context, TripDetailsModel trip, double total) {
    final bool payNow = trip.tripStatus == TripStatusEnum.completed.name && trip.paymentStatus != 'paid';
    final bool review = trip.tripStatus == TripStatusEnum.completed.name && trip.paymentStatus == 'paid'
        && _canReview(trip.vehicleIdentity ?? []) && (trip.provider?.reviewSection ?? false) && AuthHelper.isLoggedIn();
    if(!payNow && !review) return const SizedBox(width: double.infinity);

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), blurRadius: 10)]),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        child: payNow
            ? CustomButton(buttonText: 'pay_now'.tr, onPressed: () {
                showModalBottomSheet(isScrollControlled: true, context: context,
                  builder: (_) => TaxiPaymentBottomSheet(id: trip.id!, totalPrice: total),
                ).then((success) {
                  if(success != null && success) Get.find<TaxiOrderController>().getTripDetails(trip.id!, willUpdate: false);
                });
              })
            : OutlinedButton(
                onPressed: () {
                  if(trip.vehicleIdentity!.isNotEmpty) {
                    Get.bottomSheet(ReviewBottomSheet(vehicleList: trip.vehicleIdentity!), isScrollControlled: true);
                  } else {
                    showCustomSnackBar('not_found_any_assigned_vehicle'.tr);
                  }
                },
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault))),
                child: Text('give_review'.tr, style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: 16)),
              ),
      )),
    );
  }

  // ── Shared card surface ──
  Widget _card(BuildContext context, {required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
      ),
      child: child,
    );
  }

  // ── Status → colour / icon / message ──
  Color _statusColor(BuildContext context, String? status) {
    if(status == TripStatusEnum.canceled.name) return Theme.of(context).colorScheme.error;
    if(status == TripStatusEnum.completed.name) return Theme.of(context).primaryColor;
    return Theme.of(context).primaryColor;
  }

  IconData _statusIcon(String? status) {
    if(status == TripStatusEnum.canceled.name) return Icons.close_rounded;
    if(status == TripStatusEnum.completed.name) return Icons.check_rounded;
    if(status == TripStatusEnum.ongoing.name) return Icons.directions_car_filled;
    return Icons.access_time;
  }

  String _statusMessage(String? status) {
    if(status == TripStatusEnum.pending.name) return 'we_are_waiting_for_provider'.tr;
    return '';
  }

  // ── Existing production helpers, unchanged ──
  void _launchWhatsApp(String? phone) async {
    if(phone == null) return;
    final String url = 'https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}';
    if(await canLaunchUrlString(url)) {
      launchUrlString(url, mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $phone');
    }
  }

  void _launchCall(String? phone) async {
    if(phone == null) return;
    if(await canLaunchUrlString('tel:$phone')) {
      launchUrlString('tel:$phone', mode: LaunchMode.externalApplication);
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $phone');
    }
  }

  void _openChat(Provider provider, int? tripId) {
    Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: NotificationBodyModel(orderId: tripId, restaurantId: provider.id),
      user: User(id: provider.id, fName: provider.name, lName: '', imageFullUrl: provider.logoFullUrl),
    ));
  }

  double _calculateTripCost(List<TripDetails>? tripDetails) {
    double tripCost = 0;
    if(tripDetails != null) {
      for (var trip in tripDetails) {
        tripCost += trip.calculatedPrice ?? 0;
      }
    }
    return tripCost;
  }

  bool _canReview(List<VehicleIdentity> vehicleList) {
    if(AuthHelper.isLoggedIn()) {
      for (int i = 0; i < vehicleList.length; i++) {
        if (vehicleList[i].rating == null) return true;
      }
    }
    return false;
  }
}
