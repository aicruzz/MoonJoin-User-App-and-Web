import 'package:flutter/material.dart';
import 'package:sixam_mart/features/checkout/widgets/virtual_account_details_widget.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/wallet/controllers/wallet_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';

class AddFundDialogueWidget extends StatefulWidget {
  final ScrollController cardScrollController;
  const AddFundDialogueWidget({super.key, required this.cardScrollController});

  @override
  State<AddFundDialogueWidget> createState() => _AddFundDialogueWidgetState();
}

class _AddFundDialogueWidgetState extends State<AddFundDialogueWidget> {
  final TextEditingController inputAmountController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        widget.cardScrollController.jumpTo(50);
      }
    });

    Get.find<WalletController>().isTextFieldEmpty('', isUpdate: false);
    Get.find<WalletController>().changeDigitalPaymentName('', isUpdate: false);

    if(Get.find<SplashController>().configModel!.activePaymentMethodList!.length == 1){
      Get.find<WalletController>().changeDigitalPaymentName(Get.find<SplashController>().configModel!.activePaymentMethodList!.first.getWay!, isUpdate: false);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [

      Align(
        alignment: Alignment.topRight,
        child: InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.clear, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      GetBuilder<WalletController>(builder: (walletController) {
        final bool is9PSBSelected = walletController.digitalPaymentName?.toLowerCase() == '9psb';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
          ),
          width: context.width * 0.9,
          constraints: BoxConstraints(minHeight: context.height * 0.34, maxHeight: context.height * 0.7),
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            const SizedBox(height: Dimensions.paddingSizeSmall),

            Container(
              height: 56, width: 56, alignment: Alignment.center,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(Icons.account_balance_wallet_rounded, color: Theme.of(context).primaryColor, size: 28),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text('add_fund_to_wallet'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Text('add_fund_form_secured_digital_payment_gateways'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Hide amount field when 9PSB is selected
            if(!is9PSBSelected) ...[
              CustomTextField(
                hintText: 'enter_amount'.tr,
                titleText: 'enter_amount'.tr,
                showLabelText: false,
                inputType: TextInputType.number,
                focusNode: focusNode,
                inputAction: TextInputAction.done,
                controller: inputAmountController,
                textAlign: TextAlign.center,
                isAmount: true,
                onChanged: (String value){
                  _checkFormatters(value);
                  try{
                    if(double.parse(value) > 0){
                      walletController.isTextFieldEmpty(value);
                    }
                  }catch(e) {
                    walletController.isTextFieldEmpty('');
                  }
                },
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],

            Flexible(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: 'choose_payment_method'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color)),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'faster_and_secure_way_to_pay_bill'.tr,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                  ),
                ]),
              ),
            ),

            Flexible(
              child: Scrollbar(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [

                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    ListView.builder(
                      itemCount: Get.find<SplashController>().configModel!.activePaymentMethodList!.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final paymentMethod = Get.find<SplashController>().configModel!.activePaymentMethodList![index];
                        final bool is9PSB = paymentMethod.getWay?.toLowerCase() == '9psb';
                        bool isSelected = paymentMethod.getWay! == walletController.digitalPaymentName;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                walletController.changeDigitalPaymentName(paymentMethod.getWay!);
                              },
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.25),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
                                child: Row(children: [
                                  Container(
                                    height: 22, width: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                      border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, width: 1.5),
                                    ),
                                    child: isSelected ? Icon(Icons.check, color: Theme.of(context).cardColor, size: 15) : const SizedBox(),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeDefault),

                                  CustomImage(
                                    height: 22, fit: BoxFit.contain,
                                    image: '${paymentMethod.getWayImageFullUrl}',
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),

                                  Expanded(child: Text(
                                    // Label 9PSB as "9PSB Virtual Account" so users
                                    // understand funding is by bank transfer.
                                    is9PSB ? '9PSB ${'virtual_account'.tr}' : paymentMethod.getWayTitle!,
                                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )),
                                ]),
                              ),
                            ),

                            // Wallet "+" 9PSB → the SHARED Your Virtual Account
                            // Details component (same as Profile & Checkout). One
                            // widget, zero duplication.
                            if(is9PSB && isSelected) ...[
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              const VirtualAccountDetailsWidget(detailsOnly: true, margin: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall)),
                            ],

                          ],
                        );
                      },
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                  ]),
                ),
              ),
            ),

            // Hide add fund button when 9PSB is selected
            if(!is9PSBSelected)
              CustomButton(
                buttonText: 'add_fund'.tr,
                isLoading: walletController.isLoading,
                onPressed: () => _onAddFundButtonClicked(walletController),
              ),

          ]),
        );
      }),
    ]);
  }

  void _checkFormatters(String value) {
    String test = value;
    if(value.contains('-')) {
      test = value.replaceAll('-', '');
    } else if(value.contains(' ')) {
      test = value.replaceAll(' ', '');
    } else if(value.contains(',')) {
      test = value.replaceAll(',', '');
    } else {
      test = value;
    }
    setState(() {
      inputAmountController.text = test;
      inputAmountController.selection = TextSelection.fromPosition(
        TextPosition(offset: test.length),
      );
    });
  }

  void _onAddFundButtonClicked(WalletController walletController) {
    if(inputAmountController.text.isEmpty){
      showCustomSnackBar('please_provide_transfer_amount'.tr);
    }else if(inputAmountController.text == '0'){
      showCustomSnackBar('you_can_not_add_zero_amount_in_wallet'.tr);
    }else if(walletController.digitalPaymentName == ''){
      showCustomSnackBar('please_select_payment_method'.tr);
    }else{
      double amount = double.parse(inputAmountController.text.replaceAll(Get.find<SplashController>().configModel!.currencySymbol!, ''));
      walletController.addFundToWallet(amount, walletController.digitalPaymentName!);
    }
  }

}