import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_top_brands_section.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/app_constants.dart';

/// MoonJoin **Food** Top Brands adapter (ui-designs/Top_Brands.png): maps the existing
/// featured Food stores onto the shared [MoonjoinTopBrandsSection] presentation.
///
/// PRESENTATION ONLY. It owns only the Food DATA wiring — the existing featured-store
/// capability (`StoreController.featuredStoreList` → `GET .../stores/get-stores/all?featured=1`,
/// already module- + zone-scoped) — and delegates ALL visuals to the shared section.
/// Food module only; self-hides off-Food and when there are no featured Food stores.
/// Shared by the User App and Web homes.
class MoonjoinFoodTopBrands extends StatefulWidget {
  const MoonjoinFoodTopBrands({super.key});

  @override
  State<MoonjoinFoodTopBrands> createState() => _MoonjoinFoodTopBrandsState();
}

class _MoonjoinFoodTopBrandsState extends State<MoonjoinFoodTopBrands> {
  bool get _isFood => Get.find<SplashController>().module?.moduleType == AppConstants.food;

  @override
  void initState() {
    super.initState();
    // Ensure featured (Food) stores are loaded for this home; guarded so it does
    // not duplicate a load the home lifecycle already performed.
    if (_isFood && Get.find<StoreController>().featuredStoreList == null) {
      Get.find<StoreController>().getFeaturedStoreList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFood) return const SizedBox();

    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? stores = storeController.featuredStoreList;
      final List<MoonjoinTopBrandItem>? items = stores
          ?.map((s) => MoonjoinTopBrandItem(
                name: s.name ?? '',
                imageUrl: s.logoFullUrl,
                onTap: () => Get.toNamed(RouteHelper.getStoreRoute(id: s.id, page: 'store')),
              ))
          .toList();

      return MoonjoinTopBrandsSection(
        title: 'top_brands'.tr,
        items: items,
        onSeeAll: () => Get.toNamed(RouteHelper.getAllStoreRoute('featured')),
      );
    });
  }
}
