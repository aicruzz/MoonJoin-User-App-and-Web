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
/// countdown, View All), a peeking card carousel and pagination dots. It owns
/// NO business logic — the caller supplies the card widgets via [itemBuilder]
/// and maps its own already-working data. Reused by every module's Flash Sale
/// (Food/Grocery/Fashion …) and the Rental "Flash Rent" section, so there is a
/// single flash presentation across the app.
class MoonjoinFlashDealsSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final DateTime? endTime;             // countdown target; null → no countdown
  final Duration? countdownDuration;   // alternative seed (e.g. controller.duration)
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
    this.countdownDuration,
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
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage.clamp(0, widget.itemCount > 0 ? widget.itemCount - 1 : 0);
    _controller = PageController(initialPage: _current, viewportFraction: 0.88);
    _endTime = widget.endTime ?? (widget.countdownDuration != null ? DateTime.now().add(widget.countdownDuration!) : null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      child: ClipPath(
        clipper: _FlashOrganicClipper(),
        child: Container(
          color: green.withValues(alpha: 0.08),
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 26, Dimensions.paddingSizeDefault, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            _header(context, green),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            SizedBox(
              height: widget.cardHeight,
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

            if (widget.itemCount > 1) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _pagination(green),
            ],
          ]),
        ),
      ),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
        ]),
      ),

      if (_endTime != null) Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
        child: _FlashCountdown(endTime: _endTime!),
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

/// "Ends in" countdown — three brand-green blocks with labels, ticking every
/// second from [endTime]. Adapts to DAYS:HRS:MINS for long campaigns and
/// HRS:MINS:SECS for short ones (the common flash case), so numbers never
/// overflow. Presentation only: it reads an existing end time, never business logic.
class _FlashCountdown extends StatefulWidget {
  final DateTime endTime;
  const _FlashCountdown({required this.endTime});

  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final Duration d = widget.endTime.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _remaining = d.isNegative ? Duration.zero : d);
    if (d.isNegative) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final int days = _remaining.inDays;
    final int hours = _remaining.inHours % 24;
    final int minutes = _remaining.inMinutes % 60;
    final int seconds = _remaining.inSeconds % 60;

    final List<List<String>> blocks = days >= 1
        ? [[_two(days), 'days'.tr], [_two(hours), 'hours'.tr], [_two(minutes), 'mins'.tr]]
        : [[_two(hours), 'hours'.tr], [_two(minutes), 'mins'.tr], [_two(seconds), 'sec'.tr]];

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text('ends_in'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
      const SizedBox(height: 3),
      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _block(context, blocks[0][0], blocks[0][1]),
        _colon(context),
        _block(context, blocks[1][0], blocks[1][1]),
        _colon(context),
        _block(context, blocks[2][0], blocks[2][1]),
      ]),
    ]);
  }

  Widget _block(BuildContext context, String value, String label) {
    final Color green = Theme.of(context).primaryColor;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        constraints: const BoxConstraints(minWidth: 26),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
        child: Text(value, textAlign: TextAlign.center, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
      ),
      const SizedBox(height: 2),
      Text(label.toUpperCase(), style: robotoRegular.copyWith(fontSize: 8, color: Theme.of(context).disabledColor)),
    ]);
  }

  Widget _colon(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5, left: 2, right: 2),
    child: Text(':', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
  );
}
