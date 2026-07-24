import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Reusable MoonJoin green waved header for Profile sub-pages (Personal
/// Information, and future Profile pages). Reproduces the frozen Stage-1 Account
/// header language: primary-green fill, concave wave bottom, status-bar-aware top
/// spacing, white title, optional back button and trailing action.
///
/// NOTE: the wave geometry mirrors the frozen `_HeaderWaveClipper` in
/// `menu_screen.dart`. It is duplicated here (not imported) to avoid modifying the
/// frozen Account shell; unify into one shared clipper when Stage 1 is next
/// intentionally reopened.
class ProfilePageHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;
  /// Extra green space below the title row — room for an avatar that overlaps the
  /// header/body boundary via a parent Stack.
  final double bottomExtra;
  const ProfilePageHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.trailing,
    this.bottomExtra = Dimensions.paddingSizeLarge,
  });

  static const double _slot = 40;

  @override
  Widget build(BuildContext context) {
    final Color onGreen = Theme.of(context).cardColor;
    return ClipPath(
      clipper: _ProfileHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.only(
          left: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeDefault,
          top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeSmall,
          bottom: bottomExtra,
        ),
        child: Row(children: [
          SizedBox(
            width: _slot,
            child: showBack
                ? InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(30),
                    child: Icon(Icons.arrow_back_ios_new, size: 20, color: onGreen),
                  )
                : const SizedBox(),
          ),
          Expanded(child: Text(
            title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: onGreen),
          )),
          SizedBox(width: _slot, child: Align(alignment: Alignment.centerRight, child: trailing ?? const SizedBox())),
        ]),
      ),
    );
  }
}

class _ProfileHeaderWaveClipper extends CustomClipper<Path> {
  static const double _amp = 20;
  @override
  Path getClip(Size size) {
    final path = Path();
    final h = size.height;
    final w = size.width;
    path.lineTo(0, h - _amp * 0.35);
    path.cubicTo(w * 0.30, h, w * 0.52, h - _amp, w * 0.72, h - _amp * 0.85);
    path.cubicTo(w * 0.88, h - _amp * 0.72, w * 0.96, h - _amp * 0.15, w, h - _amp * 0.35);
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
