import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/highlight_widget.dart';
import 'package:sixam_mart/features/home/widgets/views/product_with_categories_view.dart';
import 'package:sixam_mart/features/home/widgets/views/best_store_nearby_view.dart';
import 'package:sixam_mart/features/home/widgets/views/common_condition_view.dart';
import 'package:sixam_mart/features/home/widgets/views/just_for_you_view.dart';
import 'package:sixam_mart/features/home/widgets/views/middle_section_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/new_on_mart_view.dart';
import 'package:sixam_mart/features/home/widgets/views/promotional_banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/recommended_store_view.dart';
import 'package:sixam_mart/features/home/widgets/views/top_offers_near_me.dart';
import 'package:sixam_mart/features/home/widgets/views/visit_again_view.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/views/category_view.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

class PharmacyHomeScreen extends StatelessWidget {
  /// See [GroceryHomeScreen.storefrontMode]: when true, render only the
  /// pharmacy-unique sections (products-by-category, common conditions, etc.);
  /// the banner/category/store strips come from the shared [AllStoreScreen] shell.
  final bool storefrontMode;
  const PharmacyHomeScreen({super.key, this.storefrontMode = false});

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      if (!storefrontMode) Container(
        width: MediaQuery.of(context).size.width,
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        child:  const Column(
          children: [
            BannerView(isFeatured: false),
            SizedBox(height: 12),
          ],
        ),
      ),

      if (!storefrontMode) const CategoryView(),
      isLoggedIn ? const VisitAgainView() : const SizedBox(),
      if (!storefrontMode) const RecommendedStoreView(),
      const ProductWithCategoriesView(),
      const HighlightWidget(),
      const MiddleSectionBannerView(),
      if (!storefrontMode) const BestStoreNearbyView(),
      const JustForYouView(),
      if (!storefrontMode) const TopOffersNearMe(),
      if (!storefrontMode) const NewOnMartView(isShop: false, isPharmacy: true, isNewStore: true),
      const CommonConditionView(),
      const PromotionalBannerView(),

    ]);
  }
}
