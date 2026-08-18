import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/util/app_constants.dart';

class AddressHelper {

  static Future<bool> saveUserAddressInSharedPref(AddressModel address) async {
    SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    String userAddress = jsonEncode(address.toJson());
    Get.find<ApiClient>().updateHeader(
      sharedPreferences.getString(AppConstants.token),
      address.zoneIds,[],
      sharedPreferences.getString(AppConstants.languageCode),
      Get.find<SplashController>().module?.id,
      address.latitude,
      address.longitude,
    );
    return await sharedPreferences.setString(AppConstants.userAddress, userAddress);
  }

  static AddressModel? getUserAddressFromSharedPref() {
    SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    AddressModel? addressModel;
    try {
      addressModel = AddressModel.fromJson(jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!));
    }catch(e) {
      if(!GetPlatform.isWeb) {
        debugPrint('Address Catch exception : $e');
      }
    }
    return addressModel;
  }

  static bool clearAddressFromSharedPref() {
    SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    sharedPreferences.remove(AppConstants.userAddress);
    return true;
  }

}