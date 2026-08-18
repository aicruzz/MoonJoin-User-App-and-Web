import 'package:flutter/material.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin bottom-nav item (reference: `ui-designs/.../home.png`): a filled/
/// outlined [IconData] with a light-green rounded pill behind the active icon,
/// and a green (selected) / grey (unselected) label.
class BottomNavItemWidget extends StatelessWidget {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String title;
  final Function? onTap;
  final bool isSelected;
  const BottomNavItemWidget({super.key, this.onTap, this.isSelected = false, required this.title, required this.selectedIcon, required this.unselectedIcon});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color inactive = Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha: 0.7);
    return Expanded(
      child: InkWell(
        onTap: onTap as void Function()?,
        borderRadius: BorderRadius.circular(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 0, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(isSelected ? selectedIcon : unselectedIcon, size: 24, color: isSelected ? primary : inactive),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: robotoRegular.copyWith(
              color: isSelected ? primary : inactive,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }
}
