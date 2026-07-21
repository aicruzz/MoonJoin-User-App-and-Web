import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/moonjoin/loading_skeleton.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/widgets/all_restaurants_widgets.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_search_bar.dart';
import 'package:sixam_mart/common/widgets/moonjoin/wavy_header.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/screens/vehicle_favourite_screen.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/rental_module/apartment_placeholder/apartment_placeholder.dart';
import 'package:sixam_mart/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:sixam_mart/features/rental_module/home/screens/all_vehicle_screen.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/banner_widget.dart';
import 'package:sixam_mart/features/rental_module/home/widgets/rental_popular_card.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/controllers/taxi_favourite_controller.dart';
import 'package:sixam_mart/features/rental_module/select_vehicle_screen/search_vehicle_screen.dart';
import 'package:sixam_mart/features/rental_module/rental_order/controllers/taxi_order_controller.dart';
import 'package:sixam_mart/features/rental_module/vehicle_details_screen/vehicle_details_screen.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class TaxiHomeScreen extends StatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  State<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends State<TaxiHomeScreen> {

  @override
  void initState() {
    super.initState();
    Get.find<TaxiHomeController>().getTaxiBannerList(false);
    Get.find<TaxiHomeController>().getTopRatedCarList(1, false);
    // Real backend categories (admin: Car & Apt Rental → Vehicle Management → Categories).
    Get.find<TaxiHomeController>().getVehicleCategoryList();
    if (AuthHelper.isLoggedIn()) {
      Get.find<AddressController>().getAddressList();
      Get.find<TaxiOrderController>().getTripList(1, isRunning: false, fromHome: true);
      Get.find<TaxiHomeController>().getTaxiCouponList(false);
      Get.find<TaxiFavouriteController>().getFavouriteTaxiList();
    }
  }

  // TODO(BACKEND): Short Apartment Rental has no backend — see docs/BACKEND_INTEGRATION_QUEUE.md.
  void _comingSoon() => showCustomSnackBar('short_apartment_rental_coming_soon'.tr, isError: false);

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _header(context, green),

          const SizedBox(height: Dimensions.paddingSizeDefault),
          _heroCards(context, green),

          const SizedBox(height: Dimensions.paddingSizeLarge),
          _categoryChips(context, green),

          const SizedBox(height: Dimensions.paddingSizeLarge),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Text('exclusive_deals'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          const BannerWidget(),

          const SizedBox(height: Dimensions.paddingSizeLarge),
          _popularCars(context),

          const SizedBox(height: Dimensions.paddingSizeLarge),
          _popularApartments(context),

          const SizedBox(height: 90),
        ]),
      ),
    );
  }

  // ── 1. Green wavy header + 2. Search ──
  Widget _header(BuildContext context, Color green) {
    final double topInset = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: topInset + 172,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(top: 0, left: 0, right: 0, child: WavyHeader(height: topInset + 150, color: green)),

        Positioned(
          top: topInset + Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back to the all-modules dashboard. Reuses the SAME approved action as the
            // standard MoonJoin home app bar (which is hidden on Rental because this
            // screen draws its own header) — no new navigation logic.
            _circleIcon(context, Icons.arrow_back, () {
              Get.find<SplashController>().removeModule();
              Get.find<StoreController>().resetStoreData();
            }),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Container(
              height: 44, width: 44, alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.directions_car_filled, color: green, size: 24),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('car_rental_and_short_apt_rental'.tr, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge, height: 1.1)),
              const SizedBox(height: 2),
              Text('drive_more_stay_better'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
            ])),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            GetBuilder<NotificationController>(builder: (nc) => _circleIcon(context, CupertinoIcons.bell, () => Get.toNamed(RouteHelper.getNotificationRoute()), showDot: nc.hasNotification)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _circleIcon(context, Icons.favorite_border, () => Get.to(() => const VehicleFavouriteScreen())),
          ]),
        ),

        // Search — the shared approved MoonJoin search bar (tap-to-search), straddling
        // the wave. Reused as-is; no Rental-specific search styling.
        Positioned(
          left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: 0,
          // Search performs SEARCH (approved MoonJoin/Food behaviour) via the existing
          // rental search screen. It must NOT open the Location screen — the location /
          // trip-context flow stays fully intact and is used later in the booking
          // journey (TaxiLocationSuggestionScreen is still used by that flow).
          child: MoonjoinSearchBar(
            hintText: 'search_cars_locations_or_apartments'.tr,
            readOnly: true,
            onTap: () => Get.to(() => const SearchVehicleScreen()),
            onFilterTap: () => Get.to(() => const SearchVehicleScreen()),
          ),
        ),
      ]),
    );
  }

  Widget _circleIcon(BuildContext context, IconData icon, VoidCallback onTap, {bool showDot = false}) {
    return InkWell(
      onTap: onTap, customBorder: const CircleBorder(),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 44, width: 44, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        ),
        if (showDot) Positioned(top: 0, right: 0, child: Container(
          height: 10, width: 10,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle, border: Border.all(width: 1.5, color: Colors.white)),
        )),
      ]),
    );
  }

  // ── 3 + 4. Car Rental & Apartment Rental hero cards ──
  Widget _heroCards(BuildContext context, Color green) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      // IntrinsicHeight gives the Row a bounded cross-axis height inside the vertical
      // scroll view so CrossAxisAlignment.stretch (equal-height hero cards) can lay
      // out — without it the Row can't be laid out and the whole screen renders blank.
      child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _heroCard(
          context, green,
          title: 'car_rental'.tr, desc: 'best_cars_best_prices_anytime_anywhere'.tr,
          buttonText: 'explore_cars'.tr, image: kPlaceholderCarHeroImage,
          onExplore: () => Get.to(() => const AllVehicleScreen()),
        )),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: _heroCard(
          context, green,
          title: 'short_apt_rental'.tr, desc: 'comfortable_stays_for_any_duration'.tr,
          buttonText: 'explore_apts'.tr, image: kPlaceholderAptHeroImage,
          onExplore: _comingSoon, // TODO(BACKEND): apartment listing screen (no backend yet)
        )),
      ])),
    );
  }

  Widget _heroCard(BuildContext context, Color green, {required String title, required String desc,
      required String buttonText, required String image, required VoidCallback onExplore}) {
    // The WHOLE card is tappable (single tappable card); the CTA button remains and
    // performs the same action.
    return InkWell(
      onTap: onExplore,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      child: Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: green.withValues(alpha: 0.10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Dominant admin-uploaded image (dynamic; backend-ready). Fills 100% of the
        // card's image area — placeholder asset now, swaps to the admin hero image URL
        // with no layout change. BoxFit.cover preserves aspect ratio (no stretching).
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: CustomImage(image: image, height: 150, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text(title, style: robotoBold.copyWith(color: green, fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        Align(alignment: Alignment.centerLeft, child: InkWell(
          onTap: onExplore,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(buttonText, style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
            ]),
          ),
        )),
      ]),
      ),
    );
  }

  // ── 5. Categories — REAL backend data, MoonJoin category design language ──
  // Source: existing `/api/v1/rental/vehicle/category-list` via
  // TaxiHomeController.getVehicleCategoryList() (admin: Car & Apt Rental → Vehicle
  // Management → Categories). Nothing is hardcoded — names, images and the number of
  // categories all come from the backend, exactly like every other MoonJoin module.
  //
  // Uses THE approved MoonJoin category component (`RestaurantCategoryChip`) — the same
  // one used by Food / All Restaurants and every approved module. Rental shares it; only
  // the backend data differs, plus additive overrides for icon-style artwork. Selection
  // reuses the existing controller state (`selectedCategoryIds` / `addOrRemoveCategory`).
  Widget _categoryChips(BuildContext context, Color green) {
    return GetBuilder<TaxiHomeController>(builder: (taxiController) {
      final categories = taxiController.vehicleCategoryModel?.vehicles;
      if (categories == null) return const _RentalCategoryShimmer();
      if (categories.isEmpty) return const SizedBox();

      final bool allSelected = taxiController.selectedCategoryIds.isEmpty;
      return SizedBox(
        // Same geometry as the approved Food category section.
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
          itemCount: categories.length + 1, // +1 for the leading "All"
          separatorBuilder: (_, i) => const SizedBox(width: Dimensions.paddingSizeDefault),
          itemBuilder: (context, i) {
            // Leading "All" — default active when nothing is selected (Food Home behaviour).
            if (i == 0) {
              return RestaurantCategoryChip(
                label: 'all'.tr, index: 0, fallbackIcon: Icons.grid_view_rounded, selected: allSelected,
                onTap: () => taxiController.clearSelectedCategories(),
              );
            }
            final category = categories[i - 1];
            final bool selected = taxiController.selectedCategoryIds.contains(category.id);
            return RestaurantCategoryChip(
              label: category.name ?? '', imageUrl: category.imageFullUrl, index: i, selected: selected,
              imagePadding: const EdgeInsets.all(4),
              onTap: () => taxiController.addOrRemoveCategory(category.id!),
            );
          },
        ),
      );
    });
  }

  // ── 7. Popular Car Rentals (real backend via TaxiHomeController) ──
  Widget _popularCars(BuildContext context) {
    return GetBuilder<TaxiHomeController>(builder: (taxiController) {
      final vehicles = taxiController.topRatedCarsModel?.vehicles?.where((v) => v.status == 1).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(context, 'popular_car_rentals'.tr, () => Get.to(() => const AllVehicleScreen())),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        (vehicles == null)
            ? const _RentalCardShimmer()
            : vehicles.isEmpty ? const SizedBox()
            : SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: vehicles.length,
            separatorBuilder: (_, i) => const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (context, i) {
              final v = vehicles[i];
              return RentalPopularCard(
                image: v.thumbnailFullUrl ?? '',
                title: v.name ?? '',
                subtitle: '${v.transmissionType ?? ''}${(v.transmissionType != null && v.fuelType != null) ? ' • ' : ''}${v.fuelType ?? ''}',
                price: PriceConverter.convertPrice(v.dayWisePrice ?? 0),
                unit: ' /${'day'.tr}',
                rating: v.avgRating ?? 0,
                showBookNow: true,
                onTap: () => Get.to(() => VehicleDetailsScreen(vehicleId: v.id)),
                onBook: () => Get.to(() => VehicleDetailsScreen(vehicleId: v.id)),
              );
            },
          ),
        ),
      ]);
    });
  }

  // ── 8. Popular Short Apt Rentals (UI-layer placeholder — TODO(BACKEND)) ──
  Widget _popularApartments(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(context, 'popular_short_apt_rentals'.tr, _comingSoon),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: kPlaceholderPopularApartments.length,
          separatorBuilder: (_, i) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, i) {
            final a = kPlaceholderPopularApartments[i];
            return RentalPopularCard(
              image: a.image,
              title: a.name,
              subtitle: a.location,
              price: PriceConverter.convertPrice(a.pricePerNight),
              unit: ' /${'night'.tr}',
              rating: a.rating,
              onTap: _comingSoon, // TODO(BACKEND): apartment details screen
            );
          },
        ),
      ),
    ]);
  }

  Widget _sectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        InkWell(onTap: onSeeAll, child: Text('see_all'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall))),
      ]),
    );
  }
}

/// Loading state for the Rental category row — mirrors the approved Food category
/// shimmer (same tile geometry and spacing), driven by Rental data instead.
class _RentalCategoryShimmer extends StatelessWidget {
  const _RentalCategoryShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        itemCount: 6,
        separatorBuilder: (_, i) => const SizedBox(width: Dimensions.paddingSizeDefault),
        // Reuses the shared MoonJoin skeleton primitives — no bespoke shimmer styling.
        itemBuilder: (context, i) => const MoonjoinSkeleton(
          child: SizedBox(width: 60, child: Column(children: [
            SkeletonBox(height: 60, width: 60, circle: true),
            SizedBox(height: Dimensions.paddingSizeSmall),
            SkeletonBox(height: 10, width: 50, radius: Dimensions.radiusSmall),
          ])),
        ),
      ),
    );
  }
}

/// Loading state for the Rental "Popular …" card rows — matches `RentalPopularCard`
/// geometry and reuses the shared MoonJoin skeleton primitives.
class _RentalCardShimmer extends StatelessWidget {
  const _RentalCardShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        itemCount: 4,
        separatorBuilder: (_, i) => const SizedBox(width: Dimensions.paddingSizeSmall),
        itemBuilder: (context, i) => const MoonjoinSkeleton(
          child: SizedBox(width: 168, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBox(height: 96, width: 168, radius: Dimensions.radiusDefault),
            SizedBox(height: Dimensions.paddingSizeSmall),
            SkeletonBox(height: 12, width: 120, radius: Dimensions.radiusSmall),
            SizedBox(height: Dimensions.paddingSizeExtraSmall),
            SkeletonBox(height: 10, width: 90, radius: Dimensions.radiusSmall),
            SizedBox(height: Dimensions.paddingSizeExtraSmall),
            SkeletonBox(height: 12, width: 70, radius: Dimensions.radiusSmall),
          ])),
        ),
      ),
    );
  }
}
