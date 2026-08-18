import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/basic_campaign_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// "Special Offers for You" — a horizontal list of the featured promo banners
/// rendered as rounded cards, matching `home.png`. Presentation only: it reads
/// the existing [BannerController] data and reuses the exact banner navigation
/// behaviour (Item / Store / Campaign / external URL).
class SpecialOffersView extends StatelessWidget {
  const SpecialOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BannerController>(builder: (bannerController) {
      final List<String?>? bannerList = bannerController.featuredBannerList;
      final List<dynamic>? bannerDataList = bannerController.featuredBannerDataList;

      if (bannerList != null && bannerList.isEmpty) return const SizedBox();

      final double cardWidth = MediaQuery.of(context).size.width * 0.74;
      final double cardHeight = cardWidth * 0.42;

      if (bannerList == null) {
        return Shimmer(
          duration: const Duration(seconds: 2),
          child: Container(
            height: cardHeight,
            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
          ),
        );
      }

      return SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: bannerList.length,
          separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => _onBannerTap(context, bannerDataList?[index]),
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              child: SizedBox(
                width: cardWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: CustomImage(image: '${bannerList[index]}', fit: BoxFit.cover, width: cardWidth, height: cardHeight),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Future<void> _onBannerTap(BuildContext context, dynamic data) async {
    if (data is Item) {
      Get.find<ItemController>().navigateToItemPage(data, context);
    } else if (data is Store) {
      final Store store = data;
      final zone = AddressHelper.getUserAddressFromSharedPref()?.zoneData;
      if (zone != null && zone.isNotEmpty) {
        for (ModuleModel module in Get.find<SplashController>().moduleList ?? []) {
          if (module.id == store.moduleId) {
            Get.find<SplashController>().setModule(module);
            break;
          }
        }
        final ZoneData zoneData = zone.firstWhere((d) => d.id == store.zoneId);
        final Modules module = zoneData.modules!.firstWhere((m) => m.id == store.moduleId);
        Get.find<SplashController>().setModule(ModuleModel(
          id: module.id, moduleName: module.moduleName, moduleType: module.moduleType,
          themeId: module.themeId, storesCount: module.storesCount,
        ));
      }
      Get.toNamed(
        RouteHelper.getStoreRoute(id: store.id, page: 'module'),
        arguments: StoreScreen(store: store, fromModule: true),
      );
    } else if (data is BasicCampaignModel) {
      Get.toNamed(RouteHelper.getBasicCampaignRoute(data));
    } else if (data is String) {
      if (await canLaunchUrlString(data)) {
        await launchUrlString(data, mode: LaunchMode.externalApplication);
      } else {
        showCustomSnackBar('unable_to_found_url'.tr);
      }
    }
  }
}
