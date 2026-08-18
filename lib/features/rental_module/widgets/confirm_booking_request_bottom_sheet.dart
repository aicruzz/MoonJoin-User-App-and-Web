import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/features/rental_module/common/models/trip_details_model.dart';
import 'package:moonjoin/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:moonjoin/features/rental_module/provider_adapter/rental_apartment_adapter.dart';
import 'package:moonjoin/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:moonjoin/helper/price_converter.dart';
import 'package:moonjoin/helper/date_converter.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// **Booking Request Successful** sheet (design
/// `ui-designs/Car_Rental/booking_request_successful.png`) — shown over the trip
/// details page after a real booking, exactly as before
/// (`TaxiOrderDetailsScreen(fromCheckout: true)` auto-opens it).
///
/// Presentation-only redesign of the legacy sheet: same constructor, same call
/// sites, same close behaviour. Every displayed value is REAL trip data read from
/// `TaxiOrderController.tripDetailsModel` (schedule time, pickup/dropoff location
/// names, vehicle name + thumbnail, provider phone). Rows render as the trip
/// details load; nothing is fabricated. The call button reuses the existing
/// `ProviderView` tel: pattern.
class ConfirmBookingRequestBottomSheet extends StatelessWidget {

  final bool isScheduleBooking;
  final bool isBooking;

  const ConfirmBookingRequestBottomSheet({super.key, required this.isScheduleBooking, required this.isBooking});

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;

    return GetBuilder<TaxiOrderController>(builder: (taxiOrderController) {
      final TripDetailsModel? trip = taxiOrderController.tripDetailsModel;

      final String? pickupTime = trip?.scheduleAt != null ? DateConverter.dateTimeStringToDateTime(trip!.scheduleAt!) : null;
      final String? pickupName = trip?.pickupLocation?.locationName;
      final String? dropoffName = trip?.destinationLocation?.locationName;
      final List<TripDetails> details = trip?.tripDetails ?? [];
      final String vehicleNames = details.map((d) => d.vehicleDetails?.name ?? '').where((n) => n.isNotEmpty).join(', ');
      final String? vehicleThumb = details.isNotEmpty ? details.first.vehicleDetails?.thumbnailFullUrl : null;
      final String? providerPhone = trip?.provider?.phone;

      // Auto-activating APARTMENT success (ONE shared sheet — product-owner rule):
      // real category of the booked item vs the real Short-Apt category. Never
      // activates for car bookings; car success is byte-identical.
      final int? aptCatId = RentalApartmentAdapter.apartmentCategoryId(Get.find<TaxiHomeController>().vehicleCategoryModel);
      final bool isApartment = aptCatId != null && details.isNotEmpty &&
          details.where((d) => d.vehicleDetails?.categoryId == aptCatId).length * 2 > details.length;

      // Apartment-only REAL fields (design's extra blocks): booking id = trip id,
      // total paid = trip amount, payment method, check-in/out/nights arithmetic.
      final String bookingId = trip?.id != null ? 'BK${trip!.id}' : '';
      final String bookingDate = trip?.scheduleAt != null ? DateConverter.dateTimeStringToDateTime(trip!.scheduleAt!) : '';
      final String totalPaid = trip?.tripAmount != null ? PriceConverter.convertPrice(trip!.tripAmount) : '';
      final String paymentMethod = (trip?.paymentMethod ?? '').isNotEmpty ? trip!.paymentMethod!.tr : '';
      final double aptHours = trip?.estimatedHours ?? 0;
      String checkIn = '', checkOut = '', nights = '';
      if(isApartment && trip?.scheduleAt != null) {
        try {
          final DateTime ci = DateConverter.dateTimeStringToDate(trip!.scheduleAt!);
          checkIn = DateConverter.dateToDateAndTime(ci);
          checkOut = DateConverter.dateToDateAndTime(ci.add(Duration(hours: aptHours.round())));
          nights = (aptHours / 24).toStringAsFixed(0);
        } catch (_) {}
      }

      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
        ),
        padding: const EdgeInsets.only(top: 10),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            Container(width: 33, height: 4.0,
              decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(23.0)),
            ),

            Container(padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 32, width: 32, alignment: Alignment.center,
                  decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 18, color: Theme.of(context).hintColor),
                ),
              ),
            ),

            // Check badge + the REAL booked vehicle image (design's hero art).
            Container(
              height: 96, width: 96, alignment: Alignment.center,
              decoration: BoxDecoration(color: green.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Container(
                height: 72, width: 72, alignment: Alignment.center,
                decoration: BoxDecoration(color: green, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
            ),
            if((vehicleThumb ?? '').isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: SizedBox(height: 110, child: CustomImage(image: vehicleThumb!, fit: BoxFit.contain)),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text.rich(TextSpan(children: [
              TextSpan(text: '${isApartment ? 'booking'.tr : isBooking ? 'booking_request'.tr : 'schedule_booking_request'.tr} ', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
              TextSpan(text: '${'successful'.tr}!', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: green)),
            ])),
            const SizedBox(height: 6),
            Container(height: 3, width: 56, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(2))),

            Padding(
              padding: const EdgeInsets.fromLTRB(40, Dimensions.paddingSizeDefault, 40, Dimensions.paddingSizeDefault),
              child: Text((isApartment ? 'your_apartment_has_been_booked' : 'great_choice_booking_confirmed').tr, textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ),

            // Apartment-only: Booking ID + Booking Date, then Total Paid + payment
            // method (design's extra cards). Real trip fields only.
            if(isApartment) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(children: [
                  if(bookingId.isNotEmpty) Expanded(child: _miniFact(context, Icons.confirmation_number_outlined, 'booking_id'.tr, bookingId)),
                  if(bookingDate.isNotEmpty) Expanded(child: _miniFact(context, Icons.calendar_today_outlined, 'booking_date'.tr, bookingDate)),
                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],

            // Real trip facts (render as the trip details load). Apartment mode shows
            // check-in / check-out / nights; car mode shows pickup/dropoff/vehicle.
            Container(
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
              ),
              child: isApartment
                  ? Column(children: [
                      if(checkIn.isNotEmpty) _infoRow(context, Icons.login_outlined, 'check_in'.tr, checkIn),
                      if(checkOut.isNotEmpty) _infoRow(context, Icons.logout_outlined, 'check_out'.tr, checkOut),
                      if(nights.isNotEmpty) _infoRow(context, Icons.nightlight_outlined, 'nights'.tr, nights),
                      if(vehicleNames.isNotEmpty) _infoRow(context, Icons.apartment_outlined, 'selected_apartment'.tr, vehicleNames, isLast: true),
                    ])
                  : Column(children: [
                if(pickupTime != null) _infoRow(context, Icons.calendar_today_outlined, 'pickup_time'.tr, pickupTime),
                if((pickupName ?? '').isNotEmpty) _infoRow(context, Icons.location_on_outlined, 'pickup_location'.tr, pickupName!),
                if((dropoffName ?? '').isNotEmpty) _infoRow(context, Icons.near_me_outlined, 'dropoff_location'.tr, dropoffName!),
                if(vehicleNames.isNotEmpty) _infoRow(context, Icons.directions_car_outlined, 'vehicle'.tr, vehicleNames, isLast: true),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Apartment-only: Total Paid + payment method (real trip fields).
            if(isApartment && totalPaid.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('total_paid'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                    if(paymentMethod.isNotEmpty) Text(paymentMethod, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
                  ]),
                  Text(totalPaid, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: green)),
                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],

            // Contact provider — reuses the existing production tel: pattern.
            if((providerPhone ?? '').isNotEmpty) Container(
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: Row(children: [
                Icon(Icons.support_agent, color: green, size: 22),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(child: Text('need_help_contact_your_provider_anytime'.tr,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
                InkWell(
                  onTap: () async {
                    if(await canLaunchUrlString('tel:$providerPhone')) {
                      launchUrlString('tel:$providerPhone', mode: LaunchMode.externalApplication);
                    } else {
                      showCustomSnackBar('${'can_not_launch'.tr} $providerPhone');
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 36, width: 36, alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: green, width: 1.5)),
                    child: Icon(Icons.call, color: green, size: 18),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, GetPlatform.isAndroid ? Dimensions.paddingSizeSmall : 0),
                child: CustomButton(
                  buttonText: 'okay_got_it'.tr,
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _miniFact(BuildContext context, IconData icon, String label, String value) {
    return Row(children: [
      Container(height: 36, width: 36, alignment: Alignment.center,
        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 18)),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ])),
    ]);
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      decoration: isLast ? null : BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      child: Row(children: [
        Container(
          height: 44, width: 44, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
        ])),
        Icon(Icons.chevron_right, color: Theme.of(context).hintColor, size: 20),
      ]),
    );
  }
}
