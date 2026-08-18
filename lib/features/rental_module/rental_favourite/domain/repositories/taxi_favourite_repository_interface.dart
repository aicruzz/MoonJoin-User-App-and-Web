import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/interfaces/repository_interface.dart';

abstract class TaxiFavouriteRepositoryInterface extends RepositoryInterface {
  @override
  Future<ResponseModel> delete(int? id, {bool isProvider = false});
  Future<ResponseModel> addVehicleFavouriteList(int id, bool isProvider);
}