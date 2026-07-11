import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/features/brands/controllers/brands_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
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
  const AllStoreScreen({super.key, required this.isPopular, required this.isFeatured, required this.isNearbyStore, required this.isTopOfferStore, required this.isRecommendedStore});

  @override
  State<AllStoreScreen> createState() => _AllStoreScreenState();
}

class _AllStoreScreenState extends State<AllStoreScreen> {
  final ScrollController scrollController = ScrollController();
  int _activeFilter = -1; // -1 none, 0 fast delivery, 1 free delivery, 2 top rated

  @override
  void initState() {
    super.initState();
    _loadStores();
    Get.find<CategoryController>().getCategoryList(false);
    if (Get.find<BrandsController>().brandList == null) {
      Get.find<BrandsController>().getBrandList();
    }
    // Featured-store promo carousel reuses the existing featured backend.
    // On the featured entry the main list already IS the featured list, so we
    // skip the duplicate carousel there.
    if (!widget.isFeatured) {
      Get.find<StoreController>().getFeaturedStoreList();
    }
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
    return result;
  }

  String _title() {
    final showRestaurant = Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText ?? false;
    if (widget.isFeatured) return 'featured_stores'.tr;
    if (widget.isPopular) return widget.isNearbyStore ? 'best_store_nearby'.tr : showRestaurant ? 'popular_restaurants'.tr : 'popular_stores'.tr;
    if (widget.isTopOfferStore) return 'top_offers_near_me'.tr;
    if (widget.isRecommendedStore) return 'recommended_store'.tr;
    return showRestaurant ? 'all_restaurants'.tr : '${'new_on'.tr} ${AppConstants.appName}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: GetBuilder<StoreController>(builder: (storeController) {
          final source = _sourceList(storeController);
          final List<Store>? stores = source == null ? null : _applyFilter(source);
          // Featured promo carousel (existing backend). Empty/absent → falls back
          // to the hero-card layout so the approved UI still holds.
          final List<Store> featured = (!widget.isFeatured && _activeFilter == -1)
              ? (storeController.featuredStoreList ?? const [])
              : const [];
          return Column(children: [
            _appBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadStores();
                  await Get.find<CategoryController>().getCategoryList(true);
                },
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    _searchBar(context),
                    _categoryChips(),
                    _filterChips(),

                    if (featured.isNotEmpty) ...[
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      FeaturedStoreCarousel(stores: featured, onTapStore: _openStore),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                    ],

                    _storeList(context, stores, hasFeatured: featured.isNotEmpty),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                  ]),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      child: Row(children: [
        _circleButton(context, Icons.arrow_back, () => Get.back()),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(child: Text(_title(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
              onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(c.id, c.name ?? '')),
            );
          },
        ),
      );
    });
  }

  Widget _filterChips() {
    void toggle(int i) => setState(() => _activeFilter = _activeFilter == i ? -1 : i);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        StoreFilterChip(label: 'filters'.tr, icon: Icons.tune, iconColor: Theme.of(context).primaryColor, labelColor: Theme.of(context).primaryColor, onTap: () {}),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'sort'.tr, trailingDropdown: true, selected: _activeFilter == 2, onTap: () => toggle(2)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'fast_delivery'.tr, icon: Icons.bolt, iconColor: Colors.amber.shade700, selected: _activeFilter == 0, onTap: () => toggle(0)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'free_delivery'.tr, icon: Icons.favorite, iconColor: Theme.of(context).primaryColor, selected: _activeFilter == 1, onTap: () => toggle(1)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        StoreFilterChip(label: 'top_rated'.tr, icon: Icons.star, iconColor: Colors.amber.shade700, selected: _activeFilter == 2, onTap: () => toggle(2)),
      ]),
    );
  }

  Widget _topBrands() {
    return GetBuilder<BrandsController>(builder: (brandsController) {
      final brands = brandsController.brandList;
      if (brands == null || brands.isEmpty) return const SizedBox();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('top_brands'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            InkWell(
              onTap: () => Get.toNamed(RouteHelper.getBrandsScreen()),
              child: Row(children: [
                Text('see_all'.tr, style: robotoMedium.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall)),
                Icon(Icons.chevron_right, size: 18, color: Theme.of(context).hintColor),
              ]),
            ),
          ]),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemCount: brands.length,
            separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              final b = brands[index];
              return TopBrandCard(
                name: b.name ?? '', imageUrl: b.imageFullUrl, itemCount: b.itemsCount ?? 0,
                onTap: () => Get.toNamed(RouteHelper.getBrandsItemScreen(b.id ?? 0, b.name ?? '')),
              );
            },
          ),
        ),
      ]);
    });
  }

  Widget _storeList(BuildContext context, List<Store>? stores, {bool hasFeatured = false}) {
    if (stores == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (stores.isEmpty) {
      return Column(children: [_topBrands(), const SizedBox(height: 40), NoDataScreen(text: 'no_store_available'.tr, showFooter: false)]);
    }
    // With a featured carousel present the hero is already shown → Top Brands then
    // the full list. Without one (fallback), the first card acts as the hero.
    final int skip = hasFeatured ? 0 : 1;
    return Column(children: [
      if (!hasFeatured)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          child: MoonjoinStoreCard(store: stores.first, onTap: () => _openStore(stores.first)),
        ),
      _topBrands(),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        itemCount: stores.length - skip,
        separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
        itemBuilder: (context, index) {
          final store = stores[index + skip];
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
}
