// virtual_account_details_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class VirtualAccountDetailsWidget extends StatelessWidget {
  const VirtualAccountDetailsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final virtualAccountData = Get.find<ProfileController>().virtualAccountData;

    if (virtualAccountData == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, 
                color: Theme.of(context).primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'virtual_account_details'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          _AccountRow(
            label: 'bank_name'.tr,
            value: virtualAccountData['bank_name'] ?? '9PSB',
          ),
          const SizedBox(height: 10),

          _AccountRow(
            label: 'account_name'.tr,
            value: virtualAccountData['account_name'] ?? '',
          ),
          const SizedBox(height: 10),

          _AccountRow(
            label: 'account_number'.tr,
            value: virtualAccountData['account_number'] ?? '',
            canCopy: true,
          ),

          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'transfer_to_account_and_confirm'.tr,
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _AccountRow({
    required this.label,
    required this.value,
    this.canCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).hintColor,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  showCustomSnackBar(
                    'account_number_copied'.tr,
                    isError: false,
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}