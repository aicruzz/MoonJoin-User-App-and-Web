import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/card_design/store_card_with_distance.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/widgets/moonjoin_store_card.dart';
import 'package:sixam_mart/features/home/widgets/web/web_new_on_view_widget.dart';
import 'package:sixam_mart/helper/module_terminology_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:get/get.dart';

class NewOnMartView extends StatelessWidget {
  final bool isPharmacy;
  final bool isShop;
  final bool isNewStore;
  const NewOnMartView({super.key, required this.isPharmacy, required this.isShop, this.isNewStore = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreController>(builder: (storeController) {
      List<Store>? storeList = storeController.latestStoreList;

      return storeList != null ? storeList.isNotEmpty ? Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Column(children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: TitleWidget(
              title: ModuleTerminology.newOnHeader(Get.find<SplashController>().module),
              onTap: () => Get.toNamed(RouteHelper.getAllStoreRoute('latest')),
            ),
          ),
          // const SizedBox(height: Dimensions.paddingSizeSmall),

          (isPharmacy || isShop) ? SizedBox(
            height: 215,
            child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                itemCount: storeList.length,
                itemBuilder: (context, index){
                  return Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
                    child: StoreCardWithDistance(store: storeList[index], isNewStore: isNewStore),
                  );
                }),
          ) : _moonjoinStrip(storeController.sortStoresOpenFirst(storeList)),
        ]),
      ) : const SizedBox.shrink() : const WebNewOnShimmerView();
    });
  }

  /// The "New on MoonJoin" strip reuses the frozen All Restaurants card
  /// (MoonjoinStoreCard) — same approved design + closed-store treatment — and is
  /// fed the open-first ordering so open stores lead, consistent with the lists.
  Widget _moonjoinStrip(List<Store> stores) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        controller: ScrollController(),
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
        itemCount: stores.length,
        itemBuilder: (context, index){
          return Padding(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
            child: SizedBox(
              width: 280,
              child: MoonjoinStoreCard(
                store: stores[index],
                onTap: () => _openStore(stores[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ensure the store's module is active, then open its page — identical to the
  /// frozen AllStoreScreen behaviour (no new business logic).
  void _openStore(Store store) {
    for (ModuleModel module in Get.find<SplashController>().moduleList ?? []) {
      if (module.id == store.moduleId) {
        Get.find<SplashController>().setModule(module);
        break;
      }
    }
    Get.toNamed(RouteHelper.getStoreRoute(id: store.id, page: 'store'));
  }
}

class PopularStoreShimmer extends StatelessWidget {
  final StoreController storeController;
  const PopularStoreShimmer({super.key, required this.storeController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
        itemCount: 10,
        itemBuilder: (context, index){
          return Container(
            height: 150, width: 200,
            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: 5),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10, spreadRadius: 1)],
            ),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Container(
                  height: 90, width: 200,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusSmall)),
                      color: Colors.grey[300],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [

                      Container(height: 10, width: 100, color: Colors.grey[300]),
                      const SizedBox(height: 5),

                      Container(height: 10, width: 130, color: Colors.grey[300]),
                      const SizedBox(height: 5),

                      const RatingBar(rating: 0.0, size: 12, ratingCount: 0),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

