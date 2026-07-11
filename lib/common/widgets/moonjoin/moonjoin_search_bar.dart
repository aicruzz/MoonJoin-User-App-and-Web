import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Rounded white search field with an optional green filter button, matching
/// the MoonJoin home/search designs. Pure presentation — supply a [controller]
/// and/or callbacks. Set [readOnly] with [onTap] to use it as a "tap to open
/// search" affordance.
class MoonjoinSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool readOnly;
  final bool showFilter;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? leading;

  const MoonjoinSearchBar({
    super.key,
    this.hintText = '',
    this.controller,
    this.readOnly = false,
    this.showFilter = true,
    this.onTap,
    this.onFilterTap,
    this.onChanged,
    this.onSubmitted,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    // One full-width white pill; the green filter button sits INSIDE it at the
    // right (matching the Figma HOME SCREEN search bar).
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        leading ?? Icon(Icons.search, color: Theme.of(context).hintColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
            ),
          ),
        ),
        if (showFilter)
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Container(
              height: 44, width: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 22),
            ),
          ),
      ]),
    );
  }
}
