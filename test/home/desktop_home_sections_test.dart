// Slice D3a — Home skips the lists only the desktop layout (WebNewHomeScreen)
// renders when it will show the mobile storefront (AllStoreScreen). If the
// desktop layout appears later (resize / iPad rotation to >= 1300), it loads
// them itself — only when they were actually skipped, only what is missing, and
// everything again if the lists in memory belong to another module. A normal
// desktop start loads nothing twice.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/models/promotional_banner_model.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/home/helpers/desktop_home_sections.dart';
import 'package:moonjoin/features/item/controllers/campaign_controller.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/basic_campaign_model.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/services/campaign_service_interface.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';
import 'package:moonjoin/util/app_constants.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}
class _StoreService extends _NoSuch implements StoreServiceInterface {}
class _ItemService extends _NoSuch implements ItemServiceInterface {}
class _CampaignService extends _NoSuch implements CampaignServiceInterface {}
class _BannerService extends _NoSuch implements BannerServiceInterface {}
class _AuthService extends _NoSuch implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;
}

/// Every desktop-only load is recorded here, with its reload flag where it has one.
final List<String> _loads = <String>[];

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  ModuleModel? active;
  bool parcel = false;
  bool taxi = false;
  @override
  ModuleModel? get module => active;
  @override
  ConfigModel? get configModel => ConfigModel(moduleConfig: ModuleConfig(module: Module(isParcel: parcel, isTaxi: taxi)));
}

class _Auth extends AuthController {
  _Auth() : super(authServiceInterface: _AuthService());
  bool loggedIn = false;
  @override
  bool isLoggedIn() => loggedIn;
}

class _Store extends StoreController {
  _Store() : super(storeServiceInterface: _StoreService());
  List<Store>? recommended, popular, topOffer, visitAgain;
  StoreModel? model;
  @override List<Store>? get recommendedStoreList => recommended;
  @override List<Store>? get popularStoreList => popular;
  @override List<Store>? get topOfferStoreList => topOffer;
  @override List<Store>? get visitAgainStoreList => visitAgain;
  @override StoreModel? get storeModel => model;
  @override
  Future<void> getRecommendedStoreList({dynamic dataSource, bool fromRecall = false}) async => _loads.add('recommendedStores');
  @override
  Future<void> getPopularStoreList(bool reload, String type, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _loads.add('popularStores(reload=$reload)');
  @override
  Future<void> getTopOfferStoreList(bool reload, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _loads.add('topOfferStores(reload=$reload)');
  @override
  Future<void> getStoreList(int offset, bool reload, {dynamic source}) async => _loads.add('storeGrid(reload=$reload)');
  @override
  Future<void> getVisitAgainStoreList({bool fromModule = false, dynamic dataSource, bool fromRecall = false}) async => _loads.add('visitAgain');
}

class _Item extends ItemController {
  _Item() : super(itemServiceInterface: _ItemService());
  List<Item>? reviewed, recommended;
  ItemModel? featuredCategories;
  @override List<Item>? get reviewedItemList => reviewed;
  @override List<Item>? get recommendedItemList => recommended;
  @override ItemModel? get featuredCategoriesItem => featuredCategories;
  @override
  Future<void> getReviewedItemList({required String offset, dynamic dataSource, bool notify = false, bool firstTimeCategoryLoad = false}) async => _loads.add('reviewedItems');
  @override
  Future<void> getRecommendedItemList(bool reload, String type, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _loads.add('recommendedItems(reload=$reload)');
  @override
  Future<void> getFeaturedCategoriesItemList(bool reload, bool notify, {dynamic dataSource, bool fromRecall = false}) async => _loads.add('featuredCategories(reload=$reload)');
}

class _Campaign extends CampaignController {
  _Campaign() : super(campaignServiceInterface: _CampaignService());
  List<BasicCampaignModel>? basic;
  @override List<BasicCampaignModel>? get basicCampaignList => basic;
  @override
  Future<void> getBasicCampaignList(bool reload, {dynamic dataSource, bool fromRecall = false}) async => _loads.add('basicCampaigns(reload=$reload)');
}

class _Banner extends BannerController {
  _Banner() : super(bannerServiceInterface: _BannerService());
  PromotionalBanner? promo;
  @override PromotionalBanner? get promotionalBanner => promo;
  @override
  Future<void> getPromotionalBannerList(bool reload) async => _loads.add('promotionalBanner(reload=$reload)');
}

final ModuleModel _food = ModuleModel(id: 3, moduleType: AppConstants.food);
final ModuleModel _grocery = ModuleModel(id: 5, moduleType: AppConstants.grocery);
final ModuleModel _fashion = ModuleModel(id: 8, moduleType: AppConstants.ecommerce);

/// Desktop lists never loaded for the current module → all loaded fresh (reload).
const List<String> _storefrontAll = <String>[
  'recommendedStores', 'promotionalBanner(reload=true)', 'reviewedItems', 'popularStores(reload=true)',
  'basicCampaigns(reload=true)', 'topOfferStores(reload=true)', 'recommendedItems(reload=true)', 'storeGrid(reload=true)',
];

void main() {
  group('shouldLoadDesktopOnlyHomeSections — same layout choice as HomeScreen.build', () {
    const List<String> storefronts = <String>[AppConstants.food, AppConstants.grocery, AppConstants.pharmacy, AppConstants.ecommerce];

    for (final String type in storefronts) {
      test('mobile layout, $type (Fashion is ecommerce) → AllStoreScreen → desktop-only lists skipped', () {
        expect(homeRendersMobileStorefront(isDesktop: false, moduleType: type), isTrue);
        expect(shouldLoadDesktopOnlyHomeSections(isDesktop: false, moduleType: type), isFalse);
      });
      test('desktop layout (web, iPad landscape, large tablet >= 1300), $type → loaded', () {
        expect(shouldLoadDesktopOnlyHomeSections(isDesktop: true, moduleType: type), isTrue);
      });
    }

    test('All Module (no module) on mobile is not the storefront → unchanged (loaded)', () {
      expect(shouldLoadDesktopOnlyHomeSections(isDesktop: false, moduleType: null), isTrue);
      expect(shouldLoadDesktopOnlyHomeSections(isDesktop: true, moduleType: null), isTrue);
    });

    test('Parcel / Rental on mobile are not the storefront → unchanged', () {
      expect(shouldLoadDesktopOnlyHomeSections(isDesktop: false, moduleType: AppConstants.parcel), isTrue);
      expect(shouldLoadDesktopOnlyHomeSections(isDesktop: false, moduleType: AppConstants.taxi), isTrue);
    });
  });

  group('DesktopHomeSections.loadIfSkipped — desktop layout fallback', () {
    late _Splash splash;
    late _Auth auth;
    late _Store store;
    late _Item item;
    late _Campaign campaign;
    late _Banner banner;

    setUp(() {
      Get.testMode = true;
      _loads.clear();
      DesktopHomeSections.skipped = false;
      DesktopHomeSections.loadedForModuleId = null;
      splash = _Splash()..active = _food;
      auth = _Auth();
      store = _Store();
      item = _Item();
      campaign = _Campaign();
      banner = _Banner();
      Get.put<SplashController>(splash);
      Get.put<AuthController>(auth);
      Get.put<StoreController>(store);
      Get.put<ItemController>(item);
      Get.put<CampaignController>(campaign);
      Get.put<BannerController>(banner);
    });

    tearDown(Get.reset);

    test('normal desktop start (loadData loaded everything): mounting the desktop loads NOTHING again', () {
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: true, moduleId: 3);
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, isEmpty);
    });

    test('mobile Food load skipped them (never loaded for Food) → resize/rotate to desktop loads every list (guest)', () {
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: false, moduleId: 3);
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, unorderedEquals(_storefrontAll));
    });

    test('logged in: visit-again is loaded too', () {
      auth.loggedIn = true;
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: false, moduleId: 3);
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, unorderedEquals(<String>[..._storefrontAll, 'visitAgain']));
    });

    test('Ecommerce/Fashion: featured categories are loaded too', () {
      splash.active = _fashion;
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: false, moduleId: 8);
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, unorderedEquals(<String>[..._storefrontAll, 'featuredCategories(reload=true)']));
    });

    test('same module, some lists already present → only the missing ones are loaded', () {
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: true, moduleId: 3);   // desktop earlier
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: false, moduleId: 3);  // then mobile, same module
      store.recommended = <Store>[];
      store.popular = <Store>[];
      store.topOffer = <Store>[];
      store.model = StoreModel();
      item.reviewed = <Item>[];
      campaign.basic = <BasicCampaignModel>[];
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, unorderedEquals(<String>['promotionalBanner(reload=false)', 'recommendedItems(reload=false)']));
    });

    test('module switched while on the mobile layout → all lists are reloaded for the current module', () {
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: true, moduleId: 3);   // Food on desktop
      splash.active = _grocery;
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: false, moduleId: 5);  // Grocery on mobile
      store.recommended = <Store>[];                                                  // Food's lists still in memory
      store.popular = <Store>[];
      store.topOffer = <Store>[];
      store.model = StoreModel();
      item.reviewed = <Item>[];
      item.recommended = <Item>[];
      campaign.basic = <BasicCampaignModel>[];
      banner.promo = PromotionalBanner();
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, unorderedEquals(_storefrontAll));
    });

    test('runs once per skip: a second desktop mount does not reload', () {
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: false, moduleId: 3);
      DesktopHomeSections.loadIfSkipped();
      _loads.clear();
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, isEmpty);
    });

    test('Parcel/Rental: no storefront lists (only visit-again when logged in, as loadData does)', () {
      auth.loggedIn = true;
      splash.parcel = true;
      DesktopHomeSections.recordHomeLoad(loadedDesktopSections: false, moduleId: 12);
      DesktopHomeSections.loadIfSkipped();
      expect(_loads, <String>['visitAgain']);
    });
  });
}
