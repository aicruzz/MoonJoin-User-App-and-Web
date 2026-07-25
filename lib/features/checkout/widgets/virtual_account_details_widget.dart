// virtual_account_details_widget.dart
//
// THE single, master "Your Virtual Account Details" component.
//
// This is the EXACT approved card from the Choose Payment Method sheet
// (`payment_method_bottom_sheet.dart` → `_virtualAccountFundSection`), extracted
// verbatim so there is ONE visual implementation reused everywhere: Checkout,
// Profile, Wallet "+", and any future Deposit/Funding screen. Zero visual drift.
//
// It is self-contained (reads `ProfileController.virtualAccountData` /
// `isGeneratingAccount`, reuses the existing `generateVirtualAccount()`), and
// supports every state — details · loading · generate/no-account — WITHOUT
// changing the approved details layout.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class VirtualAccountDetailsWidget extends StatelessWidget {
  /// When true, the null-account state shows the approved placeholder text
  /// (Checkout / Wallet "+" — funding-only surfaces, no generate affordance).
  /// When false (default → Profile) the null state offers "Generate".
  final bool detailsOnly;

  /// When false the "Your Virtual Account Details" title is hidden (host screen
  /// already provides a header). Default true — as the approved card renders it.
  final bool showTitle;

  /// When false the "Important Instructions" box is hidden (e.g. Profile, where the
  /// general details below should be immediately visible). Default true — Checkout
  /// and Wallet keep the approved instructions.
  final bool showInstructions;

  final EdgeInsetsGeometry? margin;

  const VirtualAccountDetailsWidget({
    super.key,
    this.detailsOnly = false,
    this.showTitle = true,
    this.showInstructions = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final Map<String, dynamic>? data = profileController.virtualAccountData;
      final bool isLoading = profileController.isGeneratingAccount;

      return Container(
        margin: margin,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          if(showTitle) ...[
            Text('your_virtual_account_details'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],

          if(data != null) ...[
            _detailsCard(context, data),
            if(showInstructions) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _instructions(context),
            ],
          ] else if(isLoading) ...[
            _loadingShell(context),
          ] else if(detailsOnly) ...[
            Text(
              'transfer_to_virtual_account_to_top_up_wallet'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
            ),
          ] else ...[
            _generateButton(context, profileController),
          ],
        ]),
      );
    });
  }

  // ── Approved premium details card (verbatim from the Choose Payment sheet) ──
  Widget _detailsCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Bank Name (with logo chip)  |  Account Number (with copy)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              height: 46, width: 46, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Icon(Icons.account_balance_rounded, size: 24, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: _infoRow(context, label: 'bank_name'.tr, value: data['bank_name']?.toString() ?? 'N/A')),
          ])),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _infoRow(
              context,
              label: 'account_number'.tr,
              value: data['account_number']?.toString() ?? 'N/A',
            )),
            if(data['account_number'] != null) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              _CopyButton(accountNumber: data['account_number'].toString()),
            ],
          ])),
        ]),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        ),

        _infoRow(context, label: 'account_name'.tr, value: data['account_name']?.toString() ?? 'N/A'),
      ]),
    );
  }

  // Generate affordance — same premium shell as the details card, tappable.
  Widget _generateButton(BuildContext context, ProfileController profileController) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => profileController.generateVirtualAccount(),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.30)),
            boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text('generate_virtual_account'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
          ]),
        ),
      ),
    );
  }

  // Loading — same premium shell, centered spinner.
  Widget _loadingShell(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: const Center(child: CircularProgressIndicator()),
    );
  }


  Widget _infoRow(BuildContext context, {required String label, required String value}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
      const SizedBox(height: 6),
      // scaleDown so values (e.g. the full account number) never truncate in narrow
      // contexts like the Add Fund dialog; full-width contexts render unchanged.
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, maxLines: 1,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, letterSpacing: 0.3, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
    ]);
  }

  Widget _instructions(BuildContext context) {
    final steps = [
      'Copy the account number above.',
      'Open your bank app or USSD and transfer any amount to the account.',
      'Your wallet will be topped up automatically once the transfer is confirmed.',
      'Return here and tap "Apply" to use your wallet balance at checkout.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              height: 22, width: 22, alignment: Alignment.center,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
              child: Icon(Icons.info_outline_rounded, size: 13, color: Theme.of(context).cardColor),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              'important_instructions'.tr,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ...List.generate(steps.length, (i) => Column(children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20, width: 20,
                  margin: const EdgeInsets.only(top: 1, right: Dimensions.paddingSizeSmall),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: robotoBold.copyWith(fontSize: 10, color: Theme.of(context).primaryColor),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      steps[i],
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color),
                    ),
                  ),
                ),
              ],
            ),
            if(i != steps.length - 1) Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Divider(height: 1, color: Theme.of(context).primaryColor.withValues(alpha: 0.10)),
            ),
          ])),
        ],
      ),
    );
  }
}

/// Premium copy-to-clipboard button for the account number. Copies exactly as
/// before (clipboard content unchanged); replaces the intrusive top snackbar with
/// a subtle inline "Copied" indicator that fades in and out beside the icon.
class _CopyButton extends StatefulWidget {
  final String accountNumber;
  const _CopyButton({required this.accountNumber});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  Timer? _timer;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.accountNumber));
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if(mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Material(
      color: green.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _copy,
        splashColor: green.withValues(alpha: 0.20),
        highlightColor: green.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 0),
          child: SizedBox(
            height: 44,
            child: Center(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: _copied
                  ? Row(key: const ValueKey('copied'), mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_rounded, size: 16, color: green),
                      const SizedBox(width: 4),
                      Text('copied'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: green)),
                    ])
                  : Icon(Icons.copy_rounded, key: const ValueKey('copy'), size: 20, color: green),
            )),
          ),
        ),
      ),
    );
  }
}
