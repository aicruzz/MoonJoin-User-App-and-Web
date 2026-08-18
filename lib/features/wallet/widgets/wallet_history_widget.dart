import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:moonjoin/features/wallet/controllers/wallet_controller.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/no_data_screen.dart';
import '../../../common/widgets/history_item_widget.dart';

class WalletHistoryWidget extends StatelessWidget {
  const WalletHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      builder: (walletController) {
        List<PopupMenuEntry> entryList = [];
        String filterName = '';

        for(int i=0; i < walletController.walletFilterList.length; i++){
          entryList.add(PopupMenuItem<int>(value: i, child: Text(
            walletController.walletFilterList[i].title!.tr,
            style: robotoMedium.copyWith(
              color: walletController.walletFilterList[i].value == walletController.type
                  ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).disabledColor,
            ),
          )));
          if(walletController.walletFilterList[i].value == walletController.type) {
            filterName = walletController.walletFilterList[i].title!.tr;
          } else if(walletController.type == 'all') {
            filterName = '';
          }
        }

        return Column(children: [
          Padding(
            padding: EdgeInsets.only(top: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeExtraLarge),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'wallet_history'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                ),
                if(filterName.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    filterName,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                  ),
                ],
              ]),

              PopupMenuButton<dynamic>(
                offset: const Offset(-20, 40),
                itemBuilder: (BuildContext context) => entryList,
                onSelected: (dynamic value) {
                  walletController.setWalletFilerType(walletController.walletFilterList[value].value!);
                  walletController.getWalletTransactionList('1', false, walletController.type);
                },
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.tune_rounded, size: 16, color: Theme.of(context).primaryColor),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      'filter'.tr,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                    ),
                    Icon(Icons.arrow_drop_down, size: 18, color: Theme.of(context).primaryColor),
                  ]),
                ),
              ),

            ]),
          ),
          walletController.transactionList != null ? walletController.transactionList!.isNotEmpty ? GridView.builder(
            key: UniqueKey(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisSpacing: 50,
              mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeSmall : 0.01,
              childAspectRatio: ResponsiveHelper.isDesktop(context) ? 7 : 4.45,
              crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 1,
            ),
            physics:  const NeverScrollableScrollPhysics(),
            shrinkWrap:  true,
            itemCount: walletController.transactionList!.length,
            padding: EdgeInsets.only(top: ResponsiveHelper.isDesktop(context) ? 28 : 25),
            itemBuilder: (context, index) {
              return HistoryItemWidget(index: index, fromWallet: true, data: walletController.transactionList, moonjoinWallet: true);
            },
          ) : NoDataScreen(text: 'no_data_found'.tr) : WalletShimmer(walletController: walletController),

          walletController.isLoading ? const Center(child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: CircularProgressIndicator(),
          )) : const SizedBox(),


        ]);
      }
    );
  }
}


class WalletShimmer extends StatelessWidget {
  final WalletController walletController;
  const WalletShimmer({super.key, required this.walletController});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: UniqueKey(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 50,
        mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0.01,
        childAspectRatio: ResponsiveHelper.isDesktop(context) ? 5 : 3.8,
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 1,
      ),
      physics:  const NeverScrollableScrollPhysics(),
      shrinkWrap:  true,
      itemCount: 10,
      padding: EdgeInsets.only(top: ResponsiveHelper.isDesktop(context) ? 28 : 25),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: walletController.transactionList == null,
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(height: 10, width: 50, decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 10),
                    Container(height: 10, width: 70, decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(2))),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(height: 10, width: 50, decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 10),
                    Container(height: 10, width: 70, decoration: BoxDecoration(color: Theme.of(context).shadowColor, borderRadius: BorderRadius.circular(2))),
                  ]),
                ],
              ),
              Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge), child: Divider(color: Theme.of(context).disabledColor)),
            ],
            ),
          ),
        );
      },
    );
  }
}