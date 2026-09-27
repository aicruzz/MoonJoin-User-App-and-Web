import 'package:get/get.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';

/// Single source of truth for "is this payment gateway currently active?".
///
/// Reads the existing `ConfigModel.activePaymentMethodList` that Menu, Wallet
/// Add Fund and Checkout already consume — no new state, no hardcoding, and no
/// second gateway mechanism. When Admin disables a gateway it leaves that list,
/// so every surface hides together.
///
/// [methods] is an optional injection point so the rule can be exercised without
/// a registered [SplashController]; production callers omit it.
bool isPaymentGatewayActive(String gateway, {List<PaymentBody>? methods}) {
  List<PaymentBody>? list = methods;
  if (list == null) {
    if (!Get.isRegistered<SplashController>()) {
      return false;
    }
    list = Get.find<SplashController>().configModel?.activePaymentMethodList;
  }
  if (list == null) {
    return false;
  }
  final String target = gateway.toLowerCase();
  return list.any((PaymentBody m) => m.getWay?.toLowerCase() == target);
}

/// The 9PSB virtual-account gateway.
bool is9PSBActive({List<PaymentBody>? methods}) => isPaymentGatewayActive('9psb', methods: methods);
