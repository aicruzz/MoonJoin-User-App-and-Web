import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/features/profile/domain/models/update_user_model.dart';
import 'package:moonjoin/features/profile/domain/models/userinfo_model.dart';
import 'package:moonjoin/interfaces/repository_interface.dart';

abstract class ProfileRepositoryInterface extends RepositoryInterface {
  //Future<dynamic> updateProfile(UserInfoModel userInfoModel, XFile? data, String token);
  Future<ResponseModel> updateProfile(UpdateUserModel userInfoModel, XFile? data, String token);
  Future<dynamic> changePassword(UserInfoModel userInfoModel);
  Future<Response> generateVirtualAccount();
}