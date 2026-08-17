import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin Flash Deals — the approved premium section shell
/// (ui-designs/flashcard.PNG + flashcard_sample_look.PNG).
///
/// PURE PRESENTATION: an organic pale-green module (wavy top/bottom, rounded
/// corners) with a header (green lightning disc + title/subtitle, "Ends in"
/// countdown, View All), an auto-rotating peeking card carousel and pagination
/// dots. It owns NO business logic — the caller supplies the card widgets via
/// [itemBuilder] and maps its own already-working data. Reused by every module's
/// Flash Sale (Food/Grocery/Fashion …) and the Rental "Flash Rent" section.
///
/// The organic clip is painted BEHIND the content (Stack), so only the green
/// background carries the amoeba silhouette — the inner white cards stay clean
/// rounded rectangles. The countdown ticks from an absolute [endTime] (a stable
/// campaign end), never a relative duration, so it can never freeze.
class MoonjoinFlashDealsSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final DateTime? endTime;             // absolute campaign end; null → no countdown
  final VoidCallback? onViewAll;       // null → hide View All
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onPageChanged;
  final int initialPage;
  final double cardHeight;

  const MoonjoinFlashDealsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.itemBuilder,
    this.endTime,
    this.onViewAll,
    this.onPageChanged,
    this.initialPage = 0,
    this.cardHeight = 210,
  });

  @override
  State<MoonjoinFlashDealsSection> createState() => _MoonjoinFlashDealsSectionState();
}

class _MoonjoinFlashDealsSectionState extends State<MoonjoinFlashDealsSection> {
  late PageController _controller;
  int _current = 0;
  Timer? _autoTimer;

  static const Duration _autoInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage.clamp(0, widget.itemCount > 0 ? widget.itemCount - 1 : 0);
    _controller = PageController(initialPage: _current, viewportFraction: 0.88);
    _startAuto();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── Auto-rotation (like the home promo carousel): advances every few seconds,
  // pauses while the user is touching, then resumes. Manual swipe and card taps
  // are untouched; it only drives the same PageController/index. ──
  void _startAuto() {
    _autoTimer?.cancel();
    if (widget.itemCount <= 1) return;
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final int next = (_current + 1) % widget.itemCount;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  void _pauseAuto() => _autoTimer?.cancel();

  void _resumeAutoSoon() {
    _autoTimer?.cancel();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startAuto();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      child: Stack(children: [

        // Organic pale-green background — the ONLY element carrying the amoeba
        // silhouette. Sized to fill the content behind it.
        Positioned.fill(
          child: ClipPath(
            clipper: _FlashOrganicClipper(),
            child: Container(color: green.withValues(alpha: 0.08)),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 26, Dimensions.paddingSizeDefault, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            _header(context, green),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            SizedBox(
              height: widget.cardHeight,
              child: Listener(
                onPointerDown: (_) => _pauseAuto(),
                onPointerUp: (_) => _resumeAutoSoon(),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.itemCount,
                  padEnds: false,
                  onPageChanged: (i) {
                    setState(() => _current = i);
                    widget.onPageChanged?.call(i);
                  },
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, bottom: 6),
                    child: widget.itemBuilder(context, i),
                  ),
                ),
              ),
            ),

            if (widget.itemCount > 1) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _pagination(green),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _header(BuildContext context, Color green) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

      Container(
        height: 40, width: 40, alignment: Alignment.center,
        decoration: BoxDecoration(color: green, shape: BoxShape.circle),
        child: const Icon(Icons.bolt, color: Colors.white, size: 24),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),

      Expanded(
        flex: 2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
        ]),
      ),

      // Four countdown blocks (DAYS:HRS:MINS:SECS) can be wide next to the title +
      // View All, so the countdown gets a flex slot and scales down only if space
      // is tight — full size on a normal phone, never an overflow on narrow ones.
      if (widget.endTime != null) Expanded(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: MoonjoinFlashCountdown(endTime: widget.endTime!),
          ),
        ),
      ),

      if (widget.onViewAll != null) InkWell(
        onTap: widget.onViewAll,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('view_all'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: green)),
            Icon(Icons.chevron_right, size: 18, color: green),
          ]),
        ),
      ),
    ]);
  }

  Widget _pagination(Color green) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.itemCount, (i) {
      final bool active = i == _current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 7, width: active ? 22 : 7,
        decoration: BoxDecoration(
          color: active ? green : green.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
      );
    }));
  }
}

/// Organic wavy background for the Flash Deals module: rounded corners, a soft
/// centre dip on the top edge and a soft centre rise on the bottom edge — the
/// premium "amoeba" character of the approved design, defined in fractions of
/// the width so it renders stably at any screen size.
class _FlashOrganicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width, h = size.height;
    const double r = 28, topWave = 16, botWave = 14;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..cubicTo(w * 0.30, 0, w * 0.34, topWave, w * 0.5, topWave)
      ..cubicTo(w * 0.66, topWave, w * 0.70, 0, w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..cubicTo(w * 0.70, h, w * 0.66, h - botWave, w * 0.5, h - botWave)
      ..cubicTo(w * 0.34, h - botWave, w * 0.30, h, r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// The four countdown values as DAYS:HRS:MINS:SECS (zero-padded) for [remaining].
///
/// Pure + public so it can be unit-tested. Days stay a SEPARATE block (never
/// folded into total hours), and it ALWAYS ends with a seconds block, so the
/// smallest visible unit changes every second and the countdown never LOOKS
/// static. When days reach 0 it naturally continues as 00:HH:MM:SS.
List<String> moonjoinFlashCountdownDigits(Duration remaining) {
  final Duration r = remaining.isNegative ? Duration.zero : remaining;
  String two(int v) => v.toString().padLeft(2, '0');
  return [two(r.inDays), two(r.inHours % 24), two(r.inMinutes % 60), two(r.inSeconds % 60)];
}

/// "Ends in" countdown — three brand-green HRS:MINS:SECS blocks, ticking every
/// second from the absolute [endTime]. Because it computes `endTime - now` each
/// tick (never a relative duration), it stays correct and in sync with the
/// View All/details countdown even if the widget rebuilds, and can never freeze
/// on a sliding target. Presentation only: it reads an existing end time.
class MoonjoinFlashCountdown extends StatefulWidget {
  final DateTime endTime;
  const MoonjoinFlashCountdown({super.key, required this.endTime});

  @override
  State<MoonjoinFlashCountdown> createState() => MoonjoinFlashCountdownState();
}

class MoonjoinFlashCountdownState extends State<MoonjoinFlashCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant MoonjoinFlashCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      setState(() => _remaining = _compute());
    }
  }

  Duration _compute() {
    final Duration d = widget.endTime.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  void _tick() {
    if (!mounted) return;
    final Duration d = _compute();
    setState(() => _remaining = d);
    if (d == Duration.zero) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DAYS:HRS:MINS:SECS — days stays a separate block, seconds is the ticking
    // block (so it can never look static). Block style/labels are the approved
    // design; kept compact so four blocks fit alongside the title + View All.
    final List<String> digits = moonjoinFlashCountdownDigits(_remaining);

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text('ends_in'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
      const SizedBox(height: 3),
      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _block(context, digits[0], 'days'.tr),
        _colon(context),
        _block(context, digits[1], 'hours'.tr),
        _colon(context),
        _block(context, digits[2], 'mins'.tr),
        _colon(context),
        _block(context, digits[3], 'sec'.tr),
      ]),
    ]);
  }

  Widget _block(BuildContext context, String value, String label) {
    final Color green = Theme.of(context).primaryColor;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        constraints: const BoxConstraints(minWidth: 22),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        child: Text(value, textAlign: TextAlign.center, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
      ),
      const SizedBox(height: 2),
      Text(label.toUpperCase(), style: robotoRegular.copyWith(fontSize: 8, color: Theme.of(context).disabledColor)),
    ]);
  }

  Widget _colon(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5, left: 1, right: 1),
    child: Text(':', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
  );
}
