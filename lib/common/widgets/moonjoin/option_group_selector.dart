import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/moonjoin/status_badge.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A single option row inside an [OptionGroupSelector] (label + optional
/// trailing price string).
class OptionItem {
  final String label;
  final String? trailing;
  const OptionItem(this.label, {this.trailing});
}

/// Food product-details option group: a titled card containing radio-cards
/// (single choice) or checkbox-cards (multi choice) with a Required/Optional
/// tag — matching `product_details_for_only_food`. Pure presentation: the
/// parent owns [selectedIndexes] and reacts via [onChanged].
class OptionGroupSelector extends StatelessWidget {
  final String title;
  final List<OptionItem> options;
  final Set<int> selectedIndexes;
  final bool multiSelect;
  final bool required;
  final ValueChanged<Set<int>>? onChanged;

  const OptionGroupSelector({
    super.key,
    required this.title,
    required this.options,
    this.selectedIndexes = const {},
    this.multiSelect = false,
    this.required = false,
    this.onChanged,
  });

  void _toggle(int index) {
    final Set<int> next = Set<int>.from(selectedIndexes);
    if (multiSelect) {
      next.contains(index) ? next.remove(index) : next.add(index);
    } else {
      next
        ..clear()
        ..add(index);
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          StatusBadge(
            text: required ? 'Required' : 'Optional',
            color: required ? Theme.of(context).colorScheme.error : Theme.of(context).disabledColor,
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Wrap(
          spacing: Dimensions.paddingSizeSmall,
          runSpacing: Dimensions.paddingSizeSmall,
          children: List.generate(options.length, (i) => _optionCard(context, i)),
        ),
      ]),
    );
  }

  Widget _optionCard(BuildContext context, int index) {
    final bool selected = selectedIndexes.contains(index);
    final Color primary = Theme.of(context).primaryColor;
    final OptionItem option = options[index];
    return InkWell(
      onTap: () => _toggle(index),
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: (MediaQuery.of(context).size.width - (Dimensions.paddingSizeDefault * 4) - Dimensions.paddingSizeSmall) / 2,
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.08) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: selected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          _control(context, selected),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(option.label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: selected ? primary : null)),
              if (option.trailing != null) ...[
                const SizedBox(height: 2),
                Text(option.trailing!, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: primary)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _control(BuildContext context, bool selected) {
    final Color primary = Theme.of(context).primaryColor;
    if (multiSelect) {
      return Container(
        height: 20, width: 20,
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(color: selected ? primary : Theme.of(context).disabledColor),
        ),
        child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
      );
    }
    return Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: selected ? primary : Theme.of(context).disabledColor);
  }
}
