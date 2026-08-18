import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';

class VirtualAccountBottomSheet extends StatelessWidget {
  const VirtualAccountBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final data = profileController.virtualAccountData;
      final bool isLoading = profileController.isGeneratingAccount;

      return Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Title
            Text(
              'virtual_account_details'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              )
            else if (data != null) ...[
              // Account info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bank Name
                    _buildInfoRow(
                      context,
                      label: 'bank_name'.tr,
                      value: data['bank_name']?.toString() ?? '9PSB',
                    ),
                    const Divider(height: 24),

                    // Account Name
                    _buildInfoRow(
                      context,
                      label: 'account_name'.tr,
                      value: data['account_name']?.toString() ?? 'N/A',
                    ),
                    const Divider(height: 24),

                    // Account Number with copy button
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            context,
                            label: 'account_number'.tr,
                            value: data['account_number']?.toString() ?? 'N/A',
                          ),
                        ),
                        if (data['account_number'] != null)
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                text: data['account_number'].toString(),
                              ));
                              showCustomSnackBar('account_number_copied'.tr, isError: false);
                            },
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            tooltip: 'copy'.tr,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Info note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Text(
                        'use_this_account_for_transfers'.tr,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'no_virtual_account_data'.tr,
                  style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
                ),
              ),

            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                ),
                child: Text(
                  'close'.tr,
                  style: robotoBold.copyWith(color: Theme.of(context).cardColor),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(BuildContext context, {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
        ),
      ],
    );
  }
}
