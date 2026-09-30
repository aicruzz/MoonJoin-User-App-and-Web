import 'package:get/get.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/item/controllers/campaign_controller.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/util/app_constants.dart';

/// Whether this Home load will render the mobile storefront (AllStoreScreen).
///
/// Mirrors the existing layout choice in HomeScreen.build: below the desktop
/// breakpoint (ResponsiveHelper.isDesktop, width >= 1300), every storefront
/// module type lands on AllStoreScreen. Desktop — web, native iPad landscape,
/// large tablets — renders WebNewHomeScreen instead.
bool homeRendersMobileStorefront({required bool isDesktop, required String? moduleType}) {
  return !isDesktop && (moduleType == AppConstants.food || moduleType == AppConstants.grocery
      || moduleType == AppConstants.pharmacy || moduleType == AppConstants.ecommerce);
}

/// The Home lists only the desktop layout (WebNewHomeScreen) renders — promotional
/// banner, recommended/popular/top-offer stores, reviewed/recommended items, basic
/// campaigns, the paginated store grid, visit-again, Ecommerce featured categories
/// — are needed unless the mobile storefront is what this load renders.
bool shouldLoadDesktopOnlyHomeSections({required bool isDesktop, required String? moduleType}) {
  return !homeRendersMobileStorefront(isDesktop: isDesktop, moduleType: moduleType);
}

/// Remembers whether HomeScreen.loadData skipped the desktop-only lists, so the
/// desktop layout can load them itself if it appears later (browser resize,
/// iPad rotation to >= 1300). A normal desktop start is not affected: loadData
/// already requested the lists, and nothing is fetched twice.
class DesktopHomeSections {
  DesktopHomeSections._();

  /// True when the latest loadData skipped the desktop-only lists.
  static bool skipped = false;

  /// Module the desktop-only lists were last loaded for (null = none/landing).
  static int? loadedForModuleId;

  /// Called by HomeScreen.loadData after deciding.
  static void recordHomeLoad({required bool loadedDesktopSections, required int? moduleId}) {
    skipped = !loadedDesktopSections;
    if (loadedDesktopSections) {
      loadedForModuleId = moduleId;
    }
  }

  /// Called when WebNewHomeScreen mounts. Loads the desktop-only lists only if
  /// the last Home load skipped them: missing lists are loaded; if the lists in
  /// memory belong to another module (module switched while on the mobile
  /// layout), they are all reloaded so the desktop never shows another module's
  /// data.
  static void loadIfSkipped() {
    if (!skipped) {
      return;
    }
    skipped = false;

    final SplashController splash = Get.find<SplashController>();
    final int? moduleId = splash.module?.id;
    final bool sameModule = loadedForModuleId == moduleId;
    loadedForModuleId = moduleId;

    final StoreController store = Get.find<StoreController>();
    if (AuthHelper.isLoggedIn() && (!sameModule || store.visitAgainStoreList == null)) {
      store.getVisitAgainStoreList();
    }

    final module = splash.configModel?.moduleConfig?.module;
    if (splash.module == null || module == null || module.isParcel! || module.isTaxi!) {
      return;
    }
    final BannerController banner = Get.find<BannerController>();
    final ItemController item = Get.find<ItemController>();
    final CampaignController campaign = Get.find<CampaignController>();
    final bool reload = !sameModule;

    if (!sameModule || store.recommendedStoreList == null) store.getRecommendedStoreList();
    if (splash.module!.moduleType.toString() == AppConstants.ecommerce && (!sameModule || item.featuredCategoriesItem == null)) {
      item.getFeaturedCategoriesItemList(reload, false);
    }
    if (!sameModule || banner.promotionalBanner == null) banner.getPromotionalBannerList(reload);
    if (!sameModule || item.reviewedItemList == null) item.getReviewedItemList(offset: '1', firstTimeCategoryLoad: true);
    if (!sameModule || store.popularStoreList == null) store.getPopularStoreList(reload, 'all', false);
    if (!sameModule || campaign.basicCampaignList == null) campaign.getBasicCampaignList(reload);
    if (!sameModule || store.topOfferStoreList == null) store.getTopOfferStoreList(reload, false);
    if (!sameModule || item.recommendedItemList == null) item.getRecommendedItemList(reload, 'all', false);
    if (!sameModule || store.storeModel == null) store.getStoreList(1, reload);
  }
}
