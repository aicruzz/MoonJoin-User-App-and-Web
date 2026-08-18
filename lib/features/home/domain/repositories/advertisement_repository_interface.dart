import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/home/domain/models/advertisement_model.dart';
import 'package:moonjoin/interfaces/repository_interface.dart';

abstract class AdvertisementRepositoryInterface extends RepositoryInterface{
  @override
  Future<List<AdvertisementModel>?> getList({int? offset, DataSourceEnum source = DataSourceEnum.client});
}