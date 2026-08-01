import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/features/checkout/widgets/tips_widget.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// THE shared MoonJoin **Delivery Man Tips** component — the single tip UI used by
/// both Checkout and Parcel Request (no duplicate tip UI logic).
///
/// It renders the tip options from the DYNAMIC `AppConstants.tips` (→
/// `DeliveryManTipsConfig`: zone → global `dm_default_tips` → temporary fallback,
/// i.e. MoonJoin backend/admin-owned configuration), keeping the "Not Now" (index 0)
/// and "custom" (last index) bookends, plus the save-for-later toggle and the
/// custom-amount field. Amounts are formatted by `PriceConverter`, which follows the
/// configured currency — no hardcoded currency symbol.
///
/// Pure presentation — it owns NO business logic. Each host screen passes its own
/// controller values and wires the callbacks to its own controller, so tip
/// controllers/validation stay untouched.
class DeliveryManTips extends StatelessWidget {
  /// The host controller's selected tip index (`selectedTips`).
  final int selectedIndex;

  /// Whether the custom-amount field is showing (chip row is hidden then).
  /// Host passes `(selectedTips == last) && canShowTipsField`.
  final bool showCustomField;

  /// Backend "most tapped" suggestion (`mostDmTipAmount`) — badges one chip.
  final int? mostTipAmount;

  /// Host controller's `isDmTipSave`.
  final bool saveForLater;

  /// Host controller's custom-amount text controller.
  final TextEditingController customController;

  /// Tip chip tapped (index into the option list). Host wires its full logic here.
  final void Function(int index) onSelectTip;

  /// Save-for-later toggled.
  final VoidCallback onToggleSave;

  /// Clear (X) pressed on the custom field.
  final VoidCallback onClearCustom;

  /// Optional custom-amount change / submit handlers (host-specific).
  final void Function(String value)? onCustomChanged;
  final void Function(String value)? onCustomSubmit;

  /// Optional tooltip (Checkout provides one; Parcel omits it).
  final JustTheController? tooltipController;

  /// Outer margin (Checkout uses horizontal page padding on mobile).
  final EdgeInsetsGeometry margin;

  const DeliveryManTips({
    super.key,
    required this.selectedIndex,
    required this.showCustomField,
    required this.mostTipAmount,
    required this.saveForLater,
    required this.customController,
    required this.onSelectTip,
    required this.onToggleSave,
    required this.onClearCustom,
    this.onCustomChanged,
    this.onCustomSubmit,
    this.tooltipController,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> options = AppConstants.tips;
    final int customIndex = options.length - 1;
    final bool isCustomSelected = selectedIndex == customIndex;

    return Container(
      margin: margin,
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('delivery_man_tips'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            Text('show_some_love_to_your_rider'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
          ])),
          if (tooltipController != null) JustTheTooltip(
            backgroundColor: Colors.black87,
            controller: tooltipController,
            preferredDirection: AxisDirection.left,
            tailLength: 14, tailBaseWidth: 20,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('it_s_a_great_way_to_show_your_appreciation_for_their_hard_work'.tr, style: robotoRegular.copyWith(color: Colors.white)),
            ),
            child: InkWell(
              onTap: () => tooltipController!.showTooltip(),
              child: Icon(Icons.info_outline, size: 18, color: Theme.of(context).disabledColor),
            ),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        SizedBox(
          height: showCustomField ? 0 : (ResponsiveHelper.isDesktop(context) ? 80 : 66),
          child: showCustomField ? const SizedBox() : ListView.builder(
            scrollDirection: Axis.horizontal, shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (context, index) {
              return TipsWidget(
                title: options[index] == '0' ? 'not_now'.tr : (index != customIndex)
                    ? PriceConverter.convertPrice(double.parse(options[index]), forDM: true)
                    : options[index].tr,
                isSelected: selectedIndex == index,
                isSuggested: index != 0 && options[index] == mostTipAmount.toString(),
                onTap: () => onSelectTip(index),
              );
            },
          ),
        ),
        SizedBox(height: showCustomField ? Dimensions.paddingSizeExtraSmall : 0),

        isCustomSelected ? const SizedBox() : Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: Row(children: [
            Icon(Icons.bookmark_border, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(child: Text('save_for_later'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault))),
            Switch.adaptive(
              value: saveForLater,
              activeThumbColor: Theme.of(context).primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) => onToggleSave(),
            ),
          ]),
        ),
        SizedBox(height: isCustomSelected ? Dimensions.paddingSizeDefault : 0),

        isCustomSelected ? Row(children: [
          Expanded(child: CustomTextField(
            titleText: 'enter_amount'.tr,
            controller: customController,
            inputAction: TextInputAction.done,
            inputType: TextInputType.number,
            onChanged: onCustomChanged,
            onSubmit: onCustomSubmit,
          )),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          InkWell(
            onTap: onClearCustom,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: const Icon(Icons.clear),
            ),
          ),
        ]) : const SizedBox(),
      ]),
    );
  }
}
