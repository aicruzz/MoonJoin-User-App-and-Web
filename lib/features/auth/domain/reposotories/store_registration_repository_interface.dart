import 'package:get/get_connect.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/features/auth/domain/models/store_body_model.dart';
import 'package:moonjoin/features/business/domain/models/package_model.dart';
import 'package:moonjoin/interfaces/repository_interface.dart';

abstract class StoreRegistrationRepositoryInterface extends RepositoryInterface{
  Future<Response> registerStore(StoreBodyModel store, XFile? logo, XFile? cover, List<MultipartDocument> tinFiles);
  Future<bool> checkInZone(String? lat, String? lng, int zoneId);
  Future<PackageModel?> getPackageList({int? moduleId});
}