import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';

/// MoonJoin module glyph as seen in `home.png`: a white **organic blob**
/// (not a perfect circle) with a fixed-thickness green ring and a soft shadow.
/// The blob outline is subtly different for each module while the ring, outer
/// diameter, shadow and spacing stay identical.
///
/// A deterministic set of [_shapeCount] handcrafted blob shapes is defined
/// below; [shapeIndex] selects one so a given module always renders the same
/// shape. The icon sits inside with breathing room (never full-bleed).
class OrganicModuleIcon extends StatelessWidget {
  final String? imageUrl;
  final String? assetImage;
  final IconData? icon;
  final Widget? child;
  final double size;
  final int shapeIndex;
  final Color? ringColor;

  /// Fraction of the blob the artwork should visually occupy (bold & premium).
  /// LOCKED baseline: ~0.89 for normal modules, ~0.93 for featured — matching
  /// the reference. Only global final-polish may revisit this.
  final double artworkFraction;

  const OrganicModuleIcon({
    super.key,
    this.imageUrl,
    this.assetImage,
    this.icon,
    this.child,
    required this.size,
    this.shapeIndex = 0,
    this.ringColor,
    this.artworkFraction = 0.89,
  });

  /// Number of distinct organic shapes available.
  static const int shapeCount = 14;

  @override
  Widget build(BuildContext context) {
    final Color ring = ringColor ?? Theme.of(context).primaryColor;
    final double ringWidth = (size * 0.04).clamp(3.0, 6.0);
    // Artwork occupies ~[artworkFraction] of the blob (bold & premium) while
    // keeping comfortable breathing room. The ring/blob/spacing are untouched.
    final double inset = size * (1 - artworkFraction) / 2;

    return SizedBox(
      height: size, width: size,
      child: CustomPaint(
        painter: _BlobPainter(
          factors: _shapeFactors(shapeIndex % shapeCount),
          fill: Theme.of(context).cardColor,
          ring: ring,
          ringWidth: ringWidth,
        ),
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: Center(child: _content(context)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (child != null) return child!;
    if (icon != null) return FittedBox(child: Icon(icon, color: Theme.of(context).primaryColor));
    if (assetImage != null) return Image.asset(assetImage!, fit: BoxFit.contain);
    if (imageUrl != null && imageUrl!.isNotEmpty) return CustomImage(image: imageUrl!, fit: BoxFit.contain);
    return const SizedBox();
  }
}

/// Radius multipliers (per angle) for each organic shape. Generated once,
/// deterministically, so every shape is smooth, distinct and stable. Two gentle
/// harmonics keep the blobs "amoeba"-like (~±7% radius variation, matching the
/// measured reference tiles).
final List<List<double>> _shapeCache = List.generate(OrganicModuleIcon.shapeCount, (s) {
  const int samples = 30;
  // Distinct frequency/phase per shape → visually different blobs. Amplitudes
  // are kept gentle (~±6% total) to match the reference tiles, which are subtle
  // "amoeba" shapes rather than perfect circles.
  final double f1 = 2 + (s % 2).toDouble(); // 2 or 3 (low frequency = smooth)
  final double f2 = 3 + ((s + 1) % 2).toDouble(); // 3 or 4
  final double p1 = s * 0.9;
  final double p2 = s * 1.7 + 1.1;
  return List<double>.generate(samples, (k) {
    final double a = 2 * math.pi * k / samples;
    return 1 + 0.042 * math.sin(f1 * a + p1) + 0.020 * math.sin(f2 * a + p2);
  });
});

List<double> _shapeFactors(int index) => _shapeCache[index];

Path _buildBlobPath(List<double> factors, Offset center, double radius) {
  final int n = factors.length;
  final List<Offset> pts = List.generate(n, (k) {
    final double a = 2 * math.pi * k / n;
    final double r = radius * factors[k];
    return Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
  });
  // Smooth closed curve through the midpoints, using each point as a control.
  final Path path = Path();
  Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  final Offset start = mid(pts[n - 1], pts[0]);
  path.moveTo(start.dx, start.dy);
  for (int i = 0; i < n; i++) {
    final Offset cur = pts[i];
    final Offset next = pts[(i + 1) % n];
    final Offset m = mid(cur, next);
    path.quadraticBezierTo(cur.dx, cur.dy, m.dx, m.dy);
  }
  path.close();
  return path;
}

class _BlobPainter extends CustomPainter {
  final List<double> factors;
  final Color fill;
  final Color ring;
  final double ringWidth;
  _BlobPainter({required this.factors, required this.fill, required this.ring, required this.ringWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    // Leave room for the ring stroke and a little shadow spread.
    final double radius = size.width / 2 - ringWidth / 2 - size.width * 0.03;
    final Path path = _buildBlobPath(factors, center, radius);

    // Soft drop shadow following the blob.
    canvas.save();
    canvas.translate(0, size.width * 0.02);
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.05));
    canvas.restore();

    // White fill + green ring.
    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) =>
      old.factors != factors || old.ring != ring || old.fill != fill || old.ringWidth != ringWidth;
}
