import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/custom_text_field.dart';
import 'package:moonjoin/common/widgets/quantity_button.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/features/rental_module/provider_adapter/rental_apartment_adapter.dart';
import 'package:moonjoin/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:moonjoin/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:moonjoin/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/controllers/taxi_cart_controller.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/domain/models/car_cart.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:moonjoin/features/rental_module/helper/cart_helper.dart';
import 'package:moonjoin/features/rental_module/rental_cart_screen/widgets/trip_vehicle_list_dialog.dart';
import 'package:moonjoin/features/rental_module/rental_checkout_screen/taxi_checkout_screen.dart';
import 'package:moonjoin/features/rental_module/rental_location_screen/taxi_location_suggestion_screen.dart';
import 'package:moonjoin/features/rental_module/vendor/screens/vendor_detail_screen.dart';
import 'package:moonjoin/features/rental_module/widgets/date_time_picker_sheet.dart';
import 'package:moonjoin/features/rental_module/widgets/trip_from_to_card.dart';
import 'package:moonjoin/features/rental_module/widgets/trip_type_card.dart';
import 'package:moonjoin/helper/address_helper.dart';
import 'package:moonjoin/helper/date_converter.dart';
import 'package:moonjoin/helper/price_converter.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// **Rental — Vehicle Details** (design `ui-designs/Car_Rental/car_rental_details.png`;
/// `car_rental_details_trip_type.png` is the SAME page with "Per Day" selected — the
/// "Estimate Days" row and bottom estimate are trip-type-dependent, not a second page).
///
/// Presentation-only rewrite. Every piece of business logic is the pre-existing rental
/// implementation, unchanged: `TaxiHomeController.getVehicleDetails`, the trip context
/// (`TaxiLocationController` — destination via the existing
/// `TaxiLocationSuggestionScreen`, pickup time via the existing `DateTimePickerSheet`,
/// trip type via `selectTripType`, estimate inputs via the existing controllers), the
/// cart (`_addToCart` → `addToCart`/`decideAddToCart`, `setQuantity`, `removeFromCart`)
/// and the production `TaxiCheckoutScreen` (reads the cart, exactly as when reached
/// from the cart screen).
class VehicleDetailsScreen extends StatefulWidget {
  final int? vehicleId;
  final bool? fromSelectVehicleScreen;
  const VehicleDetailsScreen({super.key, required this.vehicleId, this.fromSelectVehicleScreen = false});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {

  int cartQuantity = 1;
  int isExistInCartPosition = -1;
  bool _showAllPhotos = false;

  /// Cart values the estimate inputs were seeded with — used to detect whether the
  /// user changed the trip type/estimate so the cart is updated before checkout.
  String _seededEstimateTime = '';
  String _seededEstimateDay = '';

  /// Loads the vehicle through the EXISTING controller call with SILENT
  /// auto-retry. The repository returns null for any non-200 (timeout/429/500) and
  /// the controller stores it silently — previously one failed request left the
  /// page spinning forever with no recovery. Now a transient failure is retried in
  /// the background (1s/2s/3s, then every 5s while the page is open), so the user
  /// only ever sees the loader resolve into the page — never an error screen.
  Future<void> _loadVehicleDetails() async {
    int attempt = 0;
    while(mounted) {
      try {
        await Get.find<TaxiHomeController>().getVehicleDetails(widget.vehicleId!);
      } catch (_) {
        // API/parse exception — treated identically to a null result below.
      }
      if(!mounted || Get.find<TaxiHomeController>().vehicleDetailsModel != null) return;
      attempt++;
      await Future.delayed(Duration(seconds: attempt < 4 ? attempt : 5));
    }
  }

  @override
  void initState() {
    super.initState();
    if(!widget.fromSelectVehicleScreen!) {
      Get.find<TaxiLocationController>().initialSetup();
    }
    _loadVehicleDetails();
    // Apartment detection needs the REAL category list (may not be loaded on a
    // deep entry) — existing controller call, no new API.
    if(Get.find<TaxiHomeController>().vehicleCategoryModel == null) {
      Get.find<TaxiHomeController>().getVehicleCategoryList();
    }
    isExistInCartPosition = Get.find<TaxiCartController>().isExistInCart(widget.vehicleId!);
    if(isExistInCartPosition != -1) {
      cartQuantity = Get.find<TaxiCartController>().getCartQuantity(isExistInCartPosition);
      // Existing pattern (TripTypeBottomSheetWidget): mirror the cart's real rental
      // type into the cart controller so the trip-type cards show the true selection,
      // and seed the estimate inputs from the cart's real values (same seeding the
      // production sheet performs).
      final UserData? userData = Get.find<TaxiCartController>().carCartModel?.userData;
      if(userData?.rentalType != null) {
        Get.find<TaxiCartController>().selectTripType(userData!.rentalType!, willUpdate: false);
      }
      final double hours = userData?.estimatedHours ?? 0;
      _seededEstimateTime = hours > 0 ? '$hours' : '';
      _seededEstimateDay = hours > 0 ? (hours / 24).toStringAsFixed(1) : '';
      Get.find<TaxiLocationController>().estimateTimeController.text = _seededEstimateTime;
      Get.find<TaxiLocationController>().estimateDayController.text = _seededEstimateDay;
    }
  }

  bool get _isInCart => isExistInCartPosition != -1;

  /// Default the location controller's trip type to one the vehicle actually
  /// supports (its default is `distance_wise`, which this vehicle may not offer).
  /// Uses the existing `selectTripType` — no new state.
  void _ensureSupportedTripType(TaxiLocationController locationController, VehicleModel vehicle) {
    final String t = locationController.tripType;
    final bool supported = (t == 'distance_wise' && vehicle.tripDistance!) ||
        (t == 'hourly' && vehicle.tripHourly!) || (t == 'day_wise' && vehicle.tripDayWise!);
    if(!supported) {
      final String fallback = vehicle.tripDistance! ? 'distance_wise' : vehicle.tripHourly! ? 'hourly' : 'day_wise';
      locationController.selectTripType(fallback, willUpdate: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: GetBuilder<TaxiHomeController>(builder: (taxiHomeController) {
        VehicleModel? vehicle = taxiHomeController.vehicleDetailsModel;

        double discount = 0;
        String discountType = 'percent';
        int totalVehicles = 0;

        if(vehicle != null) {
          totalVehicles = vehicle.totalVehicles != 0 ? vehicle.totalVehicles! : 0;
          discount = vehicle.discountPrice ?? 0;
          discountType = vehicle.discountType ?? 'percent';
        }

        if(vehicle == null) {
          // Silent auto-retry runs in the background (`_loadVehicleDetails`);
          // the loader resolves into the page as soon as a request succeeds.
          return const Center(child: CircularProgressIndicator());
        }

        return GetBuilder<TaxiCartController>(builder: (taxiCartController) {
          return GetBuilder<TaxiLocationController>(builder: (locationController) {

            isExistInCartPosition = taxiCartController.isExistInCart(vehicle.id);

            // Auto-activating APARTMENT presentation (approved Provider-page
            // pattern): the item's REAL category vs the real Short-Apt category.
            // Apartments are per-night → day-wise auto-selected, trip-type row
            // hidden (the design has no trip-type selector). Falls back to the
            // standard car presentation whenever the item is not an apartment.
            final bool isApartmentItem = vehicle.categoryId != null &&
                vehicle.categoryId == RentalApartmentAdapter.apartmentCategoryId(taxiHomeController.vehicleCategoryModel);
            if(!_isInCart) {
              if(isApartmentItem && vehicle.tripDayWise!) {
                if(locationController.tripType != 'day_wise') {
                  locationController.selectTripType('day_wise', willUpdate: false);
                }
              } else {
                _ensureSupportedTripType(locationController, vehicle);
              }
            }

            // The SELECTED trip type: in-cart it is the cart controller's state
            // (seeded from the cart's real rentalType, updated by direct card taps).
            final String tripType = _isInCart ? taxiCartController.tripType : locationController.tripType;

            return Column(children: [
              Expanded(child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  _header(context, vehicle, discount, discountType, isApartmentItem),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      if(vehicle.flashSale != null) ...[
                        _flashSaleBanner(context, vehicle),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ],

                      _whereToGo(context, vehicle, taxiCartController, locationController),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      _sectionTitle(context, (isApartmentItem ? 'check_in' : 'pickup_time').tr),
                      _pickupTime(context, taxiCartController, locationController),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      if(isApartmentItem && vehicle.tripDayWise!) ...[
                        // Apartments are per-night: day-wise is the ONLY real unit —
                        // no trip-type selector (design), just the Nights input on
                        // the same existing estimate controller.
                        _sectionTitle(context, 'nights'.tr),
                        _estimateInputs(context, locationController, tripType, nightsWording: true),
                      ] else if(vehicle.tripHourly! || vehicle.tripDistance! || vehicle.tripDayWise!) ...[
                        _sectionTitle(context, 'trip_type'.tr),
                        _tripTypes(context, vehicle, discount, discountType, taxiCartController),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        _estimateInputs(context, locationController, tripType),
                      ],

                      _amenities(context, vehicle, isApartmentItem),

                      _photoGallery(context, vehicle),

                      _addMoreVehicle(context, taxiCartController),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    ]),
                  ),
                ]),
              )),

              _bottomBar(context, vehicle, taxiCartController, locationController, discount, discountType, totalVehicles, tripType),
            ]);
          });
        });
      }),
    );
  }

  // ── Header (design): light surface, back circle, name, ★rating, 📍location,
  // feature pills, vehicle image right. The location line is the USER's selected
  // address — the same real source every approved MoonJoin header uses
  // (`AddressHelper.getUserAddressFromSharedPref()`), matching the design family
  // where the header location is the browsing context ("Lekki Phase 1"). ──
  Widget _header(BuildContext context, VehicleModel vehicle, double discount, String discountType, bool isApartmentItem) {
    final String? userAddress = AddressHelper.getUserAddressFromSharedPref()?.address;
    return Container(
      width: double.infinity,
      color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      child: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 42, width: 42, alignment: Alignment.center,
              decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge!.color, size: 22),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Padding(
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Text(vehicle.name ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: 24)),
              const SizedBox(height: 6),

              Row(children: [
                if((vehicle.avgRating ?? 0) > 0) ...[
                  Icon(Icons.star, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 3),
                  Text('${vehicle.avgRating!.toStringAsFixed(1)} (${vehicle.totalReviews ?? 0}+)',
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                ],
                if((userAddress ?? '').isNotEmpty) ...[
                  Icon(Icons.location_on_outlined, size: 15, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 2),
                  Flexible(child: Text(userAddress!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor))),
                ],
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Wrap(spacing: Dimensions.paddingSizeExtraSmall, runSpacing: Dimensions.paddingSizeExtraSmall, children: isApartmentItem
                  // Apartment mode: ONLY real fields — AC + the provider's real tags
                  // (Instant Book / Wi-Fi / Pool …). Beds/baths/guests fields do not
                  // exist on the backend yet (queue item 17) — never converted from
                  // car fields, never faked.
                  ? [
                      _featurePill(context, Icons.ac_unit, vehicle.airCondition! ? 'ac'.tr : 'non_ac'.tr),
                      ...RentalApartmentAdapter.amenityTags(vehicle.tag).take(3)
                          .map((t) => _featurePill(context, Icons.check_circle_outline, t)),
                    ]
                  : [
                if((vehicle.seatingCapacity ?? '').isNotEmpty) _featurePill(context, Icons.person_outline, '${vehicle.seatingCapacity} ${'seats'.tr}'),
                if((vehicle.transmissionType ?? '').isNotEmpty) _featurePill(context, Icons.settings_outlined, vehicle.transmissionType!.tr),
                if((vehicle.fuelType ?? '').isNotEmpty) _featurePill(context, Icons.local_gas_station_outlined, vehicle.fuelType!.tr),
                _featurePill(context, Icons.ac_unit, vehicle.airCondition! ? 'ac'.tr : 'non_ac'.tr),
              ]),
            ])),

            Expanded(flex: 4, child: SizedBox(
              height: 130,
              child: CustomImage(image: vehicle.thumbnailFullUrl ?? '', fit: BoxFit.contain),
            )),
          ]),
        ),
      ])),
    );
  }

  Widget _featurePill(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Theme.of(context).textTheme.bodyLarge!.color),
        const SizedBox(width: 4),
        Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ]),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
    );
  }

  // ── Trip location (old-design behaviour) ──
  // No trip context yet → the plain "Where to go?" search bar (hint only, never
  // pre-filled), which opens the EXISTING Location page
  // (`TaxiLocationSuggestionScreen`: pickup + destination, recent & saved, map).
  // Once pickup AND destination are set (or the vehicle is in the cart) → the
  // EXISTING `TripFromToCard` shows both filled, with its edit pencil re-opening
  // the Location page (cart `userData` edit mode when in cart).
  Widget _whereToGo(BuildContext context, VehicleModel vehicle, TaxiCartController taxiCartController, TaxiLocationController locationController) {
    void openLocationPage() => Get.to(() => TaxiLocationSuggestionScreen(
      vehicle: vehicle,
      userData: _isInCart ? taxiCartController.carCartModel?.userData : null,
    ));

    AddressModel? from;
    AddressModel? to;
    if(_isInCart) {
      // Real cart locations, adapted to the card's AddressModel (values only).
      final UserData? u = taxiCartController.carCartModel?.userData;
      if(u?.pickupLocation != null && u?.destinationLocation != null) {
        from = AddressModel(address: u!.pickupLocation!.locationName, latitude: '${u.pickupLocation!.lat}', longitude: '${u.pickupLocation!.lng}');
        to = AddressModel(address: u.destinationLocation!.locationName, latitude: '${u.destinationLocation!.lat}', longitude: '${u.destinationLocation!.lng}');
      }
    } else if(locationController.fromAddress != null && locationController.toAddress != null) {
      from = locationController.fromAddress;
      to = locationController.toAddress;
    }

    if(from != null && to != null) {
      return TripFromToCard(fromAddress: from, toAddress: to, fromCartOnClick: openLocationPage);
    }

    return InkWell(
      onTap: openLocationPage,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(children: [
          Icon(Icons.search, color: Theme.of(context).hintColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(
            'where_to_go'.tr,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
          )),
        ]),
      ),
    );
  }

  // ── Pickup Time — real value (cart's pickupTime when in cart, else the location
  // controller's finalTripDateTime); the pencil opens the EXISTING production
  // DateTimePickerSheet, which already handles both the cart and pre-cart cases. ──
  Widget _pickupTime(BuildContext context, TaxiCartController taxiCartController, TaxiLocationController locationController) {
    final UserData? userData = taxiCartController.carCartModel?.userData;
    String? display;
    DateTime? shownTime;
    if(_isInCart && userData?.pickupTime != null) {
      // Same formatter the existing PickupTimeCard uses for the cart's pickupTime.
      display = DateConverter.dateTimeStringToDateTime(userData!.pickupTime!);
      try { shownTime = DateConverter.dateTimeStringToDate(userData.pickupTime!); } catch (_) {}
    } else if(locationController.finalTripDateTime != null) {
      display = DateConverter.dateToDateAndTime(locationController.finalTripDateTime!);
      shownTime = locationController.finalTripDateTime;
    }
    // Card title (product-owner rule): "Pickup Now" only while the shown time IS
    // now; a user-selected future time reads "Schedule". Title only — the
    // date/time line and all behaviour are unchanged.
    final bool isNow = shownTime == null || shownTime.difference(DateTime.now()).inMinutes.abs() <= 5;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(children: [
        Container(
          height: 44, width: 44, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ),
          child: Icon(Icons.calendar_today_outlined, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((isNow ? 'pickup_now' : 'schedule').tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          if(display != null) ...[
            const SizedBox(height: 2),
            Text(display, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          ],
        ])),

        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
              builder: (_) => DateTimePickerSheet(fromCart: _isInCart, userData: _isInCart ? userData : null),
            );
          },
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor, size: 20),
          ),
        ),
      ]),
    );
  }

  // ── Trip Type — the EXISTING shared TripTypeCard with its radio, selected
  // DIRECTLY on tap in both modes (old-design behaviour, no popup): pre-cart via
  // `TaxiLocationController.selectTripType`, in-cart via
  // `TaxiCartController.selectTripType` — both are the card's own built-in modes.
  // An in-cart change is persisted through the production cart update when the user
  // proceeds to checkout (see `_proceedToCheckout`). ──
  // ── Rental Flash Sale banner (presentation only) ──────────────────────────
  // Renders the backend's authoritative `flash_sale` payload; it NEVER computes a
  // discount. Percent campaigns publish per-axis flash_price → shown vs original
  // (strikethrough) for each axis the campaign applies to AND the vehicle supports.
  // Amount/booking-total campaigns publish no per-unit price → only the flash
  // indicator + headline discount are shown. Existing trip-type cards and booking
  // calculations are untouched.
  Widget _flashSaleBanner(BuildContext context, VehicleModel vehicle) {
    final RentalFlashSale flash = vehicle.flashSale!;
    final Color primary = Theme.of(context).primaryColor;

    final List<Widget> priceRows = [];
    void addAxis(String key, bool supported, String label) {
      final RentalFlashAxisPrice? p = flash.axisPrice(key);
      if (supported && p != null && p.hasFlashPrice) {
        priceRows.add(Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
          child: Row(children: [
            Text('$label:  ', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
            Text(PriceConverter.convertPrice(p.flashPrice, forTaxi: true), textDirection: TextDirection.ltr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: primary)),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            if (p.originalPrice != null)
              Text(PriceConverter.convertPrice(p.originalPrice, forTaxi: true), textDirection: TextDirection.ltr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).disabledColor, decoration: TextDecoration.lineThrough)),
          ]),
        ));
      }
    }
    addAxis('hourly', vehicle.tripHourly ?? false, 'hourly'.tr);
    addAxis('distance_wise', vehicle.tripDistance ?? false, 'distance_wise'.tr);
    addAxis('day_wise', vehicle.tripDayWise ?? false, 'day_wise'.tr);

    final String headline = (flash.discountType == 'percent' && flash.discount != null)
        ? '${flash.discount!.toStringAsFixed(0)}% ${'off'.tr}'
        : (flash.discount != null
            ? '${PriceConverter.convertPrice(flash.discount, forTaxi: true)} ${'off'.tr}'
            : 'flash_sale'.tr);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flash_on, size: 18, color: primary),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(
            child: Text((flash.title != null && flash.title!.isNotEmpty) ? flash.title! : 'flash_sale'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: primary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            child: Text(headline,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).cardColor)),
          ),
        ]),
        if (priceRows.isNotEmpty) ...priceRows,
      ]),
    );
  }

  Widget _tripTypes(BuildContext context, VehicleModel vehicle, double discount, String discountType, TaxiCartController taxiCartController) {
    final double distanceWiseDiscount = PriceConverter.calculation(vehicle.distancePrice!, discount, discountType, 1);
    final double hourlyDiscount = PriceConverter.calculation(vehicle.hourlyPrice!, discount, discountType, 1);
    final double dayWiseDiscount = PriceConverter.calculation(vehicle.dayWisePrice!, discount, discountType, 1);

    Widget card(String tripType, double basePrice, double discounted, String fareType) {
      return TripTypeCard(
        tripType: tripType, amount: PriceConverter.convertPrice(basePrice, forTaxi: true),
        discountAmount: PriceConverter.convertPrice(basePrice - discounted, forTaxi: true),
        fareType: fareType, indicatorIcon: Icons.radio_button_checked,
        isVehicleDetailScene: false, isClockIcon: false, fromVehicleDetails: false,
        fromCart: _isInCart, haveVehicle: true, discountType: discountType,
      );
    }

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        children: [
          if(vehicle.tripDistance!) ...[
            card('distance_wise', vehicle.distancePrice ?? 0, distanceWiseDiscount, 'km'),
            const SizedBox(width: Dimensions.paddingSizeDefault),
          ],
          if(vehicle.tripHourly!) ...[
            card('hourly', vehicle.hourlyPrice ?? 0, hourlyDiscount, 'hr'),
            const SizedBox(width: Dimensions.paddingSizeDefault),
          ],
          if(vehicle.tripDayWise!)
            card('day_wise', vehicle.dayWisePrice ?? 0, dayWiseDiscount, 'day'),
        ],
      ),
    );
  }

  // ── Estimate inputs — the EXISTING controllers and the exact CustomTextField
  // wiring from the production location bottom sheet. Shown in both modes; in-cart
  // they are seeded from the cart's real values and any change is persisted through
  // the production cart update on Proceed. ──
  Widget _estimateInputs(BuildContext context, TaxiLocationController locationController, String tripType, {bool nightsWording = false}) {
    return Column(children: [
      if(tripType == 'hourly') ...[
        CustomTextField(
          controller: locationController.estimateTimeController,
          titleText: 'Ex: 5',
          labelText: '${'estimate_time'.tr}(${'hrs'.tr})',
          isNumber: true,
          inputType: TextInputType.number,
          // Recompute the bottom-bar estimate/price on every keystroke — no
          // trip-type re-tap needed (design: instant calculation, no popup).
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],
      if(tripType == 'day_wise') ...[
        CustomTextField(
          controller: locationController.estimateDayController,
          titleText: nightsWording ? 'Ex: 2' : 'Ex: 2 days',
          labelText: (nightsWording ? 'nights' : 'estimate_days').tr,
          isNumber: true,
          inputType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],
    ]);
  }

  // ── Amenities — the provider's REAL `tag` values (design's Amenities grid).
  // Hidden when the backend sent none; auto-populates as providers tag their
  // apartments. Proper structured amenities = queue item 17. ──
  Widget _amenities(BuildContext context, VehicleModel vehicle, bool isApartmentItem) {
    if(!isApartmentItem) return const SizedBox();
    final List<String> tags = RentalApartmentAdapter.amenityTags(vehicle.tag);
    if(tags.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(context, 'amenities'.tr),
      Wrap(spacing: Dimensions.paddingSizeSmall, runSpacing: Dimensions.paddingSizeSmall, children: tags.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(t, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ]),
      )).toList()),
      const SizedBox(height: Dimensions.paddingSizeLarge),
    ]);
  }

  // ── Photo Gallery — the vehicle's REAL images (`images_full_url`). Hidden when the
  // backend returns none. "See all" expands the full set in place. ──
  Widget _photoGallery(BuildContext context, VehicleModel vehicle) {
    final List<String> images = (vehicle.imagesFullUrl ?? []).whereType<String>().where((i) => i.isNotEmpty).toList();
    if(images.isEmpty) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: Dimensions.paddingSizeSmall),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('photo_gallery'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        if(images.length > 4)
          InkWell(
            onTap: () => setState(() => _showAllPhotos = !_showAllPhotos),
            child: Text(_showAllPhotos ? 'show_less'.tr : 'see_all'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
          ),
      ]),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      _showAllPhotos ? GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: images.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: CustomImage(image: images[index], fit: BoxFit.cover),
        ),
      ) : SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length > 4 ? 4 : images.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(image: images[index], width: 84, height: 84, fit: BoxFit.cover),
          ),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),
    ]);
  }

  // ── "Add More Vehicle +" — the cart screen's EXACT existing behaviour: provider
  // page of the first cart vehicle when the cart has items, otherwise back. ──
  Widget _addMoreVehicle(BuildContext context, TaxiCartController taxiCartController) {
    return InkWell(
      onTap: () {
        if(taxiCartController.cartList.isNotEmpty) {
          Get.to(() => VendorDetailScreen(vendorId: taxiCartController.cartList[0].vehicle!.providerId));
        } else {
          Get.back();
        }
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: Theme.of(context).disabledColor.withValues(alpha: 0.6)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text('${'add_more_vehicle'.tr} +', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
          ]),
        ),
      ),
    );
  }

  // ── Bottom bar — real estimate + real price + Proceed to Checkout. In-cart keeps
  // the frozen shared quantity system (QuantityButton → setQuantity) and the
  // pre-existing price calculation; pre-cart shows the selected trip type's real
  // start-from price (the trip total only exists once the trip context is in the
  // cart, exactly as before). ──
  Widget _bottomBar(BuildContext context, VehicleModel vehicle, TaxiCartController taxiCartController,
      TaxiLocationController locationController, double discount, String discountType, int totalVehicles, String tripType) {

    int quantity = 1;
    int cartId = 0;
    double price = 0;
    String estimateLabel;

    final double estimatedDay = (taxiCartController.carCartModel?.userData?.estimatedHours ?? 0) / 24;

    if(_isInCart) {
      quantity = taxiCartController.getCartQuantity(isExistInCartPosition);
      cartId = taxiCartController.getCartId(isExistInCartPosition) ?? 0;
      // The SELECTED type (cart controller state, seeded from the cart's real
      // rentalType) with the current estimate inputs — so a direct card selection
      // is reflected immediately, old-design style.
      final String rentalType = tripType;
      final double inputHours = double.tryParse(locationController.estimateTimeController.text) ?? (taxiCartController.carCartModel?.userData?.estimatedHours ?? 0);
      final double inputDays = double.tryParse(locationController.estimateDayController.text) ?? estimatedDay;

      // Flash Sale-aware applicable rate (backend flash price when the campaign
      // targets this axis, else the original rate). Flash already embeds the
      // saving, so the vehicle discount is not stacked on top when flash applies.
      final double a = vehicle.applicableRate(rentalType);
      final double b = rentalType == AppConstants.hourly ? inputHours
          : rentalType == AppConstants.dayWise ? inputDays : (taxiCartController.carCartModel!.userData!.distance ?? 0);
      final double priceWithoutDiscount = (a * b) * cartQuantity;
      price = priceWithoutDiscount - (vehicle.hasFlashRate(rentalType) ? 0 : _calculateDiscount(priceWithoutDiscount, discount, discountType, vehicle));

      estimateLabel = rentalType == AppConstants.hourly
          ? '${'estimated'.tr} $inputHours ${'hr'.tr}'
          : rentalType == AppConstants.dayWise
              ? '${'duration'.tr} ${inputDays.toStringAsFixed(0)} ${'day'.tr}'
              : '${'estimated'.tr} ${taxiCartController.carCartModel?.userData?.distance?.toStringAsFixed(3) ?? 0} ${'km'.tr}';
    } else {
      // Pre-cart (design behaviour): the selected type's real start-from price
      // until trip context exists; once it does (real distance from the map
      // confirm, or a typed estimate), the REAL total: rate × units − discount —
      // the same maths the in-cart branch and the cart backend use.
      // Flash Sale-aware applicable rate — same rule as the in-cart branch.
      final double base = vehicle.applicableRate(tripType);
      final bool flashApplies = vehicle.hasFlashRate(tripType);
      final double units = tripType == 'hourly'
          ? (double.tryParse(locationController.estimateTimeController.text) ?? 0)
          : tripType == 'day_wise'
              ? (double.tryParse(locationController.estimateDayController.text) ?? 0)
              : ((locationController.distance ?? -1) > 0 ? locationController.distance! : 0);
      if(units > 0) {
        final double priceWithoutDiscount = base * units;
        price = priceWithoutDiscount - (flashApplies ? 0 : _calculateDiscount(priceWithoutDiscount, discount, discountType, vehicle));
      } else {
        price = flashApplies ? base : (base - PriceConverter.calculation(base, discount, discountType, 1));
      }

      estimateLabel = tripType == 'hourly'
          ? '${'estimated'.tr} ${locationController.estimateTimeController.text.isEmpty ? 0 : locationController.estimateTimeController.text} ${'hr'.tr}'
          : tripType == 'day_wise'
              ? '${'estimate_days'.tr}: ${locationController.estimateDayController.text.isEmpty ? 0 : locationController.estimateDayController.text}'
              : '${'estimated'.tr} ${(locationController.distance ?? -1) > 0 ? locationController.distance!.toStringAsFixed(3) : '0.000'} ${'km'.tr}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusLarge)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(estimateLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault))),
          Text(PriceConverter.convertPrice(price, forTaxi: true),
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor)),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        SafeArea(top: false, child: Row(children: [

          if(_isInCart) ...[
            Row(children: [
              QuantityButton(
                onTap: taxiCartController.isLoading ? null : () {
                  if (quantity > 1) {
                    setState(() {
                      if(cartQuantity > 1) {
                        cartQuantity--;
                      }
                    });
                    taxiCartController.setQuantity(true, isExistInCartPosition, count: cartQuantity);
                  } else {
                    taxiCartController.removeFromCart(cartId);
                  }
                },
                isIncrement: false,
                showRemoveIcon: quantity == 1 || cartQuantity == 1,
              ),
              Text(cartQuantity.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
              QuantityButton(
                onTap: taxiCartController.isLoading ? null : () {
                  if(totalVehicles > cartQuantity) {
                    setState(() {
                      cartQuantity++;
                    });
                    taxiCartController.setQuantity(true, isExistInCartPosition, count: cartQuantity);
                  } else {
                    showCustomSnackBar('${'you_cant_add_more_than'.tr} $totalVehicles ${'quantities_of_this_vehicle'.tr}');
                  }
                },
                isIncrement: true,
                color: taxiCartController.isLoading || cartQuantity == totalVehicles ? Theme.of(context).disabledColor : null,
              ),
            ]),
            const SizedBox(width: Dimensions.paddingSizeSmall),
          ],

          Expanded(child: CustomButton(
            buttonText: 'proceed_to_checkout'.tr,
            isLoading: taxiCartController.isLoading,
            onPressed: () => _proceedToCheckout(taxiCartController, locationController, vehicle),
          )),
        ])),
      ]),
    );
  }

  /// Design flow: Vehicle Details → Checkout. The cart REMAINS the single source the
  /// production `TaxiCheckoutScreen` reads — so "Proceed" first ensures this vehicle
  /// is in the cart through the EXISTING `_addToCart` logic (identical validation to
  /// the production location bottom sheet), then opens the existing checkout.
  Future<void> _proceedToCheckout(TaxiCartController taxiCartController, TaxiLocationController locationController, VehicleModel vehicle) async {
    if(_isInCart) {
      final UserData? userData = taxiCartController.carCartModel?.userData;
      final String selectedType = taxiCartController.tripType;
      final bool typeChanged = userData?.rentalType != null && selectedType != userData!.rentalType;
      final bool estimateChanged = (selectedType == 'hourly' && locationController.estimateTimeController.text != _seededEstimateTime) ||
          (selectedType == 'day_wise' && locationController.estimateDayController.text != _seededEstimateDay);

      if((typeChanged || estimateChanged) && userData?.id != null) {
        // EXACT persist logic of the production TripTypeBottomSheetWidget "update":
        // validate estimate → checkTypeInCart → CarCart(applyMethod) →
        // updateUserData/getCarCartList, or the existing TripVehicleListDialog.
        if(selectedType == 'hourly' && (locationController.estimateTimeController.text.isEmpty || (double.tryParse(locationController.estimateTimeController.text) ?? 0) == 0)) {
          showCustomSnackBar('please_enter_estimate_time'.tr, getXSnackBar: true);
          return;
        }
        if(selectedType == 'day_wise' && (locationController.estimateDayController.text.isEmpty || (double.tryParse(locationController.estimateDayController.text) ?? 0) == 0)) {
          showCustomSnackBar('please_enter_estimate_days'.tr, getXSnackBar: true);
          return;
        }

        bool isCartExistType = await CartHelper.checkTypeInCart(taxiCartController.cartList, selectedType);
        double estimatedDay = (double.tryParse(locationController.estimateDayController.text) ?? 0) * 24;

        CarCart cart = CarCart(
          applyMethod: true, distance: userData!.distance, destinationTime: userData.destinationTime,
          rentalType: selectedType,
          estimatedHour: selectedType == 'hourly' ? locationController.estimateTimeController.text
              : selectedType == 'day_wise' ? estimatedDay.toStringAsFixed(1) : '${userData.estimatedHours ?? 0}',
        );

        if(isCartExistType) {
          final bool success = await taxiCartController.updateUserData(cart: cart, userId: userData.id!);
          if(!success) return;
          await taxiCartController.getCarCartList();
          _seededEstimateTime = locationController.estimateTimeController.text;
          _seededEstimateDay = locationController.estimateDayController.text;
        } else {
          Get.dialog(TripVehicleListDialog(rentalType: selectedType, cart: cart, userId: userData.id!));
          return;
        }
      }

      Get.to(() => const TaxiCheckoutScreen());
      return;
    }

    // No trip context yet → the existing destination flow (it computes the real
    // distance/duration and returns here).
    if(taxiCartController.cartList.isEmpty && locationController.toAddress == null) {
      Get.to(() => TaxiLocationSuggestionScreen(vehicle: vehicle));
      return;
    }

    // Same validation the production location bottom sheet performs.
    if(locationController.finalTripDateTime == null) {
      showCustomSnackBar('please_select_pickup_time'.tr);
      return;
    }
    if(locationController.tripType == 'hourly' &&
        (locationController.estimateTimeController.text.isEmpty || (double.tryParse(locationController.estimateTimeController.text) ?? 0) <= 0)) {
      showCustomSnackBar(locationController.estimateTimeController.text.isEmpty ? 'please_enter_estimate_time'.tr : 'please_enter_valid_estimate_time'.tr);
      return;
    }
    if(locationController.tripType == 'day_wise' &&
        (locationController.estimateDayController.text.isEmpty || (double.tryParse(locationController.estimateDayController.text) ?? 0) <= 0)) {
      showCustomSnackBar('please_enter_estimate_time'.tr);
      return;
    }

    final bool wasEmpty = taxiCartController.cartList.isEmpty;
    _addToCart(taxiCartController, vehicle);

    // `_addToCart`'s multi-vehicle path (`decideAddToCart`) runs its own existing
    // dialog flow — never auto-navigate over it. Only the simple empty-cart path is
    // followed to checkout once the backend confirms the add.
    if(wasEmpty && locationController.toAddress != null) {
      // addToCart is async inside _addToCart; wait for the controller to finish.
      while(taxiCartController.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if(taxiCartController.isExistInCart(vehicle.id) != -1) {
        Get.to(() => const TaxiCheckoutScreen());
      }
    }
  }

  // ── Pre-existing business logic, unchanged ──

  void _addToCart(TaxiCartController taxiCartController, VehicleModel vehicle) {

    if((taxiCartController.cartList.isEmpty && Get.find<TaxiLocationController>().toAddress == null)) {
      Get.to(()=> TaxiLocationSuggestionScreen(vehicle: vehicle));
    }
    else if (taxiCartController.cartList.isNotEmpty) {

      CartLocation pick = CartLocation(lat: taxiCartController.carCartModel!.userData!.pickupLocation!.lat, lng: taxiCartController.carCartModel!.userData!.pickupLocation!.lng, locationName: taxiCartController.carCartModel!.userData!.pickupLocation!.locationName);
      CartLocation destination = CartLocation(lat: taxiCartController.carCartModel!.userData!.destinationLocation!.lat, lng: taxiCartController.carCartModel!.userData!.destinationLocation!.lng, locationName: taxiCartController.carCartModel!.userData!.destinationLocation!.locationName);
      double? estimatedDay = (taxiCartController.carCartModel!.userData!.estimatedHours ?? 0) * 24;

      CarCart cart = CarCart(
        vehicleId: vehicle.id, quantity: 1, pickupLocation: pick, destinationLocation: destination,
        pickupTime: taxiCartController.carCartModel!.userData!.pickupTime,
        rentalType: taxiCartController.carCartModel!.userData!.rentalType, estimatedHour: taxiCartController.carCartModel!.userData!.rentalType == 'day_wise' ? estimatedDay.toStringAsFixed(0) : taxiCartController.carCartModel!.userData!.estimatedHours.toString(),
        destinationTime: taxiCartController.carCartModel!.userData!.destinationTime, distance: taxiCartController.carCartModel!.userData!.distance,
      );

      taxiCartController.decideAddToCart(taxiCartController, cart, vehicle);

    }
    else {

      CartLocation pick = CartLocation(
        lat: Get.find<TaxiLocationController>().fromAddress!.latitude,
        lng: Get.find<TaxiLocationController>().fromAddress!.longitude,
        locationName: Get.find<TaxiLocationController>().fromAddress!.address,
      );
      CartLocation destination = CartLocation(
        lat: Get.find<TaxiLocationController>().toAddress!.latitude,
        lng: Get.find<TaxiLocationController>().toAddress!.longitude,
        locationName: Get.find<TaxiLocationController>().toAddress!.address,
      );

      double? estimatedDay = (double.tryParse(Get.find<TaxiLocationController>().estimateDayController.text) ?? 0) * 24;

      CarCart cart = CarCart(
        vehicleId: vehicle.id, quantity: 1, pickupLocation: pick, destinationLocation: destination,
        pickupTime: DateConverter.formatDate(Get.find<TaxiLocationController>().finalTripDateTime!),
        rentalType: Get.find<TaxiLocationController>().tripType, estimatedHour: Get.find<TaxiLocationController>().tripType == 'day_wise' ? estimatedDay.toStringAsFixed(0) : Get.find<TaxiLocationController>().estimateTimeController.text,
        destinationTime: Get.find<TaxiLocationController>().duration, distance: Get.find<TaxiLocationController>().distance,
      );

      taxiCartController.addToCart(cart);
    }
  }

  double _calculateDiscount(double priceWithoutDiscount, double discount, String discountType, VehicleModel vehicle) {
    double discountPrice = 0;
    if(discountType == 'amount') {
      discountPrice = PriceConverter.calculation(priceWithoutDiscount, discount, discountType, cartQuantity);

    } else {
      double pPrice = PriceConverter.convertWithDiscount(priceWithoutDiscount, discount, discountType)!;
      discountPrice = priceWithoutDiscount - pPrice;
    }

    return discountPrice > priceWithoutDiscount ? priceWithoutDiscount : discountPrice;
  }
}

/// Rounded dashed border for the "Add More Vehicle +" affordance (the design's
/// dashed container). Pure presentation, local to this screen.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6;
    const double dashSpace = 4;
    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(Dimensions.radiusDefault)));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
