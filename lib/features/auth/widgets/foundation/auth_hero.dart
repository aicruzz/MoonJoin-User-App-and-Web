import 'package:flutter/material.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Auth Foundation (Phase 9C-1) — the premium brand hero.
///
/// A large MoonJoin-green banner (≈36% of the screen) with elegant large curved
/// bottom edges. At its centre a softly glowing MoonJoin logo "breathes" (a slow
/// inhale/exhale scale + glow, ease-in-out, no spin/bounce/flash). Below it a
/// white welcome title and one trust subtitle.
///
/// Presentation only. Callers pass already-translated strings (no `.tr` here),
/// matching the frozen ProfilePageHeader `title` contract. [logoAssetPath] keeps
/// the foundation reusable across future MoonJoin apps; defaults to [Images.logo].
///
/// Logo presentation is future-proof: the white container is ALWAYS a perfect
/// circle. The logo image is clipped with [logoCornerRadius] so a logo shipping
/// with square corners / a solid background sits elegantly inside the circle. A
/// logo that is already transparent is visually unaffected by the clip and
/// renders exactly as uploaded. Updating the MoonJoin logo asset later therefore
/// needs no code change — at most adjust [logoCornerRadius] for a new asset.
class AuthHero extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double logoWidth;
  final String logoAssetPath;

  /// Corner radius applied when clipping the logo image inside the circle.
  final double logoCornerRadius;

  /// Fraction of screen height the hero occupies (clamped to a sensible min).
  final double heightFactor;

  /// Enable the soft breathing animation (disable for tests/goldens).
  final bool animate;

  const AuthHero({
    super.key,
    required this.title,
    this.subtitle,
    this.logoWidth = 64,
    this.logoAssetPath = Images.logo,
    this.logoCornerRadius = 14,
    this.heightFactor = 0.36,
    this.animate = true,
  });

  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    final CurvedAnimation curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 1.0, end: 1.055).animate(curve);
    _glow = Tween<double>(begin: 0.16, end: 0.40).animate(curve);
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topInset = MediaQuery.of(context).padding.top;
    final double heroHeight = (screenHeight * widget.heightFactor).clamp(280.0, 420.0);
    // White logo disc: the logo now fills the circle 100% (owner revision).
    final double discSize = widget.logoWidth + Dimensions.paddingSizeLarge * 2;

    return Container(
      width: double.infinity,
      height: heroHeight,
      padding: EdgeInsets.only(
        top: topInset + Dimensions.paddingSizeLarge,
        bottom: Dimensions.paddingSizeExtraLarge,
        left: Dimensions.paddingSizeExtraLarge,
        right: Dimensions.paddingSizeExtraLarge,
      ),
      decoration: BoxDecoration(
        color: green,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Softly glowing, breathing logo — fills the white circle 100%.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.animate ? _scale.value : 1.0,
                child: Container(
                  width: discSize,
                  height: discSize,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: widget.animate ? _glow.value : 0.22),
                        blurRadius: 34,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Image.asset(widget.logoAssetPath, width: discSize, height: discSize, fit: BoxFit.cover),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Colors.white),
          ),

          if (widget.subtitle != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
