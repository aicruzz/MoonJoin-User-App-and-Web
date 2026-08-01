import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/moonjoin/delivery_man_tips.dart';

/// Checkout Delivery Man Tips — thin controller wiring around the shared
/// [DeliveryManTips] component. All CheckoutController + wallet/partial-pay logic
/// stays here (in the callbacks); the tip UI itself is the shared MoonJoin
/// component. Tip amounts come from the dynamic `AppConstants.tips`
/// (DeliveryManTipsConfig → backend/admin config).
class DeliveryManTipsSection extends StatefulWidget {
  final bool takeAway;
  final JustTheController tooltipController3;
  final double totalPrice;
  final Function(double x) onTotalChange;
  final int? storeId;
  const DeliveryManTipsSection({ super.key, required this.takeAway, required this.tooltipController3, required this.totalPrice, required this.onTotalChange, this.storeId});

  @override
  State<DeliveryManTipsSection> createState() => _DeliveryManTipsSectionState();
}

class _DeliveryManTipsSectionState extends State<DeliveryManTipsSection> {
  bool canCheckSmall = false;

  @override
  Widget build(BuildContext context) {
    double total = widget.totalPrice;
    return GetBuilder<CheckoutController>(
      builder: (checkoutController) {
        final bool show = !widget.takeAway && Get.find<SplashController>().configModel!.dmTipsStatus == 1;
        return Column(
          children: [
            show ? DeliveryManTips(
              margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault),
              selectedIndex: checkoutController.selectedTips,
              showCustomField: (checkoutController.selectedTips == AppConstants.tips.length - 1) && checkoutController.canShowTipsField,
              mostTipAmount: checkoutController.mostDmTipAmount,
              saveForLater: checkoutController.isDmTipSave,
              customController: checkoutController.tipController,
              tooltipController: widget.tooltipController3,
              onSelectTip: (index) async {
                total = total - checkoutController.tips;
                checkoutController.updateTips(index);
                if (checkoutController.selectedTips != AppConstants.tips.length - 1) {
                  checkoutController.addTips(double.parse(AppConstants.tips[index]));
                }
                if (checkoutController.selectedTips == AppConstants.tips.length - 1) {
                  checkoutController.showTipsField();
                }
                checkoutController.tipController.text = checkoutController.tips.toString();
                if (checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1) {
                  checkoutController.checkBalanceStatus((total + checkoutController.tips), 0);
                }
              },
              onToggleSave: () => checkoutController.toggleDmTipSave(),
              onCustomChanged: (String value) async {
                if (value.isNotEmpty) {
                  try {
                    if (double.parse(value) >= 0) {
                      if (AuthHelper.isLoggedIn()) {
                        total = total - checkoutController.tips;
                        await checkoutController.addTips(double.parse(value));
                        total = total + checkoutController.tips;
                        widget.onTotalChange(total);
                        if (Get.find<ProfileController>().userInfoModel!.walletBalance! < total && checkoutController.paymentMethodIndex == 1) {
                          checkoutController.checkBalanceStatus(total, 0);
                          canCheckSmall = true;
                        } else if (Get.find<ProfileController>().userInfoModel!.walletBalance! > total && canCheckSmall && checkoutController.isPartialPay) {
                          checkoutController.checkBalanceStatus(total, 0);
                        }
                      } else {
                        checkoutController.addTips(double.parse(value));
                      }
                    } else {
                      showCustomSnackBar('tips_can_not_be_negative'.tr);
                    }
                  } catch (e) {
                    showCustomSnackBar('invalid_input'.tr);
                    checkoutController.addTips(0.0);
                    checkoutController.tipController.text = checkoutController.tipController.text.substring(0, checkoutController.tipController.text.length - 1);
                    checkoutController.tipController.selection = TextSelection.collapsed(offset: checkoutController.tipController.text.length);
                  }
                } else {
                  checkoutController.addTips(0.0);
                }
              },
              onClearCustom: () {
                checkoutController.updateTips(0);
                checkoutController.showTipsField();
                if (checkoutController.isPartialPay) {
                  checkoutController.changePartialPayment();
                }
              },
            ) : const SizedBox.shrink(),

            SizedBox(height: (!widget.takeAway && widget.storeId == null && Get.find<SplashController>().configModel!.dmTipsStatus == 1)
                ? Dimensions.paddingSizeSmall : 0),
          ],
        );
      }
    );
  }
}
