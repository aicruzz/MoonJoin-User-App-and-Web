import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/moonjoin/loading_skeleton.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/features/rental_module/common/widgets/vehicle_filter_widget.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/select_vehicle_screen/search_vehicle_screen.dart';
import 'package:sixam_mart/features/rental_module/vendor/controllers/taxi_vendor_controller.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/models/taxi_vendor_model.dart';
import 'package:sixam_mart/features/rental_module/vendor/screens/review_details_screen.dart';
import 'package:sixam_mart/features/rental_module/vendor/widgets/rental_provider_hero_header.dart';
import 'package:sixam_mart/features/rental_module/vendor/widgets/vendor_vehicle_card.dart';
import 'package:sixam_mart/features/store/widgets/all_restaurants_widgets.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import '../widgets/provider_banner_widget.dart';

/// **Rental Screen 4 — Provider Details** (a provider's vehicle list).
///
/// Design authority: `ui-designs/Car_Rental/car_rental_provider_item_list.png`
/// (Rental is not in the Active Figma). Page architecture reuses the approved
/// MoonJoin **Store page** (`store_or_restaurant.png`) exactly as recorded in
/// MIGRATION_LOG.md: green hero → search pill → filter chips → categories →
/// "N found" + sort → paginated item list.
///
/// **Presentation only.** Every controller call, API, filter, search, category and
/// pagination behaviour is the pre-existing rental implementation, unchanged.
class VendorDetailScreen extends StatefulWidget {
  final int? vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  String searchName = '';

  /// Selected category id. The controller prepends an "All" entry with id `-1`,
  /// which the repository maps to an unfiltered request — so `-1` is the initial
  /// selection, matching the unfiltered list shown on first load.
  int? _selectedCategoryId = -1;

  /// Client-side sort of the already-loaded REAL vehicles, identical to the approved
  /// Food chips and to frozen Screen 2: `-1` none · `0` top rated (`avg_rating`) ·
  /// `1` price (real day/hourly/distance price). No API call, no fake data.
  int _activeSort = -1;

  @override
  void initState() {
    super.initState();

    Get.find<TaxiVendorController>().setCategoryId(null, canUpdate: false);
    Get.find<TaxiVendorController>().getTaxiVendorDetails(widget.vendorId!);
    Get.find<TaxiVendorController>().getVendorBannerList(widget.vendorId!);
    Get.find<TaxiVendorController>().getVendorVehicleList(offset: 1, vendorId: widget.vendorId!, searchName: '', canUpdate: false);
    Get.find<TaxiVendorController>().getVendorVehicleCategoryList();
    Get.find<TaxiVendorController>().initFilterSetup(maxPrice: 0, willUpdate: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  void _toggleSort(int mode) => setState(() => _activeSort = _activeSort == mode ? -1 : mode);

  /// Existing rental vehicle search — unchanged behaviour, unchanged callback.
  void _openSearch(TaxiVendorController vendorController) {
    if (vendorController.taxiVendorVehicleList == null) return;
    Get.to(() => const SearchVehicleScreen())?.then((value) async {
      if (value != null) {
        setState(() => searchName = value);
        await vendorController.getVendorVehicleList(offset: 1, vendorId: widget.vendorId!, searchName: value, canUpdate: false);
      }
    });
  }

  /// Existing rental filter sheet — real backend filters (price range, brands,
  /// vehicle type, seats, air conditioning).
  void _openFilter(TaxiVendorController vendorController) {
    if (vendorController.taxiVendorVehicleList == null) return;
    final double maxPrice = vendorController.taxiVendorVehicleList?.maxPrice ?? 1000;
    Get.bottomSheet(
      VehicleFilterWidget(
        searchCarName: searchName,
        vendorId: widget.vendorId,
        minPrice: vendorController.taxiVendorVehicleList?.minPrice ?? 0,
        maxPrice: maxPrice,
      ),
      backgroundColor: Colors.transparent, isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<TaxiVendorController>(builder: (vendorController) {
        final TaxiVendorModel? vendor = vendorController.taxiVendor;

        if (vendor == null) {
          return const _ProviderDetailShimmer();
        }

        final int totalSize = vendorController.taxiVendorVehicleList?.totalSize ?? 0;

        // Hero shows the provider's REAL total (`total_vehicle_count` from
        // get-provider-details) so it does not shrink when a category or search
        // narrows the list; the result header below shows the narrowed count.
        final int providerTotal = vendor.totalVehicleCount ?? totalSize;

        return CustomScrollView(controller: _scrollController, slivers: [

          SliverToBoxAdapter(child: RentalProviderHeroHeader(
            vendor: vendor,
            vehicleCount: providerTotal,
            onSearchTap: () => _openSearch(vendorController),
            onFilterTap: () => _openFilter(vendorController),
            onRatingTap: () => Get.to(() => ReviewDetailsScreen(providerID: vendor.id, providerName: vendor.name)),
          )),

          SliverToBoxAdapter(child: _filterChips(context, vendorController)),

          SliverToBoxAdapter(child: Column(children: [
            _announcement(context, vendor),
            _discount(context, vendor),
            ProviderBannerWidget(taxiVendorController: vendorController),
            _categories(context, vendorController),
            _activeSearchChip(context, vendorController),
            _resultHeader(context, totalSize),
          ])),

          SliverToBoxAdapter(child: _vehicleList(context, vendorController)),
        ]);
      }),
    );
  }

  // ── Filter chips — approved shared `StoreFilterChip`, same row the Store page uses.
  // Filters / Price / Seats / More open the EXISTING rental filter sheet (real backend
  // filtering). Sort sorts the loaded real vehicles client-side, exactly like the
  // approved Food chips and frozen Screen 2.
  //
  // Transmission is rendered but INERT: the rental vehicle API exposes
  // `transmission_type` on each vehicle but has **no transmission filter parameter**,
  // and the existing filter sheet has no transmission section. It is not wired to an
  // unrelated screen and it does not fake filtering — it activates unchanged once the
  // backend supports it. See docs/BACKEND_INTEGRATION_QUEUE.md item 14.
  Widget _filterChips(BuildContext context, TaxiVendorController vendorController) {
    final Color primary = Theme.of(context).primaryColor;
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Row(children: [
          StoreFilterChip(label: 'filters'.tr, icon: Icons.tune, iconColor: primary, labelColor: primary, onTap: () => _openFilter(vendorController)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          StoreFilterChip(label: 'sort'.tr, trailingDropdown: true, selected: _activeSort == 1, onTap: () => _toggleSort(1)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          StoreFilterChip(label: 'price'.tr, icon: Icons.sell_outlined, onTap: () => _openFilter(vendorController)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          StoreFilterChip(label: 'seats'.tr, icon: Icons.person_outline, onTap: () => _openFilter(vendorController)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          // TODO(BACKEND): no transmission filter parameter exists — queue item 14.
          StoreFilterChip(label: 'transmission'.tr, icon: Icons.call_split_rounded),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          StoreFilterChip(label: 'more'.tr, icon: Icons.more_horiz, onTap: () => _openFilter(vendorController)),
        ]),
      ),
    );
  }

  // ── Provider announcement (existing backend field, unchanged) ──
  Widget _announcement(BuildContext context, TaxiVendorModel vendor) {
    if (vendor.announcement != 1) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Colors.orange.withValues(alpha: 0.06),
        border: Border.all(color: Colors.orange, width: 0.1),
      ),
      child: Row(children: [
        Image.asset(Images.announcement, height: 20, width: 20, color: Colors.orange),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text(vendor.announcementMessage ?? '', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall), softWrap: true)),
      ]),
    );
  }

  // ── Provider discount (existing backend field + existing copy, unchanged) ──
  Widget _discount(BuildContext context, TaxiVendorModel vendor) {
    if (vendor.discount == null) return const SizedBox();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      child: Text(
        '${vendor.discount!.discountType == 'percent' ? '${vendor.discount!.discount}% '
            : '${PriceConverter.convertPrice(vendor.discount!.discount)} ${'off'.tr}'} '
            '${'discount_will_be_applicable_when_booking_amount_is_more_then'.tr} ${PriceConverter.convertPrice(vendor.discount!.minPurchase)},'
            ' ${'Max'.tr} ${PriceConverter.convertPrice(vendor.discount!.maxDiscount)} ${'discount_is_applicable'.tr}.',
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white),
      ),
    );
  }

  // ── Category strip — THE approved MoonJoin category component
  // (`RestaurantCategoryChip`), rendering the provider's REAL vehicle categories.
  // Selecting one calls the existing `setCategoryId` + `getVendorVehicleList` backend
  // filter; "All" clears it. Same data and same controller calls the previous
  // `SearchAndFilterWidget` category row used — presentation only. ──
  Widget _categories(BuildContext context, TaxiVendorController vendorController) {
    final categories = vendorController.categories;
    if (categories == null || categories.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
      child: SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          // The controller ALREADY prepends the leading "All" entry (id -1) — the
          // repository treats id -1 as "no category filter". Render that list as-is;
          // do NOT add a second synthetic "All" chip.
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            final category = categories[index];
            final bool isAll = category.id == -1;
            return RestaurantCategoryChip(
              label: category.name ?? '',
              imageUrl: category.imageFullUrl,
              index: index,
              // "All" has no artwork → a clean grid glyph. Real categories are
              // transparent icon PNGs, so reduce the inset like Screens 1 & 2.
              fallbackIcon: isAll ? Icons.apps : Icons.category,
              imagePadding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              selected: _selectedCategoryId == category.id,
              onTap: () => _selectCategory(vendorController, category.id),
            );
          },
        ),
      ),
    );
  }

  void _selectCategory(TaxiVendorController vendorController, int? id) {
    setState(() => _selectedCategoryId = id);
    // id -1 == "All"; the controller/repository map it to an unfiltered request.
    vendorController.setCategoryId(id);
    vendorController.getVendorVehicleList(offset: 1, vendorId: widget.vendorId!, searchName: searchName);
  }

  // ── Active search chip (existing clear-search behaviour, unchanged) ──
  Widget _activeSearchChip(BuildContext context, TaxiVendorController vendorController) {
    if (searchName.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(
          '${vendorController.taxiVendorVehicleList?.totalSize ?? 0} ${'result_found_for'.tr} $searchName',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color),
        )),
        InkWell(
          onTap: () async {
            setState(() => searchName = '');
            await vendorController.getVendorVehicleList(offset: 1, vendorId: widget.vendorId!, searchName: '', canUpdate: false);
          },
          child: Icon(Icons.close, size: Dimensions.fontSizeExtraLarge, color: Colors.grey),
        ),
      ]),
    );
  }

  // ── "N vehicles found" + active sort label (approved Store-page result header) ──
  Widget _resultHeader(BuildContext context, int totalSize) {
    final String sortLabel = _activeSort == 0 ? 'top_rated'.tr : _activeSort == 1 ? 'price'.tr : 'most_relevant'.tr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text('$totalSize ${'vehicles_found'.tr}', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
        Text(sortLabel, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
      ]),
    );
  }

  // ── Vehicle list — existing rental `VendorVehicleCard` + approved
  // `PaginatedListView` + approved `NoDataScreen`. Business logic untouched. ──
  Widget _vehicleList(BuildContext context, TaxiVendorController vendorController) {
    if (vendorController.taxiVendorVehicleList == null) {
      return const Padding(
        padding: EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        child: SkeletonListLoader(itemCount: 4),
      );
    }

    final List<VehicleModel> vehicles = vendorController.taxiVendorVehicleList!.vehicles ?? [];
    if (vehicles.isEmpty) {
      return NoDataScreen(text: 'no_vehicle_available'.tr);
    }

    final List<VehicleModel> sorted = _applySort(vehicles);

    return PaginatedListView(
      scrollController: _scrollController,
      onPaginate: (int? offset) async => vendorController.getVendorVehicleList(offset: offset!, vendorId: widget.vendorId!),
      totalSize: vendorController.taxiVendorVehicleList?.totalSize,
      offset: vendorController.taxiVendorVehicleList?.offset,
      itemView: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: sorted.length,
        padding: const EdgeInsets.only(bottom: 50),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => VendorVehicleCard(vehicle: sorted[index]),
      ),
    );
  }
}

/// Provider page loading state — shared `MoonjoinSkeleton`/`SkeletonBox`, mirroring
/// the page's own layout (hero → chips → list). Replaces the previous bare
/// `CircularProgressIndicator` (COMPONENTS.md recorded this as an outstanding delta
/// against the approved Store page).
class _ProviderDetailShimmer extends StatelessWidget {
  const _ProviderDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return MoonjoinSkeleton(child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        SkeletonBox(height: 250 + MediaQuery.of(context).padding.top, radius: Dimensions.radiusExtraLarge),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        SizedBox(height: 36, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (_, _) => const SkeletonBox(width: 92, radius: Dimensions.radiusExtraLarge),
        )),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        SizedBox(height: 88, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (_, _) => const SkeletonBox(width: 64, height: 64, circle: true),
        )),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        ...List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
          child: SkeletonBox(height: 220, radius: Dimensions.radiusDefault),
        )),
      ]),
    ));
  }
}
