import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// A single selectable MoonJoin pill used for filters and tabs. Green fill when
/// [selected], outlined otherwise. Pure presentation.
class MoonjoinFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const MoonjoinFilterChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: selected ? primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(color: selected ? primary : Theme.of(context).disabledColor.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? Colors.white : Theme.of(context).hintColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          ],
          Text(label, style: robotoMedium.copyWith(color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color, fontSize: Dimensions.fontSizeSmall)),
        ]),
      ),
    );
  }
}

/// A horizontally scrolling row of [MoonjoinFilterChip]s. The parent owns the
/// selection ([selectedIndex]) and reacts via [onSelected].
class FilterChipBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final EdgeInsetsGeometry padding;

  const FilterChipBar({
    super.key,
    required this.labels,
    this.selectedIndex = 0,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(children: List.generate(labels.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
          child: MoonjoinFilterChip(label: labels[i], selected: i == selectedIndex, onTap: () => onSelected?.call(i)),
        );
      })),
    );
  }
}
