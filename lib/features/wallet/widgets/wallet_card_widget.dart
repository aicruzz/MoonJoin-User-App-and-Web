import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/helper/price_converter.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/features/wallet/widgets/add_fund_dialogue_widget.dart';

class WalletCardWidget extends StatelessWidget {
  final JustTheController tooltipController;
  const WalletCardWidget({super.key, required this.tooltipController});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    final ScrollController cardScrollController = ScrollController();

    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isDesktop ? const SizedBox() : const SizedBox(height: Dimensions.paddingSizeSmall),

            // MoonJoin premium fintech balance card (foundation for future Wallet
            // products: multi-currency, virtual accounts, cards, analytics…).
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 28 : Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.85)],
                ),
                boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Theme.of(context).cardColor.withValues(alpha: 0.9), size: 18),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text('wallet_amount'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor.withValues(alpha: 0.9))),
                  ]),

                  Get.find<SplashController>().configModel!.addFundStatus! && Get.find<SplashController>().configModel!.digitalPayment! ? JustTheTooltip(
                    backgroundColor: Colors.black87,
                    controller: tooltipController,
                    preferredDirection: AxisDirection.down,
                    tailLength: 14,
                    tailBaseWidth: 20,
                    content: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'if_you_want_to_add_fund_to_your_wallet_then_click_add_fund_button'.tr,
                        style: robotoRegular.copyWith(color: Colors.white),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => tooltipController.showTooltip(),
                      child: Icon(Icons.info_outline, color: Theme.of(context).cardColor.withValues(alpha: 0.9), size: 20),
                    ),
                  ) : const SizedBox(),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text(
                  PriceConverter.convertPrice(profileController.userInfoModel!.walletBalance), textDirection: TextDirection.ltr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: Theme.of(context).cardColor),
                ),

                Get.find<SplashController>().configModel!.addFundStatus! && Get.find<SplashController>().configModel!.digitalPayment! ? Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                  child: InkWell(
                    onTap: () {
                      Get.dialog(
                        Dialog(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, child: SizedBox(
                          width: 500, child: SingleChildScrollView(controller: cardScrollController, child: AddFundDialogueWidget(cardScrollController: cardScrollController)),
                        )),
                      );
                    },
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Container(
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add_rounded, color: Theme.of(context).primaryColor, size: 18),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text('add_fund'.tr, style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
                      ]),
                    ),
                  ),
                ) : const SizedBox(),

              ]),
            ),
            isDesktop ? const SizedBox() : const SizedBox(height: Dimensions.paddingSizeSmall),
            isDesktop ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            isDesktop ? Text('how_to_use'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)) : const SizedBox(),
            isDesktop ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            !isDesktop ? const SizedBox() : const WalletStepper(),
          ],
        );
      }
    );
  }
}

class WalletStepper extends StatelessWidget {
  const WalletStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                ),
              ),

              Expanded(
                child: VerticalDivider(
                  thickness: 3,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.30),
                ),
              ),

              Container(
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                ),
              ),

              Expanded(
                child: VerticalDivider(
                  thickness: 3,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.30),
                ),
              ),

              Container(
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                ),
              ),

              Expanded(
                child: VerticalDivider(
                  thickness: 3,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.30),
                ),
              ),

              Container(
                height: 15,
                width: 15,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                ),
              ),
            ],
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('earn_money_to_your_wallet_by_completing_the_offer_challenged'.tr, style: robotoRegular),
                Text('convert_your_loyalty_points_into_wallet_money'.tr, style: robotoRegular),
                Text('amin_also_reward_their_top_customers_with_wallet_money'.tr, style: robotoRegular),
                Text('send_your_wallet_money_while_order'.tr, style: robotoRegular),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

