import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/banner/domain/models/banner_model.dart';
import 'package:moonjoin/features/banner/domain/models/others_banner_model.dart';
import 'package:moonjoin/features/banner/domain/models/promotional_banner_model.dart';
import 'package:get/get.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';

class BannerController extends GetxController implements GetxService {
  final BannerServiceInterface bannerServiceInterface;
  BannerController({required this.bannerServiceInterface});

  List<String?>? _bannerImageList;
  List<String?>? get bannerImageList => _bannerImageList;
  
  List<String?>? _taxiBannerImageList;
  List<String?>? get taxiBannerImageList => _taxiBannerImageList;
  
  List<String?>? _featuredBannerList;
  List<String?>? get featuredBannerList => _featuredBannerList;
  
  List<dynamic>? _bannerDataList;
  List<dynamic>? get bannerDataList => _bannerDataList;
  
  List<dynamic>? _taxiBannerDataList;
  List<dynamic>? get taxiBannerDataList => _taxiBannerDataList;
  
  List<dynamic>? _featuredBannerDataList;
  List<dynamic>? get featuredBannerDataList => _featuredBannerDataList;

  /// Web Performance Slice 3. Index-aligned with [bannerImageList] /
  /// [featuredBannerList]: entry i holds the `image_variants` of the banner whose
  /// URL is entry i there, or null for a campaign or a banner with none. Built in
  /// the same iteration as the URL lists, which keep their exact existing values.
  List<Map<String, String>?>? _bannerVariantList;
  List<Map<String, String>?>? get bannerVariantList => _bannerVariantList;

  List<Map<String, String>?>? _featuredBannerVariantList;
  List<Map<String, String>?>? get featuredBannerVariantList => _featuredBannerVariantList;
  
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  
  ParcelOtherBannerModel? _parcelOtherBannerModel;
  ParcelOtherBannerModel? get parcelOtherBannerModel => _parcelOtherBannerModel;
  
  PromotionalBanner? _promotionalBanner;
  PromotionalBanner? get promotionalBanner => _promotionalBanner;

  Future<void> getFeaturedBanner() async {
    BannerModel? bannerModel = await bannerServiceInterface.getFeaturedBannerList();
    if (bannerModel != null) {
      _featuredBannerList = [];
      _featuredBannerDataList = [];
      _featuredBannerVariantList = [];

      List<int?> moduleIdList = bannerServiceInterface.moduleIdList();

      for (var campaign in bannerModel.campaigns!) {
        if(_featuredBannerList!.contains(campaign.imageFullUrl)) {
          _featuredBannerList!.add('${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
        } else {
          _featuredBannerList!.add(campaign.imageFullUrl);
        }
        _featuredBannerVariantList!.add(null);
        _featuredBannerDataList!.add(campaign);
      }
      for (var banner in bannerModel.banners!) {
        if(_featuredBannerList!.contains(banner.imageFullUrl)) {
          _featuredBannerList!.add('${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
        } else {
          _featuredBannerList!.add(banner.imageFullUrl);
        }
        _featuredBannerVariantList!.add(banner.imageVariants);
        if(banner.item != null && moduleIdList.contains(banner.item!.moduleId)) {
          _featuredBannerDataList!.add(banner.item);
        }else if(banner.store != null && moduleIdList.contains(banner.store!.moduleId)) {
          _featuredBannerDataList!.add(banner.store);
        }else if(banner.type == 'default') {
          _featuredBannerDataList!.add(banner.link);
        }else{
          _featuredBannerDataList!.add(null);
        }
      }
    }
    update();
  }

  void clearBanner() {
    _bannerImageList = null;
    _bannerVariantList = null;
  }

  Future<void> getBannerList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    if(_bannerImageList == null || reload || fromRecall) {
      if(reload) {
        _bannerImageList = null;
      }
      // A load that finishes after the user switched module belongs to the
      // previous module: it is not applied (the repository already cached it
      // under that module's own key), so the new module never shows it.
      final int? moduleId = Get.find<SplashController>().module?.id;
      BannerModel? bannerModel;
      if(dataSource == DataSourceEnum.local) {
        bannerModel = await bannerServiceInterface.getBannerList(source: DataSourceEnum.local);
        if (Get.find<SplashController>().module?.id != moduleId) {
          return;
        }
        await _prepareBanner(bannerModel);

        getBannerList(false, dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        bannerModel = await bannerServiceInterface.getBannerList(source: DataSourceEnum.client);
        if (Get.find<SplashController>().module?.id != moduleId) {
          return;
        }
        _prepareBanner(bannerModel);
      }

    }
  }

  Future<void> _prepareBanner(BannerModel? bannerModel) async{
    if (bannerModel != null) {
      _bannerImageList = [];
      _bannerDataList = [];
      _bannerVariantList = [];
      for (var campaign in bannerModel.campaigns!) {
        if(_bannerImageList!.contains(campaign.imageFullUrl)) {
          _bannerImageList!.add('${campaign.imageFullUrl}${bannerModel.campaigns!.indexOf(campaign)}');
        } else {
          _bannerImageList!.add(campaign.imageFullUrl);
        }
        _bannerVariantList!.add(null);
        _bannerDataList!.add(campaign);
      }
      for (var banner in bannerModel.banners!) {

        if(_bannerImageList!.contains(banner.imageFullUrl)) {
          _bannerImageList!.add('${banner.imageFullUrl}${bannerModel.banners!.indexOf(banner)}');
        } else {
          _bannerImageList!.add(banner.imageFullUrl);
        }
        _bannerVariantList!.add(banner.imageVariants);

        if(banner.item != null) {
          _bannerDataList!.add(banner.item);
        }else if(banner.store != null){
          _bannerDataList!.add(banner.store);
        }else if(banner.type == 'default'){
          _bannerDataList!.add(banner.link);
        }else{
          _bannerDataList!.add(null);
        }
      }
    }
    update();
  }

  Future<void> getTaxiBannerList(bool reload) async {
    if(_taxiBannerImageList == null || reload) {
      _taxiBannerImageList = null;
      BannerModel? bannerModel = await bannerServiceInterface.getTaxiBannerList();
      if (bannerModel != null) {
        _taxiBannerImageList = [];
        _taxiBannerDataList = [];
        for (var campaign in bannerModel.campaigns!) {
          _taxiBannerImageList!.add(campaign.imageFullUrl);
          _taxiBannerDataList!.add(campaign);
        }
        for (var banner in bannerModel.banners!) {
          _taxiBannerImageList!.add(banner.imageFullUrl);
          if(banner.item != null) {
            _taxiBannerDataList!.add(banner.item);
          }else if(banner.store != null){
            _taxiBannerDataList!.add(banner.store);
          }else if(banner.type == 'default'){
            _taxiBannerDataList!.add(banner.link);
          }else{
            _taxiBannerDataList!.add(null);
          }
        }
        if(ResponsiveHelper.isDesktop(Get.context) && _taxiBannerImageList!.length % 2 != 0){
          _taxiBannerImageList!.add(_taxiBannerImageList![0]);
          _taxiBannerDataList!.add(_taxiBannerDataList![0]);
        }
      }
      update();
    }
  }

  Future<void> getParcelOtherBannerList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    if(_parcelOtherBannerModel == null || reload || fromRecall) {
      ParcelOtherBannerModel? parcelOtherBannerModel;
      if(dataSource == DataSourceEnum.local) {
        parcelOtherBannerModel = await bannerServiceInterface.getParcelOtherBannerList(source: dataSource);
        _prepareParcelBanner(parcelOtherBannerModel);
        getParcelOtherBannerList(false, dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        parcelOtherBannerModel = await bannerServiceInterface.getParcelOtherBannerList(source: dataSource);
        _prepareParcelBanner(parcelOtherBannerModel);
      }
    }
  }

  void _prepareParcelBanner(ParcelOtherBannerModel? parcelOtherBannerModel) {
    if (parcelOtherBannerModel != null) {
      _parcelOtherBannerModel = parcelOtherBannerModel;
    }
    update();
  }

  Future<void> getPromotionalBannerList(bool reload) async {
    if(_promotionalBanner == null || reload) {
      PromotionalBanner? promotionalBanner = await bannerServiceInterface.getPromotionalBannerList();
      if (promotionalBanner != null) {
        _promotionalBanner = promotionalBanner;
      }
      update();
    }
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }
  
}