import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_motion.dart';
import 'package:moonjoin/common/widgets/moonjoin/motion/moonjoin_status_animation.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// Data for a single MoonJoin in-app notification.
class MoonJoinNotificationData {
  final String title;
  final String message;
  final MoonJoinMotionState state;   // drives the frozen MoonJoin moon icon
  final VoidCallback? onTap;
  final bool unavailable;            // reuse the approved warm/amber/red language
  /// Auto-dismiss delay. `null` = persistent (an action-required state that stays
  /// until resolved / the customer acts — e.g. unavailable items).
  final Duration? autoDismiss;
  const MoonJoinNotificationData({
    required this.title,
    required this.message,
    required this.state,
    this.onTap,
    this.unavailable = false,
    this.autoDismiss = const Duration(seconds: 5),
  });
}

/// THE reusable MoonJoin in-app notification layer — a premium foreground banner
/// (Apple/Stripe-calm, uniquely MoonJoin), shown over any screen. It reuses the
/// frozen MoonJoin Motion System (`MoonJoinStatusAnimation`) for its icon and the
/// approved MoonJoin colours/typography. One notification language for every future
/// event: order · parcel · trip · wallet · payment · KYC · promotion · unavailable.
class MoonJoinNotificationBanner {
  MoonJoinNotificationBanner._();

  static OverlayEntry? _entry;
  static VoidCallback? _dismisser; // the active host's animated close

  static void show(MoonJoinNotificationData data) {
    final BuildContext? ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;
    final OverlayState overlay = Overlay.of(ctx);
    _remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MoonJoinBannerHost(
        data: data,
        onClosed: () {
          if (_entry == entry) {
            _entry?.remove();
            _entry = null;
            _dismisser = null;
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Animated dismissal of the current banner (used when an action-required state
  /// resolves). Safe to call when nothing is showing.
  static void dismiss() => _dismisser?.call();

  static void _remove() {
    _entry?.remove();
    _entry = null;
    _dismisser = null;
  }
}

class _MoonJoinBannerHost extends StatefulWidget {
  final MoonJoinNotificationData data;
  final VoidCallback onClosed;
  const _MoonJoinBannerHost({required this.data, required this.onClosed});

  @override
  State<_MoonJoinBannerHost> createState() => _MoonJoinBannerHostState();
}

class _MoonJoinBannerHostState extends State<_MoonJoinBannerHost> with TickerProviderStateMixin {
  // Approved MoonJoin unavailable palette.
  static const Color _warm = Color(0xFFFBF3E2);
  static const Color _amber = Color(0xFFC98B3E);

  late final AnimationController _c;   // entrance (slide/fade + warm-in)
  AnimationController? _breath;         // unavailable-only slow breathing (~3s)
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -0.35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    _c.forward();
    if (widget.data.unavailable) {
      _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    }
    MoonJoinNotificationBanner._dismisser = _close;
    if (widget.data.autoDismiss != null) {
      _timer = Timer(widget.data.autoDismiss!, _close);
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _c.reverse();
    widget.onClosed();
  }

  void _handleTap() {
    widget.data.onTap?.call();
    _close();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath?.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall, Dimensions.paddingSizeSmall, 0),
              child: GestureDetector(
                onTap: _handleTap,
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < 0) _close(); // swipe up
                },
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_c, ?_breath]),
                    builder: (context, _) => _card(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final bool warn = widget.data.unavailable;
    // Arrival: for unavailable, the background eases from the normal tone into the
    // approved warm colour as the banner settles (attract once, then stable).
    final Color bg = warn ? Color.lerp(Theme.of(context).cardColor, _warm, _c.value)! : Theme.of(context).cardColor;
    final Color titleColor = warn ? const Color(0xFFB5772A) : Theme.of(context).textTheme.bodyLarge!.color!;
    final Color bodyColor = warn
        ? (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black).withValues(alpha: 0.82)
        : Theme.of(context).hintColor;
    final double breath = _breath?.value ?? 0.0; // 0..1

    final Widget content = Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      warn
          // Same footprint (46) — a slightly warmer circular container that gently
          // breathes (~6% brightness) so the moon reads as distinct, not larger.
          ? Container(
              width: 46, height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _amber.withValues(alpha: 0.12 + 0.07 * breath)),
              child: MoonJoinStatusAnimation(state: widget.data.state, size: 40),
            )
          : MoonJoinStatusAnimation(state: widget.data.state, size: 46),
      const SizedBox(width: Dimensions.paddingSizeSmall + 2),
      Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.data.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: titleColor)),
          if (widget.data.message.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(widget.data.message,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: bodyColor, height: 1.3)),
          ],
        ]),
      ),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      InkWell(
        onTap: _close,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 18, color: bodyColor.withValues(alpha: 0.8)),
        ),
      ),
    ]);

    final BoxDecoration decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      border: warn ? Border.all(color: _amber.withValues(alpha: 0.45)) : null,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8)),
        BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );

    if (!warn) {
      return Container(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), decoration: decoration, child: content);
    }

    // Unavailable: a strengthened leading accent strip is the instant anchor that
    // distinguishes it from normal order-status banners (never the whole card orange).
    return Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: _amber),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), child: content),
          ),
        ]),
      ),
    );
  }
}
