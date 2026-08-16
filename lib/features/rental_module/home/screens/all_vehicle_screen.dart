import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/moonjoin/loading_skeleton.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/rant_cart_widget.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/banner_widget.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/rental_popular_card.dart';
import 'package:sixam_mart/features/rental_module/vehicle_details_screen/vehicle_details_screen.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/features/rental_module/select_vehicle_screen/search_vehicle_screen.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/rental_module/provider_adapter/rental_apartment_adapter.dart';
import 'package:sixam_mart/features/rental_module/provider_adapter/rental_provider_adapter.dart';
import 'package:sixam_mart/features/rental_module/provider_adapter/rental_provider_card.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/vendor_detail_screen.dart';
import 'package:sixam_mart/features/store/widgets/all_restaurants_widgets.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Rental Screen 2 — **Car Rental Listing** (`ui-designs/Car_Rental/car_rental.png`).
///
/// PAGE-LEVEL REUSE: this reproduces the approved MoonJoin **All Restaurants** page
/// architecture (`AllStoreScreen`) section-for-section — app bar, search, category row,
/// filter chips, banner, Top Brands, paginated list — and replaces only the data with
/// Rental data. Every widget is an already-approved shared component; nothing is
/// duplicated and nothing is redesigned.
///
/// FILTERING (audited): the browse endpoint `getTopRatedCarList(offset)` takes ONLY an
/// offset — it has no category/brand/sort parameters. `category_ids` exists only on
/// `getSelectedCars(...)`, which requires pickup time + location. So:
///   • Sort / Top Rated  → real client-side sort of the loaded vehicles (Food pattern).
///   • Search            → the existing Rental Search screen (never the Location screen).
///   • Filters, Self Drive, With Driver, browse category, Top Brands → rendered but
///     INERT pending backend; never routed to an unrelated screen, never faked.
/// See docs/BACKEND_INTEGRATION_QUEUE.md items 11-13.
class AllVehicleScreen extends StatefulWidget {
  /// Additive apartment mode (default false — Car Rental behaviour unchanged).
  /// ONE unified Rental listing page: apartment mode changes only wording, the
  /// inert chip labels, and the data filter (real Short-Apt category via
  /// `RentalApartmentAdapter`). Same architecture, components and discovery flow.
  final bool fromApartment;
  const AllVehicleScreen({super.key, this.fromApartment = false});

  @override
  State<AllVehicleScreen> createState() => _AllVehicleScreenState();
}

class _AllVehicleScreenState extends State<AllVehicleScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Active client-side sort: -1 none, 0 top rated, 1 price (low→high).
  int _activeSort = -1;

  /// Client-side sort for the chips — operates on the already-loaded list, exactly like
  /// the approved Food All Restaurants implementation: **no new API calls, no fake
  /// data**. It reorders real backend vehicles using real backend fields.
  List<VehicleModel> _applySort(List<VehicleModel> list) {
    final result = List<VehicleModel>.from(list);
    if (_activeSort == 0) {
      result.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
    } else if (_activeSort == 1) {
      double price(VehicleModel v) => v.dayWisePrice ?? v.hourlyPrice ?? v.distancePrice ?? 0;
      result.sort((a, b) => price(a).compareTo(price(b)));
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    final controller = Get.find<TaxiHomeController>();
    controller.getTopRatedCarList(1, false);
    controller.getVehicleCategoryList();
    controller.getTaxiBrandList(1, reload: false);
  }

  /// Search opens the existing Rental Search screen (approved Food behaviour).
  /// It must NEVER open the Location screen. The location / trip-context flow is
  /// untouched and still used by the booking journey and vehicle-selection flow.
  void _openSearch() => Get.to(() => const SearchVehicleScreen());

  /// Toggle a client-side sort (tapping the active one clears it) — mirrors the
  /// approved Food chip behaviour.
  void _toggleSort(int i) => setState(() => _activeSort = _activeSort == i ? -1 : i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: GetBuilder<TaxiHomeController>(builder: (taxiHomeController) {
          final vehicles = taxiHomeController.topRatedCarsModel?.vehicles;
          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _appBar(context),
              _searchBar(context),
              _categoryChips(taxiHomeController),
              _filterChips(context),

              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              // Section-scoped banners: Car listing shows Car content only, the
              // Apartment listing Apartment content only (Main Rental Home keeps
              // both via the default `all`). Adapter-classified — queue item 18.
              BannerWidget(section: widget.fromApartment ? RentalSection.apartment : RentalSection.car),

              // Apartment mode: the brand API returns VEHICLE brands only — no real
              // apartment brand data exists, so the section is hidden (never faked).
              // TODO(BACKEND, queue item 17): when the brand API can return apartment
              // brands/platforms, remove this gate (or filter by brand type) — the
              // section itself is UNCHANGED and reactivates without any redesign.
              if (!widget.fromApartment) _topBrands(context, taxiHomeController),

              const SizedBox(height: Dimensions.paddingSizeSmall),
              // Dedicated Flash Deals section — placed BELOW the brand section,
              // matching the established Food/Grocery/Ecommerce Flash Sale placement
              // (after brands, before the provider/listing). Rental-level: the Car
              // Rental Home shows car flash vehicles and the Short Apartments Home
              // shows apartment flash vehicles (apartment mode has no brand section,
              // so it sits directly below the banner — the analogous position).
              // Backend-authoritative (flashSale != null); category split via the
              // existing RentalApartmentAdapter. Self-hides when none qualify.
              _flashDeals(context, taxiHomeController, vehicles),

              const SizedBox(height: Dimensions.paddingSizeSmall),
              _providerList(context, taxiHomeController, vehicles),
            ]),
          );
        }),
      ),
    );
  }

  // ── App bar — approved All Restaurants pattern (back + title + search) ──
  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      child: Row(children: [
        _circleButton(context, Icons.arrow_back, () => Get.back()),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(child: Text((widget.fromApartment ? 'short_apartments' : 'all_car_rentals').tr, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge))),
        const RantCartWidget(),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        _circleButton(context, Icons.search, _openSearch),
      ]),
    );
  }

  Widget _circleButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 44, width: 44,
        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.10), shape: BoxShape.circle),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
      ),
    );
  }

  // ── Search — approved All Restaurants search field, Rental hint ──
  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: _openSearch,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
          child: Row(children: [
            Icon(Icons.search, color: Theme.of(context).hintColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Text('search_for_cars_brands_or_locations'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault))),
            Container(width: 1, height: 24, color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 22),
          ]),
        ),
      ),
    );
  }

  // ── Category row — THE shared MoonJoin Category Component, REAL Rental categories ──
  // Backend has no browse-mode category filtering, so a tap enters the trip flow.
  Widget _categoryChips(TaxiHomeController taxiHomeController) {
    // Section-scoped categories (adapter split of the REAL list — queue item 18):
    // Car listing → non-apartment categories; Apartment listing → apartment ones.
    final categories = RentalApartmentAdapter.sectionCategories(
      taxiHomeController.vehicleCategoryModel,
      widget.fromApartment ? RentalSection.apartment : RentalSection.car,
    );
    if (categories.isEmpty) return const SizedBox();
    // THE approved MoonJoin category component (`RestaurantCategoryChip`) — the same
    // one used by Food/All Restaurants and every approved module. Rental shares it;
    // only the backend data differs. Never substitute another category widget here.
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) {
          final c = categories[index];
          return RestaurantCategoryChip(
            label: c.name ?? '', imageUrl: c.imageFullUrl, index: index,
            // Rental category artwork is transparent icon PNGs, not photos, so the
            // default inset made them read small. Additive overrides only — every
            // other module keeps the default behaviour untouched.
            imagePadding: const EdgeInsets.all(4),
            // TODO(BACKEND): browse category filtering needs backend support; inert
            // rather than navigating to an unrelated screen.
          );
        },
      ),
    );
  }

  // ── Filter chips — approved StoreFilterChip, nothing faked. ──
  //
  // VEHICLE filtering (Filters / Sort) is real: it needs pickup location + time, so it
  // opens the existing approved trip-context flow → SelectVehicleScreen, where the
  // existing backend filters.
  //
  // PROVIDER filtering (Self Drive / With Driver / Top Rated) is intentionally INERT.
  // The Rental backend exposes no provider list/search endpoint — every provider API
  // requires an already-known provider id — so provider filtering cannot be performed
  // at all. The chips stay rendered (production-ready UI, integration point ready) but
  // do NOT navigate to the pickup flow, because that is not what they mean, and they do
  // NOT fake filtering. They activate unchanged once the provider endpoints exist.
  // Backend + Vendor App + Admin contract: docs/BACKEND_INTEGRATION_QUEUE.md item 9.
  Widget _filterChips(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        // Multi-criteria vehicle filtering needs pickup context → existing trip flow.
        StoreFilterChip(label: 'filters'.tr, icon: Icons.tune, iconColor: primary, labelColor: primary),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        // Sort + Top Rated sort the loaded list CLIENT-SIDE on real backend fields,
        // exactly like the approved Food chips — no API call, no fake data.
        StoreFilterChip(label: 'sort'.tr, trailingDropdown: true, selected: _activeSort == 1, onTap: () => _toggleSort(1)),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        // Provider filtering — awaiting backend/vendor. Rendered, not wired. TODO(BACKEND)
        StoreFilterChip(label: (widget.fromApartment ? 'instant_book' : 'self_drive').tr,
            icon: widget.fromApartment ? Icons.bolt_outlined : Icons.drive_eta_outlined, iconColor: primary),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: (widget.fromApartment ? 'free_cancellation' : 'with_driver').tr,
            icon: widget.fromApartment ? Icons.verified_outlined : Icons.person_outline, iconColor: primary),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'top_rated'.tr, icon: Icons.star, iconColor: Colors.amber.shade700, selected: _activeSort == 0, onTap: () => _toggleSort(0)),
      ]),
    );
  }

  // ── Top Brands — approved section + TopBrandCard, REAL Rental brand backend.
  // showCount:false because the Rental brand API has no vehicles_count yet (documented
  // in docs/BACKEND_INTEGRATION_QUEUE.md) — never show a fabricated "0+". ──
  Widget _topBrands(BuildContext context, TaxiHomeController taxiHomeController) {
    final brands = taxiHomeController.taxiBrandModel?.brands;
    if (brands == null || brands.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
        child: Text('top_brands'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      ),
      SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: brands.length,
          separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            final b = brands[index];
            return TopBrandCard(
              name: b.name ?? '', imageUrl: b.imageFullUrl,
              showCount: false, // TODO(BACKEND): pass vehicles_count once the API supplies it.
              // TODO(BACKEND): brand filtering has no browse endpoint — inert, never
              // routed to an unrelated screen. See BACKEND_INTEGRATION_QUEUE.md.
            );
          },
        ),
      ),
    ]);
  }

  // ── Vehicle list — existing shared VehicleCard + approved PaginatedListView ──
  // ── Provider banners — mirrors the approved Food All Restaurants flow:
  // ── Dedicated Flash Deals section (Car Rental Home / Short Apartments Home) ──
  // Backend-authoritative: shows only vehicles the backend flagged with an active
  // flash_sale, split by category via the existing RentalApartmentAdapter so car
  // flash appears only on the Car home and apartment flash only on the Apt home.
  // Reuses RentalPopularCard (with its new flash badge). Self-hides when empty, so
  // expired/exhausted/ineligible campaigns (backend → flash_sale null) simply drop.
  Widget _flashDeals(BuildContext context, TaxiHomeController taxiHomeController, List<VehicleModel>? vehicles) {
    if (vehicles == null) return const SizedBox();
    final int? aptId = RentalApartmentAdapter.apartmentCategoryId(taxiHomeController.vehicleCategoryModel);
    final List<VehicleModel> flashVehicles = vehicles.where((v) {
      if (v.flashSale == null || v.status != 1) return false;
      final bool isApt = aptId != null && v.categoryId == aptId;
      return widget.fromApartment ? isApt : !isApt;
    }).toList();
    if (flashVehicles.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
        child: Row(children: [
          Icon(Icons.flash_on, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text('flash_sale'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ]),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: flashVehicles.length,
          separatorBuilder: (_, i) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, i) {
            final VehicleModel v = flashVehicles[i];
            // Feature the day-wise axis (matches the "/day" unit). Show the flash
            // price as the headline and the original struck-through — all from the
            // backend flash data via the Rental-level model helpers (never hardcoded).
            // When this axis carries no per-unit flash price (e.g. an amount campaign
            // or a campaign scoped to another axis), fall back to the original price
            // with no strikethrough — the badge still marks the Flash Sale state.
            const String dayAxis = 'day_wise';
            final bool dayFlash = v.hasFlashRate(dayAxis);
            return RentalPopularCard(
              image: v.thumbnailFullUrl ?? '',
              title: v.name ?? '',
              subtitle: '${v.transmissionType ?? ''}${(v.transmissionType != null && v.fuelType != null) ? ' • ' : ''}${v.fuelType ?? ''}',
              price: PriceConverter.convertPrice(v.applicableRate(dayAxis)),
              unit: ' /${'day'.tr}',
              originalPrice: dayFlash ? PriceConverter.convertPrice(v.baseRate(dayAxis)) : null,
              rating: v.avgRating ?? 0,
              showBookNow: true,
              flashSale: v.flashSale,
              onTap: () => Get.to(() => VehicleDetailsScreen(vehicleId: v.id)),
              onBook: () => Get.to(() => VehicleDetailsScreen(vehicleId: v.id)),
            );
          },
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
    ]);
  }

  // Provider banner → Provider page → Vehicle list. Providers are derived from the
  // REAL backend `provider` object embedded in each vehicle (see
  // RentalProviderAdapter) because no provider list endpoint exists yet; when it
  // ships, only the adapter changes — this UI stays identical. ──
  Widget _providerList(BuildContext context, TaxiHomeController taxiHomeController, List<VehicleModel>? vehicles) {
    if (vehicles == null) return const _ProviderListShimmer();

    // Apartment mode: keep only REAL inventory in the real Short-Apt category
    // (RentalApartmentAdapter). Zero apartments listed → honest empty state; Car
    // data is NEVER converted into apartment data.
    List<VehicleModel> inventory = vehicles;
    if (widget.fromApartment) {
      final int? aptCategoryId = RentalApartmentAdapter.apartmentCategoryId(taxiHomeController.vehicleCategoryModel);
      inventory = RentalApartmentAdapter.filterApartments(vehicles, aptCategoryId);
      if (inventory.isEmpty) return NoDataScreen(text: 'no_apartment_available'.tr);
    }
    if (inventory.isEmpty) return const SizedBox();

    // Sort the vehicles first so the derived provider order follows the active chip.
    final List<RentalProvider> providers = RentalProviderAdapter.fromVehicles(_applySort(inventory));
    if (providers.isEmpty) return const SizedBox();

    return PaginatedListView(
      scrollController: _scrollController,
      totalSize: taxiHomeController.topRatedCarsModel!.totalSize,
      offset: taxiHomeController.topRatedCarsModel!.offset,
      onPaginate: (int? offset) async => await taxiHomeController.getTopRatedCarList(offset!, false),
      itemView: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: providers.length,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: 50),
        separatorBuilder: (_, i) => const SizedBox(height: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) {
          final RentalProvider p = providers[index];
          return RentalProviderCard(
            provider: p,
            // Provider page = the existing approved rental vendor detail screen,
            // which already lists that provider's vehicles.
            onTap: () => Get.to(() => VendorDetailScreen(vendorId: p.id)),
          );
        },
      ),
    );
  }
}

/// Loading state for the vehicle list — reuses the shared MoonJoin skeleton primitives.
class _ProviderListShimmer extends StatelessWidget {
  const _ProviderListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      itemCount: 4,
      separatorBuilder: (_, i) => const SizedBox(height: Dimensions.paddingSizeDefault),
      itemBuilder: (context, i) => const MoonjoinSkeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(height: 150, radius: Dimensions.radiusDefault),
          SizedBox(height: Dimensions.paddingSizeSmall),
          SkeletonBox(height: 14, width: 180, radius: Dimensions.radiusSmall),
          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          SkeletonBox(height: 12, width: 240, radius: Dimensions.radiusSmall),
        ]),
      ),
    );
  }
}
