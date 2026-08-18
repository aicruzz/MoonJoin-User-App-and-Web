import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_top_brand_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin Food Top Brands (ui-designs/Top_Brands.png) — featured Food
/// restaurants/stores as a premium row of brand-filled cards
/// (`MoonjoinTopBrandCard`), with a "Top Brands" heading and green "See all".
///
/// PRESENTATION ONLY. It consumes the existing featured-store capability
/// (`StoreController.featuredStoreList` → `GET .../stores/get-stores/all?featured=1`,
/// already module- + zone-scoped by the backend). Food module only — never the
/// Ecommerce/Fashion product-brand API. Self-hides when there are no featured Food
/// stores; tapping opens the store; shared by the User App and Web homes.
class MoonjoinFoodTopBrands extends StatefulWidget {
  const MoonjoinFoodTopBrands({super.key});

  @override
  State<MoonjoinFoodTopBrands> createState() => _MoonjoinFoodTopBrandsState();
}

class _MoonjoinFoodTopBrandsState extends State<MoonjoinFoodTopBrands> {
  static const double _hPadding = Dimensions.paddingSizeDefault; // row side padding
  static const double _gap = Dimensions.paddingSizeSmall;        // gap between cards

  bool get _isFood => Get.find<SplashController>().module?.moduleType == AppConstants.food;

  /// Compact card width (ui-designs/Top_Brands.png): exactly FOUR complete cards
  /// across the viewport (4 cards + 3 gaps + 2 side paddings == width). The card is
  /// near-square (height == width). Capped so wide web layouts do not blow the
  /// cards up (there the row simply shows more than four).
  double _cardWidth(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return ((w - (_hPadding * 2) - (_gap * 3)) / 4).clamp(70.0, 120.0);
  }

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
    final Color green = Theme.of(context).primaryColor;
    final double cardW = _cardWidth(context);
    final double rowH = cardW; // near-square card (ui-designs/Top_Brands.png)

    return GetBuilder<StoreController>(builder: (storeController) {
      final List<Store>? stores = storeController.featuredStoreList;
      if (stores != null && stores.isEmpty) return const SizedBox();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(_hPadding, Dimensions.paddingSizeSmall, _hPadding, Dimensions.paddingSizeSmall),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('top_brands'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            InkWell(
              onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute('featured')),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('see_all'.tr, style: robotoMedium.copyWith(color: green, fontSize: Dimensions.fontSizeSmall)),
                Icon(Icons.chevron_right, size: 18, color: green),
              ]),
            ),
          ]),
        ),

        SizedBox(
          height: rowH,
          child: stores != null
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: _hPadding),
                  itemCount: stores.length,
                  separatorBuilder: (context, index) => const SizedBox(width: _gap),
                  itemBuilder: (context, index) {
                    final Store s = stores[index];
                    return MoonjoinTopBrandCard(
                      name: s.name ?? '',
                      imageUrl: s.logoFullUrl,
                      width: cardW,
                      onTap: () => Get.toNamed(RouteHelper.getStoreRoute(id: s.id, page: 'store')),
                    );
                  },
                )
              : _TopBrandsShimmer(cardWidth: cardW),
        ),
      ]);
    });
  }
}

class _TopBrandsShimmer extends StatelessWidget {
  final double cardWidth;
  const _TopBrandsShimmer({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        ),
      ),
    );
  }
}
