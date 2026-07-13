import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/string_extension.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_method_bottom_sheet.dart';

class PaymentSection extends StatelessWidget {
  final int? storeId;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final double total;
  final CheckoutController checkoutController;
  final bool isOfflinePaymentActive;
  const PaymentSection({super.key, this.storeId, required this.isCashOnDeliveryActive, required this.isDigitalPaymentActive,
    required this.isWalletActive, required this.total, required this.checkoutController, required this.isOfflinePaymentActive,
  });

  void _openPaymentSheet(BuildContext context) {
    if(isCashOnDeliveryActive || isDigitalPaymentActive || isWalletActive || isOfflinePaymentActive){
      Get.bottomSheet(
        PaymentMethodBottomSheet(
          isCashOnDeliveryActive: isCashOnDeliveryActive, isDigitalPaymentActive: isDigitalPaymentActive,
          totalPrice: total, isOfflinePaymentActive: isOfflinePaymentActive,
        ),
        backgroundColor: Colors.transparent, isScrollControlled: true,
      );
    }else{
      showCustomSnackBar('no_payment_method_found'.tr);
    }
  }

  // MoonJoin selected-payment card (Figma). Tapping opens the redesigned selector sheet.
  Widget _buildMobilePaymentCard(BuildContext context) {
    int index = checkoutController.paymentMethodIndex;
    bool selected = index != -1;

    String title;
    String subtitle;
    String? iconAsset;
    if(index == 0) {
      title = '${'cash_on_delivery'.tr}${checkoutController.isPartialPay ? ' (${'partial'.tr})' : ''}';
      subtitle = 'pay_in_cash_when_your_order_arrives'.tr;
      iconAsset = Images.cash;
    } else if(index == 1 && !checkoutController.isPartialPay) {
      title = 'wallet_payment'.tr;
      subtitle = 'pay_using_your_wallet_balance'.tr;
      iconAsset = Images.wallet;
    } else if(index == 2) {
      title = '${'digital_payment'.tr} (${checkoutController.digitalPaymentName?.replaceAll('_', ' ').toTitleCase() ?? ''}${checkoutController.isPartialPay ? ' - ${'partial'.tr}' : ''})';
      subtitle = 'secure_online_payment'.tr;
      iconAsset = Images.digitalPayment;
    } else if(index == 3) {
      title = '${'offline_payment'.tr} (${checkoutController.offlineMethodList![checkoutController.selectedOfflineBankIndex].methodName}${checkoutController.isPartialPay ? ' - ${'partial'.tr}' : ''})';
      subtitle = 'pay_via_bank_transfer'.tr;
      iconAsset = Images.cash;
    } else {
      title = 'select_payment_method'.tr;
      subtitle = 'no_payment_method_selected'.tr;
      iconAsset = null;
    }

    Color borderColor = selected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.error.withValues(alpha: 0.5);

    return InkWell(
      onTap: () => _openPaymentSheet(context),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor.withValues(alpha: 0.06) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: borderColor, width: selected ? 1.2 : 1),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(children: [
          Container(
            height: 40, width: 40,
            decoration: BoxDecoration(
              color: selected ? Theme.of(context).primaryColor.withValues(alpha: 0.12) : Theme.of(context).disabledColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: iconAsset != null
                ? Image.asset(iconAsset, color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor)
                : Icon(Icons.account_balance_wallet_outlined, size: 20, color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: selected ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).colorScheme.error)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
            ]),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Icon(
            selected ? Icons.radio_button_checked : Icons.chevron_right,
            color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
            size: selected ? 22 : 24,
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(storeId != null ? 'payment_method'.tr : 'choose_payment_method'.tr,
            style: isDesktop ? robotoMedium : robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),

        storeId == null && !isDesktop ? InkWell(
          onTap: () => _openPaymentSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Text('change'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
          ),
        ) : const SizedBox(),
      ]),

      storeId == null && !isDesktop ? Padding(
        padding: const EdgeInsets.only(top: 2, bottom: Dimensions.paddingSizeSmall),
        child: Row(children: [
          Icon(Icons.lock_outline, size: 14, color: Theme.of(context).disabledColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text('all_payments_are_secure_and_encrypted'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
        ]),
      ) : const SizedBox(),

      isDesktop ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

      (storeId == null && !isDesktop) ? _buildMobilePaymentCard(context) : Container(
        decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3), width: 1),
        ) : const BoxDecoration(),
        padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.radiusDefault) : EdgeInsets.zero,
        child: storeId != null ? checkoutController.paymentMethodIndex == 0 ? Row(children: [
          Image.asset(Images.cash , width: 20, height: 20,
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Text('cash_on_delivery'.tr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
          )),

          Text(
            PriceConverter.convertPrice(total), textDirection: TextDirection.ltr,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
          )

        ]) : const SizedBox() : InkWell(
          onTap: () {
            if(ResponsiveHelper.isDesktop(context) && checkoutController.paymentMethodIndex == -1){
              if(isCashOnDeliveryActive || isDigitalPaymentActive || isWalletActive || isOfflinePaymentActive){
                Get.dialog(Dialog(backgroundColor: Colors.transparent, child: PaymentMethodBottomSheet(
                  isCashOnDeliveryActive: isCashOnDeliveryActive, isDigitalPaymentActive: isDigitalPaymentActive,
                  totalPrice: total, isOfflinePaymentActive: isOfflinePaymentActive,
                )));
              }else{
                showCustomSnackBar('no_payment_method_found'.tr);
              }
            }
          },
          child: Row(children: [
            checkoutController.paymentMethodIndex != -1 ? Image.asset(
              checkoutController.paymentMethodIndex == 0 ? Images.cash
                  : checkoutController.paymentMethodIndex == 1 ? Images.wallet
                  : checkoutController.paymentMethodIndex == 2 ? Images.digitalPayment
                  : Images.cash,
              width: 20, height: 20,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ) : Icon(
              !ResponsiveHelper.isDesktop(context) ? Icons.wallet_outlined : Icons.add_circle_outline_sharp,
              size: 18, color: !ResponsiveHelper.isDesktop(context) ? Theme.of(context).disabledColor : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: Row(children: [
                Builder(
                  builder: (context) {
                    return Text(
                      checkoutController.paymentMethodIndex == 0 ? '${'cash_on_delivery'.tr} ${checkoutController.isPartialPay ? '(${'partial'.tr})' : ''}'
                          : checkoutController.paymentMethodIndex == 1 && !checkoutController.isPartialPay ? 'wallet_payment'.tr
                          : checkoutController.paymentMethodIndex == 2 ? '${'digital_payment'.tr} (${checkoutController.digitalPaymentName?.replaceAll('_', ' ').toTitleCase() ?? ''}${checkoutController.isPartialPay ? ' - ${'partial'.tr}' : ''})'
                          : checkoutController.paymentMethodIndex == 3 ? '${'offline_payment'.tr}(${checkoutController.offlineMethodList![checkoutController.selectedOfflineBankIndex].methodName}${checkoutController.isPartialPay ? ' - ${'partial'.tr}' : ''})'
                          : !ResponsiveHelper.isDesktop(context) ? 'select_payment_method'.tr : 'add_payment_method'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: !ResponsiveHelper.isDesktop(context) ? Theme.of(context).disabledColor
                            : checkoutController.paymentMethodIndex == -1 ? Theme.of(context).primaryColor
                            : Theme.of(context).disabledColor,
                      ),
                    );
                  }
                ),

                checkoutController.paymentMethodIndex == -1 && !ResponsiveHelper.isDesktop(context) ? Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                  child: Icon(Icons.warning_rounded, size: 16, color: Theme.of(context).colorScheme.error),
                ) : const SizedBox(),
              ])
            ),
            checkoutController.paymentMethodIndex != -1 ? PriceConverter.convertAnimationPrice(
              checkoutController.viewTotalPrice,
              textStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
            ) : const SizedBox(),
            SizedBox(width: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeSmall : 0),

            storeId == null && ResponsiveHelper.isDesktop(context) ? InkWell(
              onTap: (){
                if(isCashOnDeliveryActive || isDigitalPaymentActive || isWalletActive || isOfflinePaymentActive){
                  Get.dialog(Dialog(backgroundColor: Colors.transparent, child: PaymentMethodBottomSheet(
                    isCashOnDeliveryActive: isCashOnDeliveryActive, isDigitalPaymentActive: isDigitalPaymentActive,
                    totalPrice: total, isOfflinePaymentActive: isOfflinePaymentActive,
                  )));
                }else{
                  showCustomSnackBar('no_payment_method_found'.tr);
                }
              },
              child: Image.asset(Images.paymentSelect, height: 24, width: 24),
            ) : const SizedBox(),
          ]),
        ),
      ),

    ]);
  }
}
