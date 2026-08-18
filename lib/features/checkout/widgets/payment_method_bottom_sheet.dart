import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/custom_text_field.dart';
import 'package:moonjoin/features/checkout/domain/models/payment_model.dart';
import 'package:moonjoin/features/checkout/widgets/virtual_account_details_widget.dart';
import 'package:moonjoin/features/order/controllers/order_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/checkout/controllers/checkout_controller.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/price_converter.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/features/payment/widgets/offline_payment_button.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isOfflinePaymentActive;
  final double totalPrice;
  final PaymentModel? paymentModel;
  final bool fromHome;
  const PaymentMethodBottomSheet({super.key, required this.isCashOnDeliveryActive, required this.isDigitalPaymentActive,
    required this.totalPrice, required this.isOfflinePaymentActive, this.paymentModel, this.fromHome = false});

  @override
  State<PaymentMethodBottomSheet> createState() => _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  bool notHideCod = true;
  bool notHideDigital = true;
  final JustTheController tooltipController = JustTheController();
  final TextEditingController _amountController = TextEditingController();
  bool showChangeAmount = true;

  @override
  void initState() {
    super.initState();

    CheckoutController checkoutController = Get.find<CheckoutController>();

    if(widget.paymentModel != null) {
      checkoutController.getOfflineMethodList();
      checkoutController.setPaymentMethod(-1, isUpdate: false);
    }

    if(checkoutController.exchangeAmount > 0) {
      showChangeAmount = true;
      _amountController.text = checkoutController.exchangeAmount.toString();
    }

    configurePartialPayment();
  }

  void configurePartialPayment() {
    if(!AuthHelper.isGuestLoggedIn()) {
      if(Get.find<CheckoutController>().isPartialPay){
        if(Get.find<SplashController>().configModel!.partialPaymentMethod! == 'cod'){
          notHideCod = true;
          notHideDigital = false;
        } else if(Get.find<SplashController>().configModel!.partialPaymentMethod! == 'digital_payment'){
          notHideCod = false;
          notHideDigital = true;
        } else if(Get.find<SplashController>().configModel!.partialPaymentMethod! == 'both'){
          notHideCod = true;
          notHideDigital = true;
        }
      } else {
        notHideCod = true;
        notHideDigital = true;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    tooltipController.dispose();
    super.dispose();
  }

  /// Returns true if 9PSB is in the active payment methods list
  bool get _is9PSBActive {
    final list = Get.find<SplashController>().configModel!.activePaymentMethodList;
    if (list == null) return false;
    return list.any((m) => m.getWay?.toLowerCase() == '9psb');
  }

  @override
  Widget build(BuildContext context) {
    bool showOfflinePay = widget.paymentModel != null ? widget.paymentModel?.partiallyPaidAmount == 0 : true;
    return SizedBox(
      width: 550,
      child: GetBuilder<CheckoutController>(builder: (checkoutController) {
        bool disablePayments = checkoutController.paymentMethodIndex == 1 && !checkoutController.isPartialPay;

        // Separate 9PSB from the rest of digital payment methods
        final allMethods = Get.find<SplashController>().configModel!.activePaymentMethodList ?? [];
        final nonPSBMethods = allMethods.where((m) => m.getWay?.toLowerCase() != '9psb').toList();

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: const Radius.circular(Dimensions.radiusLarge), bottom: Radius.circular(ResponsiveHelper.isDesktop(context) ? Dimensions.radiusLarge : 0)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            ResponsiveHelper.isDesktop(context) ? Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => Get.back(),
                child: Container(
                  height: 30, width: 30,
                  margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.clear),
                ),
              ),
            ) : Align(
              alignment: Alignment.center,
              child: Container(
                height: 5, width: 40,
                margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            // MoonJoin premium hero: title + subtitle + total on the left, Figma bank illustration on the right.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('choose_payment_method'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                  const SizedBox(height: 2),
                  Text('choose_how_you_would_like_to_pay_securely'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text('total_amount'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                  const SizedBox(height: 2),
                  Text(PriceConverter.convertPrice(widget.totalPrice), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge + 6, color: Theme.of(context).primaryColor)),
                ])),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Image.asset(Images.virtualAccountBank, width: 96, height: 96, fit: BoxFit.contain),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                child: Column(
                  children: [

                    // Wallet section — virtual account details (9PSB) are embedded inside
                    walletView(checkoutController),

                    widget.isCashOnDeliveryActive && notHideCod ? paymentButtonView(
                      padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                      title: 'cash_on_delivery'.tr,
                      subtitle: 'pay_when_your_order_arrives'.tr,
                      iconData: Icons.payments_outlined,
                      isSelected: checkoutController.paymentMethodIndex == 0,
                      disablePayments: disablePayments,
                      onTap: disablePayments ? null : (){
                        checkoutController.setPaymentMethod(0);
                        if(!showChangeAmount) {
                          setState(() {
                            showChangeAmount = true;
                          });
                        }
                      },
                    ) : const SizedBox(),

                    widget.isCashOnDeliveryActive && notHideCod && widget.paymentModel == null ? changeAmountView(checkoutController) : const SizedBox(),

                    // Digital payments — excludes 9PSB
                    widget.isDigitalPaymentActive && notHideDigital && nonPSBMethods.isNotEmpty ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, left: 2),
                          child: Text('pay_via_online'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                        ),

                        ListView.builder(
                          itemCount: nonPSBMethods.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final paymentMethod = nonPSBMethods[index];
                            bool isSelected = checkoutController.paymentMethodIndex == 2 && paymentMethod.getWay! == checkoutController.digitalPaymentName;

                            return paymentButtonView(
                              padding: EdgeInsets.only(
                                bottom: index == nonPSBMethods.length - 1 ? 0 : Dimensions.paddingSizeSmall,
                              ),
                              disablePayments: disablePayments,
                              onTap: disablePayments ? null : () {
                                checkoutController.setPaymentMethod(2);
                                checkoutController.changeDigitalPaymentName(paymentMethod.getWay!);
                                if(showChangeAmount) {
                                  setState(() {
                                    showChangeAmount = false;
                                  });
                                }
                              },
                              title: paymentMethod.getWayTitle!,
                              subtitle: 'pay_securely_using_supported_gateways'.tr,
                              isSelected: isSelected,
                              image: paymentMethod.getWayImageFullUrl,
                            );
                          },
                        ),
                      ],
                    ) : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    widget.isOfflinePaymentActive && showOfflinePay && !Get.find<CheckoutController>().isPartialPay ? OfflinePaymentButton(
                      isSelected: checkoutController.paymentMethodIndex == 3,
                      offlineMethodList: checkoutController.offlineMethodList,
                      isOfflinePaymentActive: widget.isOfflinePaymentActive,
                      onTap: disablePayments ? null : () {
                        checkoutController.setPaymentMethod(3);
                        if(showChangeAmount) {
                          setState(() {
                            showChangeAmount = false;
                          });
                        }
                      },
                      checkoutController: checkoutController, tooltipController: tooltipController,
                      disablePayment: disablePayments, forParcel: widget.paymentModel?.orderType == 'parcel',
                    ) : const SizedBox(),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
                child: GetBuilder<OrderController>(
                    builder: (orderController) {
                      return CustomButton(
                        buttonText: widget.paymentModel == null ? 'select'.tr : 'proceed'.tr,
                        isLoading: widget.paymentModel != null ? orderController.isLoading : false,
                        onPressed: () {
                          if(widget.paymentModel != null) {
                            if(checkoutController.paymentMethodIndex == 0) {
                              if((((widget.paymentModel?.maxCodOrderAmount != null && widget.paymentModel!.orderAmount! < widget.paymentModel!.maxCodOrderAmount!) || widget.paymentModel!.maxCodOrderAmount == null || widget.paymentModel!.maxCodOrderAmount == 0) && widget.paymentModel!.orderType != 'parcel') || widget.paymentModel!.orderType == 'parcel'){
                                Get.find<CheckoutController>().paymentAfterDigitalCancel(widget.paymentModel!, widget.fromHome);
                              } else {
                                showCustomSnackBar('${'you_cant_order_more_then'.tr} ${PriceConverter.convertPrice(orderController.paymentModel!.maxCodOrderAmount)} ${'in_cash_on_delivery'.tr}', getXSnackBar: true);
                                return;
                              }
                            } else {
                              Get.find<CheckoutController>().paymentAfterDigitalCancel(widget.paymentModel!, widget.fromHome);
                            }
                          } else {
                            Get.back();
                          }
                        },
                      );
                    }
                ),
              ),
            ),

          ]),
        );
      }),
    );
  }

  Widget changeAmountView(CheckoutController checkoutController) {
    return Column(children: [
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: showChangeAmount && checkoutController.paymentMethodIndex == 0
            ? AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: showChangeAmount ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
            ),
            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            margin: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: Dimensions.paddingSizeExtraSmall, children: [

              Text('${'change_amount'.tr}(${Get.find<SplashController>().configModel?.currencySymbol})', style: robotoBold.copyWith(
                color: checkoutController.paymentMethodIndex == 0 ? Theme.of(context).textTheme.bodyLarge!.color : Theme.of(context).disabledColor,
              )),

              Text('specify_the_amount_of_change_the_deliveryman_needs_to_bring_when_delivering_the_order'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              CustomTextField(
                titleText: 'amount'.tr,
                showLabelText: false,
                inputType: TextInputType.number,
                isAmount: true,
                inputAction: TextInputAction.done,
                controller: _amountController,
                isEnabled: checkoutController.paymentMethodIndex == 0 ? true : false,
                onChanged: (String value){
                  checkoutController.setExchangeAmount(double.tryParse(value) ?? 0);
                },
              ),
            ]),
          ),
        )
            : const SizedBox(),
      ),

      if(checkoutController.paymentMethodIndex == 0)
        CustomInkWell(
          onTap: (){
            setState(() {
              showChangeAmount = !showChangeAmount;
            });
          },
          radius: Dimensions.radiusSmall,
          padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Text(showChangeAmount ? 'see_less'.tr : 'see_more'.tr, style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
        ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
    ]);
  }

  // MoonJoin premium payment card (Figma): icon chip + title + description + animated radio.
  Widget paymentButtonView({required String title, String? subtitle, String? image, IconData? iconData, required bool isSelected,
    required Function? onTap, bool disablePayments = false, required EdgeInsetsGeometry padding}) {
    Color primary = Theme.of(context).primaryColor;
    Color titleColor = disablePayments ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyLarge!.color!;
    return Padding(
      padding: padding,
      child: InkWell(
        onTap: onTap as void Function()?,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.06) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: isSelected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.25), width: isSelected ? 1.2 : 1),
            boxShadow: isSelected ? [] : [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(children: [

            Container(
              height: 44, width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? primary.withValues(alpha: 0.12) : Theme.of(context).disabledColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: image != null ? Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: CustomImage(height: 24, width: 24, fit: BoxFit.contain, image: image, color: disablePayments ? Theme.of(context).disabledColor : null),
              ) : Icon(iconData ?? Icons.payments_outlined, size: 22, color: disablePayments ? Theme.of(context).disabledColor : primary),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: titleColor)),
                if(subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                ],
              ]),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.5),
              ),
            ),

          ]),
        ),
      ),
    );
  }

  Widget walletView(CheckoutController checkoutController) {
    double walletBalance = Get.find<ProfileController>().userInfoModel?.walletBalance??0;
    double balance = 0;
    if(walletBalance <= 0 || (widget.paymentModel != null && walletBalance < widget.totalPrice)) {
      return const SizedBox();
    }
    if(walletBalance > widget.totalPrice && checkoutController.paymentMethodIndex == 1) {
      balance = walletBalance - widget.totalPrice;
    }
    bool isWalletSelected = checkoutController.paymentMethodIndex == 1 || checkoutController.isPartialPay;

    return Get.find<SplashController>().configModel!.customerWalletStatus == 1
        && Get.find<ProfileController>().userInfoModel != null && (checkoutController.distance != -1)
        && Get.find<ProfileController>().userInfoModel!.walletBalance! > 0 ? Column(children: [
      // MoonJoin Wallet Balance card (Figma Virtual Account Payment): green card + white "Use Wallet" button.
      Container(
        margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [const Color(0xFF15702F), Theme.of(context).primaryColor],
          ),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 30),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(isWalletSelected ? 'wallet_remaining_balance'.tr : 'wallet_balance'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white.withValues(alpha: 0.92))),
            const SizedBox(height: 4),
            Text(PriceConverter.convertPrice(isWalletSelected ? balance : walletBalance), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge + 3, color: Colors.white)),
          ])),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          // White "Use Wallet" button — existing apply/clear (select/deselect) logic preserved verbatim.
          CustomInkWell(
            onTap: () {
              if(isWalletSelected) {
                checkoutController.setPaymentMethod(-1);
                if(checkoutController.isPartialPay) {
                  checkoutController.changePartialPayment();
                }
              } else {
                if(checkoutController.isPartialPay) {
                  checkoutController.changePartialPayment();
                }
                checkoutController.setPaymentMethod(1);
                if(walletBalance < widget.totalPrice) {
                  checkoutController.changePartialPayment();
                }
                if(showChangeAmount) {
                  setState(() {
                    showChangeAmount = false;
                  });
                }
              }
              configurePartialPayment();
            },
            radius: Dimensions.radiusDefault,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall + 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFDFD),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: const Color(0xFFD9E5DE)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if(isWalletSelected) ...[
                  Icon(Icons.check_circle, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                ],
                Text(isWalletSelected ? 'applied'.tr : 'use_wallet'.tr,
                    style: robotoSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
              ]),
            ),
          ),
        ]),
      ),

      if(isWalletSelected && !checkoutController.isPartialPay)
        Container(
          margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('paid_by_wallet'.tr, style: robotoBold.copyWith(fontSize: 14)),
            Text(PriceConverter.convertPrice(widget.totalPrice), style: robotoMedium.copyWith(fontSize: 18))
          ]),
        ),

      if(isWalletSelected && checkoutController.isPartialPay)
        Column(children: [
          Container(
            margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('paid_by_wallet'.tr, style: robotoMedium.copyWith(fontSize: 14, color: Theme.of(context).disabledColor)),
                Text(PriceConverter.convertPrice(walletBalance), style: robotoMedium.copyWith(fontSize: 14, color: Theme.of(context).disabledColor))
              ]),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('remaining_bill'.tr, style: robotoMedium.copyWith(fontSize: 14)),
                Text(PriceConverter.convertPrice(widget.totalPrice - walletBalance), style: robotoBold.copyWith(fontSize: 18)),
              ])
            ]),
          ),

          if(checkoutController.paymentMethodIndex == 1)
            Text('* ${'please_select_a_option_to_pay_remain_billing_amount'.tr}', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFFE74B4B))),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ]),

      // ── Virtual Account details section (9PSB wallet funding) ──
      // Reuses the single master component (extracted from this card). detailsOnly
      // preserves the approved null-state placeholder behavior on this surface.
      if(_is9PSBActive) ...[
        const SizedBox(height: Dimensions.paddingSizeDefault),
        const VirtualAccountDetailsWidget(detailsOnly: true),
      ],

      const SizedBox(height: Dimensions.paddingSizeDefault),

    ]) : const SizedBox();
  }

}