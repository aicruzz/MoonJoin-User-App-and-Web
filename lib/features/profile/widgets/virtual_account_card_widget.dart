// ⚠️ OBSOLETE — DO NOT USE. Superseded by the single master component
// `VirtualAccountDetailsWidget` (lib/features/checkout/widgets/virtual_account_details_widget.dart),
// which is the exact approved "Your Virtual Account Details" card reused across
// Checkout, Profile and Wallet. This file has zero call sites and is retained only
// for the final dead-code cleanup pass (no-auto-delete policy).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';

class VirtualAccountCardWidget extends StatelessWidget {
  final ProfileController profileController;
  final bool isDesktop;
  const VirtualAccountCardWidget({super.key, required this.profileController, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = profileController.virtualAccountData;
    final bool isLoading = profileController.isGeneratingAccount;

    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (data == null) {
      return InkWell(
        onTap: () => profileController.generateVirtualAccount(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text('generate_virtual_account'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
          ]),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          Icon(Icons.account_balance_wallet_outlined, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text('Virtual Account Details'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
        ]),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        _infoRow(context, label: 'bank_name'.tr, value: data['bank_name']?.toString() ?? '9PSB'),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _infoRow(context, label: 'virtual_account_name'.tr, value: data['account_name']?.toString() ?? 'N/A'),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Row(children: [
          Expanded(child: _infoRow(context, label: 'virtual_account_number'.tr, value: data['account_number']?.toString() ?? 'N/A')),
          if (data['account_number'] != null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: data['account_number'].toString()));
                showCustomSnackBar('virtual_account_number_copied'.tr, isError: false);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).primaryColor),
              ),
            ),
        ]),

      ]),
    );
  }

  Widget _infoRow(BuildContext context, {required String label, required String value}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
      const SizedBox(height: 2),
      Text(value, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
    ]);
  }
}
