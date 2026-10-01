import 'package:flutter/foundation.dart';
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:get/get.dart';

class ApiChecker {
  /// The session clear started by a 401 that is still running. 401s arriving
  /// meanwhile join it instead of clearing the session, logging in as guest and
  /// navigating again. Released when it finishes (also on error), so a later
  /// 401 is handled as before.
  static Future<void>? _sessionRecovery;

  @visibleForTesting
  static Future<void>? get sessionRecovery => _sessionRecovery;

  static void checkApi(Response response, {bool getXSnackBar = false}) {
    if(response.statusCode == 401) {
      _sessionRecovery ??= _recoverSession().whenComplete(() => _sessionRecovery = null);
    }else {
      if(response.statusText != 'The guest id field is required.') {
        showCustomSnackBar(response.statusText, getXSnackBar: getXSnackBar);
      }
    }
  }

  static Future<void> _recoverSession() async {
    await Get.find<AuthController>().clearSharedData(removeToken: false);
    Get.find<FavouriteController>().removeFavourite();
    Get.offAllNamed(RouteHelper.getInitialRoute());
  }
}
