import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/transaction_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class HistoryItemWidget extends StatelessWidget {
  final int index;
  final bool fromWallet;
  final List<Transaction>? data;
  /// Presentation-only MoonJoin variant for the Loyalty history (Phase 5, FROZEN).
  final bool moonjoinLoyalty;
  /// Presentation-only MoonJoin variant for the Wallet history (Phase 7). When
  /// true the wallet row renders in the MoonJoin language. Default false keeps the
  /// legacy row (default / Final Legacy Cleanup). The Loyalty variant stays frozen.
  final bool moonjoinWallet;
  const HistoryItemWidget({super.key, required this.index, required this.fromWallet, required this.data, this.moonjoinLoyalty = false, this.moonjoinWallet = false});

  @override
  Widget build(BuildContext context) {
    if(moonjoinLoyalty) {
      return _moonjoinLoyaltyRow(context);
    }
    if(moonjoinWallet) {
      return _moonjoinWalletRow(context);
    }
    return Column(children: [
      Row(
        children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              fromWallet ? Row(children: [
            
                data![index].transactionType == 'order_place' || data![index].transactionType == 'partial_payment'
                    ? Image.asset(Images.walletDebitIcon, height: 15, width: 15)
                    : Image.asset(Images.walletCreditIcon, height: 15, width: 15),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            
                Text(data![index].transactionType == 'order_place' || data![index].transactionType == 'partial_payment'
                    ? '- ${PriceConverter.convertPrice(data![index].debit! + data![index].adminBonus!)}'
                    : '+ ${PriceConverter.convertPrice(data![index].credit! + data![index].adminBonus!)}',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                ),
              ]) : Row(children: [
            
                data![index].transactionType == 'point_to_wallet'? Image.asset(Images.debitIcon, height: 13, width: 13) : Image.asset(Images.creditIcon, height: 13, width: 13),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            
                Text(data![index].transactionType == 'point_to_wallet'? '-${data![index].debit!.toStringAsFixed(0)}'
                    : '+${data![index].credit!.toStringAsFixed(0)}',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            
                Text('points'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,color: Theme.of(context).disabledColor),
                )]),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            
              Text(
                data![index].transactionType == 'add_fund' ? '${'added_via'.tr} ${data![index].reference!.replaceAll('_', ' ')} ${data![index].adminBonus != 0 ? '(${'bonus'.tr} = ${data![index].adminBonus})' : '' }'
                    : data![index].transactionType == 'partial_payment' ? '${'spend_on_order'.tr} # ${data![index].reference}'
                    : data![index].transactionType == 'loyalty_point' ? 'converted_from_loyalty_point'.tr
                    : data![index].transactionType == 'referrer' ? 'earned_by_referral'.tr
                    : data![index].transactionType == 'order_place' ? '${'order_place'.tr} # ${data![index].reference}'
                    : data![index].transactionType!.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall,color: Theme.of(context).hintColor),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              DateConverter.dateToDateAndTimeAm(data![index].createdAt!),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall,color: Theme.of(context).hintColor),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            Text(
              fromWallet ? data![index].transactionType == 'order_place' || data![index].transactionType == 'partial_payment' ? 'debit'.tr : 'credit'.tr : data![index].transactionType == 'point_to_wallet' ? 'debit'.tr : 'credit'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: fromWallet ? data![index].transactionType == 'order_place' || data![index].transactionType == 'partial_payment'
                  ? Colors.red : Colors.green : data![index].transactionType == 'point_to_wallet' ? Colors.red : Colors.green),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ]),

        ]),

      index == data!.length-1 ? const SizedBox() : Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
        child: Divider(color: Theme.of(context).disabledColor),
      ),

    ]);
  }

  // ── MoonJoin Loyalty history row (isolated variant) — same data/logic,
  // green icon chip · points amount · description · date · credit/debit pill. ──
  Widget _moonjoinLoyaltyRow(BuildContext context) {
    final bool isDebit = data![index].transactionType == 'point_to_wallet';
    final Color amountColor = isDebit ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Row(children: [

          Container(
            height: 42, width: 42, alignment: Alignment.center,
            decoration: BoxDecoration(color: amountColor.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: amountColor, size: 20),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                isDebit ? '-${data![index].debit!.toStringAsFixed(0)}' : '+${data![index].credit!.toStringAsFixed(0)}',
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: amountColor),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text('points'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
            ]),
            const SizedBox(height: 2),
            Text(
              data![index].transactionType == 'loyalty_point' ? 'converted_from_loyalty_point'.tr
                  : data![index].transactionType == 'referrer' ? 'earned_by_referral'.tr
                  : data![index].transactionType == 'order_place' ? '${'order_place'.tr} # ${data![index].reference}'
                  : data![index].transactionType!.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ])),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              DateConverter.dateToDateAndTimeAm(data![index].createdAt!),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
              decoration: BoxDecoration(color: amountColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              child: Text(
                isDebit ? 'debit'.tr : 'credit'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: amountColor),
              ),
            ),
          ]),

        ]),
      ),

      index == data!.length-1 ? const SizedBox() : Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
    ]);
  }

  // ── MoonJoin Wallet history row (isolated variant, Phase 7) — same data/logic
  // as the legacy wallet row (debit/credit + adminBonus, currency formatting). ──
  Widget _moonjoinWalletRow(BuildContext context) {
    final bool isDebit = data![index].transactionType == 'order_place' || data![index].transactionType == 'partial_payment';
    final Color amountColor = isDebit ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Row(children: [

          Container(
            height: 42, width: 42, alignment: Alignment.center,
            decoration: BoxDecoration(color: amountColor.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: Icon(isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: amountColor, size: 20),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isDebit
                  ? '- ${PriceConverter.convertPrice(data![index].debit! + data![index].adminBonus!)}'
                  : '+ ${PriceConverter.convertPrice(data![index].credit! + data![index].adminBonus!)}',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: amountColor),
              maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 2),
            Text(
              data![index].transactionType == 'add_fund' ? '${'added_via'.tr} ${data![index].reference!.replaceAll('_', ' ')} ${data![index].adminBonus != 0 ? '(${'bonus'.tr} = ${data![index].adminBonus})' : '' }'
                  : data![index].transactionType == 'partial_payment' ? '${'spend_on_order'.tr} # ${data![index].reference}'
                  : data![index].transactionType == 'loyalty_point' ? 'converted_from_loyalty_point'.tr
                  : data![index].transactionType == 'referrer' ? 'earned_by_referral'.tr
                  : data![index].transactionType == 'order_place' ? '${'order_place'.tr} # ${data![index].reference}'
                  : data![index].transactionType!.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
          ])),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              DateConverter.dateToDateAndTimeAm(data![index].createdAt!),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
              decoration: BoxDecoration(color: amountColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              child: Text(
                isDebit ? 'debit'.tr : 'credit'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: amountColor),
              ),
            ),
          ]),

        ]),
      ),

      index == data!.length-1 ? const SizedBox() : Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
    ]);
  }
}
