import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
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
              TextSpan(text: '${isBooking ? 'booking_request'.tr : 'schedule_booking_request'.tr} ', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
              TextSpan(text: '${'successful'.tr}!', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: green)),
            ])),
            const SizedBox(height: 6),
            Container(height: 3, width: 56, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(2))),

            Padding(
              padding: const EdgeInsets.fromLTRB(40, Dimensions.paddingSizeDefault, 40, Dimensions.paddingSizeDefault),
              child: Text('great_choice_booking_confirmed'.tr, textAlign: TextAlign.center,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ),

            // Real trip facts (render as the trip details load).
            Container(
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(children: [
                if(pickupTime != null) _infoRow(context, Icons.calendar_today_outlined, 'pickup_time'.tr, pickupTime),
                if((pickupName ?? '').isNotEmpty) _infoRow(context, Icons.location_on_outlined, 'pickup_location'.tr, pickupName!),
                if((dropoffName ?? '').isNotEmpty) _infoRow(context, Icons.near_me_outlined, 'dropoff_location'.tr, dropoffName!),
                if(vehicleNames.isNotEmpty) _infoRow(context, Icons.directions_car_outlined, 'vehicle'.tr, vehicleNames, isLast: true),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

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
