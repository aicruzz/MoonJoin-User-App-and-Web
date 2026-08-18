import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/brands/domain/models/brands_model.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/interfaces/repository_interface.dart';

abstract class BrandsRepositoryInterface extends RepositoryInterface {
  Future<ItemModel?> getBrandItemList({required int brandId, int? offset});
  Future<List<BrandModel>?> getBrandList({required DataSourceEnum source});
}