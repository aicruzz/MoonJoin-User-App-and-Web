import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/moonjoin/filter_chip_widget.dart';
import 'package:moonjoin/util/dimensions.dart';

/// # MoonJoin Sub-Category Bar — the ONE official sub-category navigation component
///
/// A horizontally scrolling row of [MoonjoinFilterChip]s used for **category
/// navigation sub-categories** — e.g. Category Items (All · Red Meat · Poultry ·
/// Game Meat · Seafood), Restaurant categories (All · Pizza · Chinese · Drinks),
/// Grocery categories (All · Fruits · Vegetables · Beverages).
///
/// **Single source of truth.** Every category sub-category navigation MUST reuse
/// this exact component. No duplicate sub-category chip implementations.
///
/// **NOT** for Home / module **filter, sort, or action** chips (Filter, Sort,
/// Fast Delivery, Free Delivery, Rating, Offers, Discount, Nearby, …) — those are
/// a separate, already-approved system and must remain untouched.
///
/// Pure presentation: the parent owns the selection ([selectedIndex]) and the
/// filtering (via [onSelected]); this widget holds no business logic.
class MoonjoinSubCategoryBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const MoonjoinSubCategoryBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            // Center lets the chip take its intrinsic height (avoids the
            // horizontal ListView capping it and clipping the label).
            child: Center(child: MoonjoinFilterChip(
              label: labels[index],
              selected: index == selectedIndex,
              onTap: () => onSelected?.call(index),
            )),
          );
        },
      ),
    );
  }
}
