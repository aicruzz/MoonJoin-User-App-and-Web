import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_advertisement_section.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_campaign_section.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_food_top_brands.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_top_brands_section.dart';
import 'package:sixam_mart/features/flash_sale/widgets/flash_sale_view_widget.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/module_terminology_helper.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/features/store/widgets/all_restaurants_widgets.dart';
import 'package:sixam_mart/features/store/widgets/moonjoin_store_card.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// ALL RESTAURANTS — redesigned from the Active Figma frame `1:1703`
/// (verified against `ui-designs/.../restaurant_list.PNG`). Presentation only:
/// it reuses the existing [StoreController]/[CategoryController]/[BrandsController]
/// data, favourites, navigation and business logic unchanged.
class AllStoreScreen extends StatefulWidget {
  final bool isPopular;
  final bool isFeatured;
  final bool isNearbyStore;
  final bool isTopOfferStore;
  final bool isRecommendedStore;
  /// When true this screen is the module landing (shown inside the dashboard Home
  /// tab for storefront modules), not a pushed page: the app bar shows a
  /// module-grid toggle + notification + cart instead of a back button.
  final bool fromModule;
  const AllStoreScreen({super.key, required this.isPopular, required this.isFeatured, required this.isNearbyStore, required this.isTopOfferStore, required this.isRecommendedStore, this.fromModule = false});

  @override
  State<AllStoreScreen> createState() => _AllStoreScreenState();
}

class _AllStoreScreenState extends State<AllStoreScreen> {
  final ScrollController scrollController = ScrollController();
  int _activeFilter = -1; // -1 none, 0 fast delivery, 1 free delivery, 2 top rated
  // Discovery filter (module features exposed on demand, not as homepage blocks):
  // -1 none, 0 Special Offer (discounted items), 1 Most Popular Items, 2 Nearby stores.
  int _discovery = -1;

  @override
  void initState() {
    super.initState();
    _loadStores();
    Get.find<CategoryController>().getCategoryList(false);
    if (Get.find<BrandsController>().brandList == null) {
      Get.find<BrandsController>().getBrandList();
    }
    // Promotional banner = the existing Admin Banner feed (banner images that
    // link to the promoted / paid-advertising stores configured in the Admin
    // Panel). Reused as-is; store-target banners are filtered at render time.
    Get.find<BannerController>().getBannerList(false);
    // Flash Deals = the existing per-store, admin-approved Flash Sale feed.
    // Reuse the existing controller/data; the section self-hides when the module
    // has no active flash products. No new API/model/business logic.
    Get.find<FlashSaleController>().getFlashSale(false, false);
  }

  void _loadStores() {
    final sc = Get.find<StoreController>();
    if (widget.isFeatured) {
      sc.getFeaturedStoreList();
    } else if (widget.isPopular) {
      sc.getPopularStoreList(false, 'all', false);
    } else if (widget.isTopOfferStore) {
      sc.getTopOfferStoreList(false, false);
    } else if (widget.isRecommendedStore) {
      sc.getRecommendedStoreList();
    } else {
      sc.getLatestStoreList(false, 'all', false);
    }
  }

  List<Store>? _sourceList(StoreController sc) {
    if (widget.isFeatured) return sc.featuredStoreList;
    if (widget.isPopular) return sc.popularStoreList;
    if (widget.isTopOfferStore) return sc.topOfferStoreList;
    if (widget.isRecommendedStore) return sc.recommendedStoreList;
    return sc.latestStoreList;
  }

  /// Client-side filter/sort for the chips (operates on the already-loaded list —
  /// no new API calls, no fake data).
  List<Store> _applyFilter(List<Store> list) {
    final result = List<Store>.from(list);
    if (_activeFilter == 1) {
      result.retainWhere((s) => s.freeDelivery == true);
    } else if (_activeFilter == 2) {
      result.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
    } else if (_activeFilter == 0) {
      int mins(Store s) => int.tryParse((s.deliveryTime ?? '').split('-').first.trim()) ?? 9999;
      result.sort((a, b) => mins(a).compareTo(mins(b)));
    }
    // Open stores first, closed after (stable — keeps the sort above within each
    // group). Reuses the existing open/close calc.
    return Get.find<StoreController>().sortStoresOpenFirst(result);
  }

  String _title() {
    final showRestaurant = Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText ?? false;
    if (widget.isFeatured) return 'featured_stores'.tr;
    if (widget.isPopular) return widget.isNearbyStore ? 'best_store_nearby'.tr : showRestaurant ? 'popular_restaurants'.tr : 'popular_stores'.tr;
    if (widget.isTopOfferStore) return 'top_offers_near_me'.tr;
    if (widget.isRecommendedStore) return 'recommended_store'.tr;
    // Module-aware header (reuse the shared terminology helper): premium bare label —
    // "Restaurants", "Grocery Stores", "Pharmacies", "Fashion Stores", "Markets",
    // "Fuel Stations", "Drink Distributors" (no "All" prefix; was a binary
    // restaurant/"New On MoonJoin" fallback that mislabelled non-food modules).
    return ModuleTerminology.providerLabelPlural(Get.find<SplashController>().module);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: GetBuilder<StoreController>(builder: (storeController) {
          final source = _sourceList(storeController);
          final List<Store>? stores = source == null ? null : _applyFilter(source);
          return Column(children: [
            _appBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadStores();
                  Get.find<BannerController>().getBannerList(true);
                  await Get.find<CategoryController>().getCategoryList(true);
                },
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: GetBuilder<BannerController>(builder: (bannerController) {
                    // Keep only store-target banners (the promoted / paid stores)
                    // from the Admin Banner feed, paired with their images.
                    final List<String?> bannerImages = [];
                    final List<Store> bannerStores = [];
                    final imgs = bannerController.bannerImageList;
                    final data = bannerController.bannerDataList;
                    if (imgs != null && data != null) {
                      for (int i = 0; i < imgs.length && i < data.length; i++) {
                        if (data[i] is Store) {
                          bannerImages.add(imgs[i]);
                          bannerStores.add(data[i] as Store);
                        }
                      }
                    }
                    // Show the rotating banner only when no filter/sort/discovery is
                    // active (the design puts it at the very top of the default list).
                    final bool hasBanner = _activeFilter == -1 && _discovery == -1 && bannerImages.isNotEmpty;

                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _searchBar(context),
                      _categoryChips(),
                      _filterChips(),

                      if (hasBanner) ...[
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        PromotionalBannerCarousel(images: bannerImages, stores: bannerStores, onTapStore: _openStoreBanner),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                      ],

                      // A discovery chip (Special Offer / Most Popular / Nearby) reveals
                      // its results on demand; otherwise the clean approved store list.
                      if (_discovery != -1)
                        _discoveryContent(context, storeController)
                      else
                        _storeList(context, stores),

                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ]);
                  }),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    final splashController = Get.find<SplashController>();
    // Module landing: show a module-grid toggle (return to the module grid) + a
    // notification and cart shortcut. Pushed page: show a back button.
    final bool showGridToggle = widget.fromModule
        && splashController.configModel?.module == null
        && (splashController.moduleList?.length ?? 0) != 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      child: Row(children: [
        widget.fromModule
            ? (showGridToggle
                ? _circleButton(context, Icons.grid_view_rounded, () {
                    splashController.removeModule();
                    Get.find<StoreController>().resetStoreData();
                  })
                : const SizedBox())
            : _circleButton(context, Icons.arrow_back, () => Get.back()),
        SizedBox(width: (widget.fromModule && !showGridToggle) ? 0 : Dimensions.paddingSizeDefault),
        Expanded(child: Text(_title(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (widget.fromModule) ...[
          _circleButton(context, Icons.notifications_none, () => Get.toNamed(RouteHelper.getNotificationRoute())),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          InkWell(
            onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 44, width: 44,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Center(child: CartWidget(color: Theme.of(context).primaryColor, size: 22)),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
        ],
        _circleButton(context, Icons.search, () => Get.toNamed(RouteHelper.getSearchRoute())),
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

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
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
            Expanded(child: Text('search_for_food_restaurants_or_cuisines'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(width: 1, height: 24, color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 22),
          ]),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return GetBuilder<CategoryController>(builder: (categoryController) {
      final categories = categoryController.categoryList;
      if (categories == null || categories.isEmpty) return const SizedBox();
      return SizedBox(
        height: 108,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeDefault),
          itemBuilder: (context, index) {
            final c = categories[index];
            return RestaurantCategoryChip(
              label: c.name ?? '', imageUrl: c.imageFullUrl, index: index,
              // Category filtering from the Store List shows stores/restaurants only (no Item tab/cards).
              onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(c.id, c.name ?? '', storesOnly: true)),
            );
          },
        ),
      );
    });
  }

  Widget _filterChips() {
    void toggle(int i) => setState(() => _activeFilter = _activeFilter == i ? -1 : i);
    // Discovery chips expose module features on demand (they don't appear as
    // homepage blocks). Toggling one clears the plain sort/filter and vice-versa.
    void toggleDiscovery(int i) => setState(() {
      _discovery = _discovery == i ? -1 : i;
      if (_discovery != -1) _activeFilter = -1;
    });
    final Color primary = Theme.of(context).primaryColor;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        StoreFilterChip(label: 'filters'.tr, icon: Icons.tune, iconColor: primary, labelColor: primary, onTap: () {}),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'sort'.tr, trailingDropdown: true, selected: _activeFilter == 2, onTap: () => toggle(2)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'fast_delivery'.tr, icon: Icons.bolt, iconColor: Colors.amber.shade700, selected: _activeFilter == 0, onTap: () => toggle(0)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'free_delivery'.tr, icon: Icons.favorite, iconColor: primary, selected: _activeFilter == 1, onTap: () => toggle(1)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'top_rated'.tr, icon: Icons.star, iconColor: Colors.amber.shade700, selected: _activeFilter == 2, onTap: () => toggle(2)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        // Discovery filters (module features on demand)
        StoreFilterChip(label: 'special_offer'.tr, icon: Icons.local_offer_outlined, iconColor: primary, selected: _discovery == 0, onTap: () => toggleDiscovery(0)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'most_popular_items'.tr, icon: Icons.local_fire_department_outlined, iconColor: Colors.amber.shade700, selected: _discovery == 1, onTap: () => toggleDiscovery(1)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: _nearbyTerm(), icon: Icons.near_me_outlined, iconColor: primary, selected: _discovery == 2, onTap: () => toggleDiscovery(2)),
      ]),
    );
  }

  /// Module-aware "Nearby …" label (Food→Restaurants, Grocery→Stores,
  /// Pharmacy→Pharmacies, Ecommerce→Shops). Uses the active module type.
  String _nearbyTerm() {
    final mt = Get.find<SplashController>().module?.moduleType?.toString() ?? '';
    if (mt == AppConstants.food) return 'nearby_restaurants'.tr;
    if (mt == AppConstants.pharmacy) return 'nearby_pharmacies'.tr;
    if (mt == AppConstants.ecommerce) return 'nearby_shops'.tr;
    return 'nearby_stores'.tr;
  }

  /// Discovery results, on demand. Special Offer / Most Popular reuse the existing
  /// discounted/popular ITEM lists (no invented ranking); Nearby reuses the loaded
  /// store list sorted by real distance (existing location logic). No new backend.
  Widget _discoveryContent(BuildContext context, StoreController storeController) {
    if (_discovery == 0) {
      return _itemDiscoveryList(context, Get.find<ItemController>().discountedItemList);
    } else if (_discovery == 1) {
      return _itemDiscoveryList(context, Get.find<ItemController>().popularItemList);
    } else {
      final source = _sourceList(storeController);
      if (source == null) {
        return const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()));
      }
      final List<Store> sorted = _sortByDistance(List<Store>.from(source));
      if (sorted.isEmpty) {
        return Padding(padding: const EdgeInsets.only(top: 40), child: NoDataScreen(text: 'no_store_available'.tr, showFooter: false));
      }
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        itemCount: sorted.length,
        separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) => MoonjoinStoreCard(store: sorted[index], onTap: () => _openStore(sorted[index])),
      );
    }
  }

  Widget _itemDiscoveryList(BuildContext context, List<Item>? items) {
    if (items == null) {
      return const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()));
    }
    if (items.isEmpty) {
      return Padding(padding: const EdgeInsets.only(top: 40), child: NoDataScreen(text: 'no_item_available'.tr, showFooter: false));
    }
    // Reuse the frozen premium ItemWidget layout via ItemsView (real item data).
    return ItemsView(
      isStore: false, stores: null, items: items,
      premiumStoreLayout: true,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
    );
  }

  /// Sort stores by real distance from the user's saved location (existing logic).
  List<Store> _sortByDistance(List<Store> list) {
    final addr = AddressHelper.getUserAddressFromSharedPref();
    final double? ulat = double.tryParse(addr?.latitude ?? '');
    final double? ulng = double.tryParse(addr?.longitude ?? '');
    if (ulat == null || ulng == null) return list;
    double dist(Store s) {
      final la = double.tryParse(s.latitude ?? '');
      final ln = double.tryParse(s.longitude ?? '');
      if (la == null || ln == null) return double.infinity;
      return Geolocator.distanceBetween(ulat, ulng, la, ln);
    }
    list.sort((a, b) => dist(a).compareTo(dist(b)));
    return list;
  }

  Widget _topBrands() {
    // Brands are backend-supported ONLY for the Ecommerce/Fashion module today.
    // Every other module must hide the Brands section — the backend currently returns
    // the SAME brand for all modules, so without this gate Grocery/Pharmacy/Market/Fuel/
    // Drink Distributor would show Fashion's brand. Reuse-only: no engine change.
    if (Get.find<SplashController>().module?.moduleType != AppConstants.ecommerce) {
      return const SizedBox();
    }
    // Presentation: the approved shared MoonJoin Top Brands (same as Food). Data,
    // navigation and the "See all" target stay the existing Ecommerce/Fashion ones
    // (BrandsController product brands → getBrandsItemScreen / getBrandsScreen).
    return GetBuilder<BrandsController>(builder: (brandsController) {
      final brands = brandsController.brandList;
      final items = brands
          ?.map((b) => MoonjoinTopBrandItem(
                name: b.name ?? '',
                imageUrl: b.imageFullUrl,
                onTap: () => Get.toNamed(RouteHelper.getBrandsItemScreen(b.id ?? 0, b.name ?? '')),
              ))
          .toList();
      return MoonjoinTopBrandsSection(
        title: 'top_brands'.tr,
        items: items,
        onSeeAll: () => Get.toNamed(RouteHelper.getBrandsScreen()),
      );
    });
  }

  Widget _storeList(BuildContext context, List<Store>? stores) {
    if (stores == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (stores.isEmpty) {
      return Column(children: [_topBrands(), const SizedBox(height: 40), NoDataScreen(text: 'no_store_available'.tr, showFooter: false)]);
    }
    // Top Brands sits at the top of the listing, then the full store list.
    // When the admin promo rotation banner exists it renders above (in build);
    // when it does NOT, Top Brands is the top element — the first store is NOT
    // promoted to a hero card (no fallback hero).
    return Column(children: [
      // Food Top Brands — featured Food restaurants/stores (module-gated, self-hides).
      // Sits at the established Top Brands position; _topBrands() below stays the
      // Ecommerce/Fashion product-brands section (only one renders per module).
      if (_activeFilter == -1 && _discovery == -1) const MoonjoinFoodTopBrands(),
      _topBrands(),
      // Flash Deals — reuse the approved FlashSaleViewWidget (which renders the
      // approved FlashProductCard). Gated to the clean home state exactly like the
      // promotional banner; it also self-hides when there are no active flash
      // products. Order: Promo Banner → [Brand] → Flash → Provider store banners.
      if (_activeFilter == -1 && _discovery == -1) const FlashSaleViewWidget(),
      // Advertisement ("Highlights") — reuse the new MoonjoinAdvertisementSection
      // (which renders the existing AdvertisementController data via the reusable
      // MoonjoinAdvertisementCard). Placed BELOW Flash Deals; when Flash Deals is
      // absent it self-hides, so Advertisement sits directly below Top Brands.
      // Gated to the clean home state exactly like Flash Deals; self-hides when
      // there are no advertisements. Data is loaded by the home lifecycle (no
      // duplicate request). Order: Top Brands → Flash → Advertisement → stores.
      if (_activeFilter == -1 && _discovery == -1) const MoonjoinAdvertisementSection(),
      // Campaigns (item-campaign) — the existing CampaignController.itemCampaignList
      // rendered via the shared MoonjoinCampaignSection. Placed after Advertisement,
      // before the store list; gated to the clean home state; self-hides when there
      // are no active campaign items. Data is loaded by the home lifecycle (no
      // duplicate request). Order: Top Brands → Flash → Advertisement → Campaigns → stores.
      if (_activeFilter == -1 && _discovery == -1) const MoonjoinCampaignSection(),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        itemCount: stores.length,
        separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) {
          final store = stores[index];
          return MoonjoinStoreCard(store: store, onTap: () => _openStore(store));
        },
      ),
    ]);
  }

  void _openStore(Store store) {
    // Ensure the store's module is active, then open its page (existing behaviour).
    for (ModuleModel module in Get.find<SplashController>().moduleList ?? []) {
      if (module.id == store.moduleId) {
        Get.find<SplashController>().setModule(module);
        break;
      }
    }
    Get.toNamed(RouteHelper.getStoreRoute(id: store.id, page: 'store'));
  }

  /// Promotional-banner tap → open the promoted store. Mirrors the existing
  /// banner→store navigation in `home/widgets/views/banner_view.dart` exactly
  /// (module activation, `page: 'banner'`, and the [StoreScreen] argument) so
  /// the established banner deep-link behaviour is preserved.
  void _openStoreBanner(Store store) {
    for (ModuleModel module in Get.find<SplashController>().moduleList ?? []) {
      if (module.id == store.moduleId) {
        Get.find<SplashController>().setModule(module);
        break;
      }
    }
    Get.toNamed(
      RouteHelper.getStoreRoute(id: store.id, page: 'banner'),
      arguments: StoreScreen(store: store, fromModule: false),
    );
  }
}
