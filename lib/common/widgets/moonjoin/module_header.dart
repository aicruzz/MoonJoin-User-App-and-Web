import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/moonjoin/wavy_header.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// The green MoonJoin top area used on Home and module screens: greeting +
/// user name, a tappable location row, notification & cart action icons (with
/// count badges), sitting on a [WavyHeader], with an optional [searchBar]
/// overlapping the curve.
///
/// Pure presentation: pass text and callbacks. Provide the already-built search
/// widget via [searchBar] (e.g. a `MoonjoinSearchBar`) to keep this decoupled.
class MoonjoinModuleHeader extends StatelessWidget {
  final String? greeting;
  final String? userName;
  final String? title;
  final String? locationText;
  final VoidCallback? onLocationTap;
  final int notificationCount;
  final int cartCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCartTap;
  final Widget? searchBar;
  final double height;
  final List<double>? notchCenters;

  const MoonjoinModuleHeader({
    super.key,
    this.greeting,
    this.userName,
    this.title,
    this.locationText,
    this.onLocationTap,
    this.notificationCount = 0,
    this.cartCount = 0,
    this.onNotificationTap,
    this.onCartTap,
    this.searchBar,
    this.height = 210,
    this.notchCenters,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      WavyHeader(height: height, notchCenters: notchCenters),
      Positioned(
        top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeSmall,
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (greeting != null)
                  Text(greeting!, style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
                if (title != null || userName != null)
                  Text(
                    title ?? userName ?? '',
                    style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeOverLarge),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
              ]),
            ),
            if (onNotificationTap != null)
              _HeaderActionButton(icon: Icons.notifications_none, count: notificationCount, onTap: onNotificationTap!),
            if (onCartTap != null) ...[
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _HeaderActionButton(icon: Icons.shopping_cart_outlined, count: cartCount, onTap: onCartTap!),
            ],
          ]),

          if (locationText != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            InkWell(
              onTap: onLocationTap,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Flexible(
                  child: Text(locationText!, style: robotoMedium.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (onLocationTap != null) const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              ]),
            ),
          ],

          if (searchBar != null) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            searchBar!,
          ],
        ]),
      ),
    ]);
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;
  const _HeaderActionButton({required this.icon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 44, width: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        if (count > 0)
          Positioned(
            top: -4, right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraSmall),
              ),
            ),
          ),
      ]),
    );
  }
}
