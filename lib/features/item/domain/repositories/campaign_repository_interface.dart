import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/interfaces/repository_interface.dart';

abstract class CampaignRepositoryInterface implements RepositoryInterface {
  @override
  Future getList({int? offset, bool isBasicCampaign = false, bool isItemCampaign = false, DataSourceEnum source});
}