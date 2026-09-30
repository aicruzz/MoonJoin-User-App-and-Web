import 'package:get/get.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/home/domain/models/advertisement_model.dart';
import 'package:moonjoin/features/home/domain/services/advertisement_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';

class AdvertisementController extends GetxController implements GetxService {
  final AdvertisementServiceInterface advertisementServiceInterface;
  AdvertisementController({required this.advertisementServiceInterface});

  List<AdvertisementModel>? _advertisementList;
  List<AdvertisementModel>? get advertisementList => _advertisementList;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Duration autoPlayDuration = const Duration(seconds: 7);

  bool autoPlay = true;

  /// Drops the in-memory ads on a module switch so the new module never shows
  /// the previous module's ads while its own ads load. The persistent (module-scoped)
  /// cache is untouched.
  void clearAdvertisementList() {
    _advertisementList = null;
  }

  Future<void> getAdvertisementList({DataSourceEnum dataSource = DataSourceEnum.local}) async {
    // A load that finishes after the user switched module belongs to the previous
    // module: it is not applied (the repository already cached it under that
    // module's own key), so the new module never shows it.
    final int? moduleId = Get.find<SplashController>().module?.id;
    List<AdvertisementModel>? responseAdvertisement;
    if(dataSource == DataSourceEnum.local) {
      responseAdvertisement = await advertisementServiceInterface.getAdvertisementList(dataSource);
      if (Get.find<SplashController>().module?.id != moduleId) {
        return;
      }
      if (responseAdvertisement != null) {
        _advertisementList = responseAdvertisement;
      }
      update();
      getAdvertisementList(dataSource: DataSourceEnum.client);
    } else {
      responseAdvertisement = await advertisementServiceInterface.getAdvertisementList(dataSource);
      if (Get.find<SplashController>().module?.id != moduleId) {
        return;
      }
      if (responseAdvertisement != null) {
        _advertisementList = responseAdvertisement;
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

  void updateAutoPlayStatus({bool shouldUpdate = false, bool status = false}){
    autoPlay = status;
    if(shouldUpdate){
      update();
    }
  }

}