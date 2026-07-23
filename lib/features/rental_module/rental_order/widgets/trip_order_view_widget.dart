import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/rental_module/common/enums/trip_status_enum.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_model.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/provider_adapter/rental_apartment_adapter.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_order/screens/taxi_order_details_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_order/widgets/taxi_order_shimmer_widget.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Rental Trips/Bookings list (Car design `my_trip.png`, Apartment `my_booking_history.png`
/// — same card, wording differs). Presentation-only redesign: same controller,
/// same pagination, same navigation to the FROZEN `TaxiOrderDetailsScreen`.
/// Apartment wording auto-activates per card from the booked item's REAL category.
class TripOrderViewWidget extends StatelessWidget {
  final bool isRunning;
  const TripOrderViewWidget({super.key, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    return GetBuilder<TaxiOrderController>(builder: (taxiOrderController) {
      TripModel? tripModel;
      if(taxiOrderController.tripModel != null && taxiOrderController.tripHistoryModel != null) {
        tripModel = isRunning ? taxiOrderController.tripModel : taxiOrderController.tripHistoryModel;
      }
      if(tripModel == null) return TaxiOrderShimmerWidget(taxiOrderController: taxiOrderController);
      if(tripModel.trips!.isEmpty) return NoDataScreen(text: 'no_order_found'.tr, showFooter: true);

      final int? aptCatId = RentalApartmentAdapter.apartmentCategoryId(Get.find<TaxiHomeController>().vehicleCategoryModel);

      return RefreshIndicator(
        onRefresh: () async => taxiOrderController.getTripList(1, isUpdate: true, isRunning: isRunning),
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 80),
          child: PaginatedListView(
            scrollController: scrollController,
            onPaginate: (int? offset) => taxiOrderController.getTripList(offset!, isUpdate: true, isRunning: isRunning),
            totalSize: tripModel.totalSize,
            offset: tripModel.offset,
            itemView: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: tripModel.trips!.length,
              separatorBuilder: (_, i) => const SizedBox(height: Dimensions.paddingSizeDefault),
              itemBuilder: (context, index) => _tripCard(context, tripModel!.trips![index], aptCatId),
            ),
          ),
        ),
      );
    });
  }

  Widget _tripCard(BuildContext context, TripDetailsModel trip, int? aptCatId) {
    final Color green = Theme.of(context).primaryColor;
    final Color error = Theme.of(context).colorScheme.error;
    final bool cancelled = trip.tripStatus == TripStatusEnum.canceled.name;
    final bool completed = trip.tripStatus == TripStatusEnum.completed.name;
    final bool paid = trip.paymentStatus == 'paid';
    final Color statusColor = cancelled ? error : green;

    final List<TripDetails> details = trip.tripDetails ?? [];
    final bool isApartment = aptCatId != null && details.isNotEmpty &&
        details.where((d) => d.vehicleDetails?.categoryId == aptCatId).length * 2 > details.length;
    final VehicleDetails? v = details.isNotEmpty ? details.first.vehicleDetails : null;

    final String dateLabel = cancelled ? 'cancelled_on'.tr : completed ? 'completed_on'.tr : 'booking_date'.tr;
    final String dateValue = trip.scheduleAt != null ? DateConverter.dateTimeStringToDateTime(trip.scheduleAt!) : '';

    return CustomInkWell(
      onTap: () => Get.to(() => TaxiOrderDetailsScreen(tripId: trip.id!)),
      radius: Dimensions.radiusLarge,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), width: 1),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Status pill + Trip/Booking ID
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cancelled ? Icons.cancel : completed ? Icons.check_circle : Icons.access_time, size: 13, color: statusColor),
                const SizedBox(width: 4),
                Text((trip.tripStatus ?? '').toTitleCase().toUpperCase(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: statusColor)),
              ]),
            ),
            Text('${isApartment ? 'booking_id'.tr : 'trip_id'.tr}: ${trip.id}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dateLabel, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
              Text(dateValue, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: statusColor)),
            ])),
            if((v?.thumbnailFullUrl ?? '').isNotEmpty) ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: CustomImage(image: v!.thumbnailFullUrl!, height: 60, width: 90, fit: BoxFit.cover),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // From / To (car) or Check-in / Check-out (apartment)
          _locRow(context, Icons.location_on, (isApartment ? 'check_in' : 'from_pickup').tr, trip.pickupLocation?.locationName ?? '-', green, connector: true),
          _locRow(context, Icons.location_on, (isApartment ? 'check_out' : 'to_dropoff').tr, trip.destinationLocation?.locationName ?? '-', error),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Item name + total + paid/cancelled badge
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Text(v?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(PriceConverter.convertPrice(trip.tripAmount ?? 0, forTaxi: true), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: cancelled ? error : green)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(color: (cancelled ? error : paid ? green : Theme.of(context).hintColor), width: 1)),
                child: Text(cancelled ? 'cancelled'.tr : paid ? 'paid'.tr : (trip.paymentStatus ?? '').toTitleCase(),
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: cancelled ? error : paid ? green : Theme.of(context).hintColor)),
              ),
            ]),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Distance / Travel-time / Nights strip (real values)
          Container(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
            child: Row(children: [
              if(isApartment) ...[
                _metric(context, Icons.nightlight_outlined, 'nights'.tr, ((trip.estimatedHours ?? 0) / 24).toStringAsFixed(0)),
                _metric(context, Icons.access_time, 'estimated_duration'.tr, '${((trip.estimatedHours ?? 0) / 24).toStringAsFixed(0)} ${'day'.tr}'),
              ] else ...[
                _metric(context, Icons.speed_outlined, 'distance'.tr, '${(trip.distance ?? 0).toStringAsFixed(1)} ${'km'.tr}'),
                _metric(context, Icons.access_time, 'travel_time'.tr, trip.tripType == 'hourly' ? '${trip.estimatedHours} ${'hrs'.tr}' : '${((trip.estimatedHours ?? 0) / 24).toStringAsFixed(0)} ${'day'.tr}'),
              ],
              _metric(context, Icons.category_outlined, 'rent_type'.tr, (trip.tripType ?? '').tr),
            ]),
          ),
          Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall), child: Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.2))),

          // Provider + View Details
          Row(children: [
            if((trip.provider?.logoFullUrl ?? '').isNotEmpty) ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(image: trip.provider!.logoFullUrl!, height: 22, width: 22, fit: BoxFit.cover),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(child: Text(trip.provider?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor))),
            Text('view_details'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: green)),
            Icon(Icons.chevron_right, size: 18, color: green),
          ]),
        ]),
      ),
    );
  }

  Widget _locRow(BuildContext context, IconData icon, String label, String value, Color color, {bool connector = false}) {
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Icon(icon, size: 16, color: color),
        if(connector) Expanded(child: Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 2), color: Theme.of(context).disabledColor.withValues(alpha: 0.4))),
      ]),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(child: Padding(
        padding: EdgeInsets.only(bottom: connector ? Dimensions.paddingSizeSmall : 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ]),
      )),
    ]));
  }

  Widget _metric(BuildContext context, IconData icon, String label, String value) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Row(children: [
        Icon(icon, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeOverSmall, color: Theme.of(context).hintColor)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
        ])),
      ]),
    ));
  }
}
