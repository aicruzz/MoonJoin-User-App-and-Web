import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/checkout/widgets/tips_widget.dart';

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
        return Column(
          children: [
            (!widget.takeAway && Get.find<SplashController>().configModel!.dmTipsStatus == 1) ? Container(
              // MoonJoin "Delivery Man Tips" card (Figma).
              margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(children: [
                  Icon(Icons.volunteer_activism, color: Theme.of(context).primaryColor, size: 26),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text('delivery_man_tips'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      Text('show_some_love_to_your_rider'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                    ]),
                  ),

                  JustTheTooltip(
                    backgroundColor: Colors.black87,
                    controller: widget.tooltipController3,
                    preferredDirection: AxisDirection.left,
                    tailLength: 14,
                    tailBaseWidth: 20,
                    content: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('it_s_a_great_way_to_show_your_appreciation_for_their_hard_work'.tr,style: robotoRegular.copyWith(color: Colors.white)),
                    ),
                    child: InkWell(
                      onTap: () => widget.tooltipController3.showTooltip(),
                      child: Icon(Icons.info_outline, size: 18, color: Theme.of(context).disabledColor),
                    ),
                  ),

                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                SizedBox(
                  height: (checkoutController.selectedTips == AppConstants.tips.length-1) && checkoutController.canShowTipsField
                      ? 0 : ResponsiveHelper.isDesktop(context) ? 80 : 66,
                  child: (checkoutController.selectedTips == AppConstants.tips.length-1) && checkoutController.canShowTipsField
                  ? const SizedBox() : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: AppConstants.tips.length,
                    itemBuilder: (context, index) {
                      return TipsWidget(
                        title: AppConstants.tips[index] == '0' ? 'not_now'.tr : (index != AppConstants.tips.length -1) ? PriceConverter.convertPrice(double.parse(AppConstants.tips[index].toString()), forDM: true) : AppConstants.tips[index].tr,
                        isSelected: checkoutController.selectedTips == index,
                        isSuggested: index != 0 && AppConstants.tips[index] == checkoutController.mostDmTipAmount.toString(),
                        onTap: () async {
                          total = total - checkoutController.tips;
                          checkoutController.updateTips(index);
                          if(checkoutController.selectedTips != AppConstants.tips.length-1) {
                            checkoutController.addTips(double.parse(AppConstants.tips[index]));
                          }
                          if(checkoutController.selectedTips == AppConstants.tips.length-1) {
                            checkoutController.showTipsField();
                          }
                          checkoutController.tipController.text = checkoutController.tips.toString();

                          if(checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1) {

                            checkoutController.checkBalanceStatus((total + checkoutController.tips), 0);
                          }

                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: (checkoutController.selectedTips == AppConstants.tips.length-1) && checkoutController.canShowTipsField ? Dimensions.paddingSizeExtraSmall : 0),

                checkoutController.selectedTips == AppConstants.tips.length-1 ? const SizedBox() : Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                  child: Row(children: [
                    Icon(Icons.bookmark_border, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(child: Text('save_for_later'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault))),
                    Switch.adaptive(
                      value: checkoutController.isDmTipSave,
                      activeThumbColor: Theme.of(context).primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (bool isChecked) => checkoutController.toggleDmTipSave(),
                    ),
                  ]),
                ),
                SizedBox(height: checkoutController.selectedTips == AppConstants.tips.length-1 ? Dimensions.paddingSizeDefault : 0),

                checkoutController.selectedTips == AppConstants.tips.length-1 ? Row(children: [
                  Expanded(
                    child: CustomTextField(
                      titleText: 'enter_amount'.tr,
                      controller: checkoutController.tipController,
                      inputAction: TextInputAction.done,
                      inputType: TextInputType.number,
                      onChanged: (String value) async {
                        if(value.isNotEmpty) {
                          try {
                            if(double.parse(value) >= 0){
                              if(AuthHelper.isLoggedIn()) {
                                total = total - checkoutController.tips;
                                await checkoutController.addTips(double.parse(value));
                                total = total + checkoutController.tips;
                                widget.onTotalChange(total);
                                if(Get.find<ProfileController>().userInfoModel!.walletBalance! < total && checkoutController.paymentMethodIndex == 1){
                                  checkoutController.checkBalanceStatus(total, 0);
                                  canCheckSmall = true;
                                } else if(Get.find<ProfileController>().userInfoModel!.walletBalance! > total && canCheckSmall && checkoutController.isPartialPay){
                                  checkoutController.checkBalanceStatus(total, 0);
                                }
                              } else {
                                checkoutController.addTips(double.parse(value));
                              }

                            }else{
                              showCustomSnackBar('tips_can_not_be_negative'.tr);
                            }
                          }catch(e) {
                            showCustomSnackBar('invalid_input'.tr);
                            checkoutController.addTips(0.0);
                            checkoutController.tipController.text = checkoutController.tipController.text.substring(0, checkoutController.tipController.text.length-1);
                            checkoutController.tipController.selection = TextSelection.collapsed(offset: checkoutController.tipController.text.length);
                          }
                        }else {
                          checkoutController.addTips(0.0);
                        }
                      },

                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  InkWell(
                    onTap: () {
                      checkoutController.updateTips(0);
                      checkoutController.showTipsField();
                      if(checkoutController.isPartialPay) {
                        checkoutController.changePartialPayment();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: const Icon(Icons.clear),
                    ),
                  ),

                ]) : const SizedBox(),

              ]),
            ) : const SizedBox.shrink(),

            SizedBox(height: (!widget.takeAway && widget.storeId == null && Get.find<SplashController>().configModel!.dmTipsStatus == 1)
                ? Dimensions.paddingSizeSmall : 0),
          ],
        );
      }
    );
  }
}
