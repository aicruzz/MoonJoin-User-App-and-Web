import 'dart:convert';

import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/api/local_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/brands/domain/models/brands_model.dart';
import 'package:moonjoin/features/brands/domain/repositories/brands_repository_interface.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/helper/in_flight_requests.dart';

class BrandsRepository implements BrandsRepositoryInterface{
  final ApiClient apiClient;
  /// Shares one in-flight load (request + parse + ONE cache write) between
  /// callers that ask for the same list at the same time, e.g. HomeScreen and
  /// AllStoreScreen in the same frame.
  static final InFlightRequests _inFlight = InFlightRequests();

  BrandsRepository({required this.apiClient});

  @override
  Future<List<BrandModel>?> getBrandList({required DataSourceEnum source}) async {
    List<BrandModel>? brandList;
    String cacheId = '${AppConstants.brandListUri}-${Get.find<SplashController>().module!.id!}';

    switch(source) {
      case DataSourceEnum.client:
        brandList = await _inFlight.run(InFlightRequests.keyFor(AppConstants.brandListUri, apiClient.getHeader()), () async {
          List<BrandModel>? brands;
          Response response = await apiClient.getData(AppConstants.brandListUri);
          if (response.statusCode == 200) {
            brands = [];
            response.body.forEach((brand) => brands!.add(BrandModel.fromJson(brand)));
            LocalClient.organize(source, cacheId, jsonEncode(response.body), apiClient.getHeader());
          }
          return brands;
        });

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(source, cacheId, null, null);
        if(cacheResponseData != null) {
          brandList = [];
          jsonDecode(cacheResponseData).forEach((brand) => brandList!.add(BrandModel.fromJson(brand)));
        }
    }

    return brandList;
  }

  @override
  Future<ItemModel?> getBrandItemList({required int brandId, int? offset}) async {
    ItemModel? brandItemModel;
    Response response = await apiClient.getData('${AppConstants.brandItemUri}/$brandId?offset=$offset&limit=12');
    if (response.statusCode == 200) {
       brandItemModel = ItemModel.fromJson(response.body);
    }
    return brandItemModel;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

}