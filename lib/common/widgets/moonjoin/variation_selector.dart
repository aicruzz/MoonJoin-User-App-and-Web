import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// Chip-style variation picker used on the grocery/others product details
/// (e.g. Size: 80g / 400g, Type: Pack / Carton). Selected option is a solid
/// green chip; others are muted grey. Pure presentation — the parent tracks
/// [selectedIndex] and reacts to [onSelected].
class VariationSelector extends StatelessWidget {
  final String? title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const VariationSelector({
    super.key,
    this.title,
    required this.options,
    this.selectedIndex = 0,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) ...[
        Text(title!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],
      Wrap(
        spacing: Dimensions.paddingSizeSmall,
        runSpacing: Dimensions.paddingSizeSmall,
        children: List.generate(options.length, (i) {
          final bool selected = i == selectedIndex;
          return InkWell(
            onTap: () => onSelected?.call(i),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: selected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Text(
                options[i],
                style: robotoMedium.copyWith(color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color, fontSize: Dimensions.fontSizeDefault),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}
