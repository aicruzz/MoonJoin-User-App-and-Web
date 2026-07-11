import 'package:flutter/material.dart';

/// MoonJoin signature header: a solid [color] block whose bottom edge curves
/// (a gentle wave) into the body behind it. Shared across Home and both
/// Product Details screens so the motif is defined in exactly one place.
///
/// Place it as the lowest layer of a [Stack] (or as a background) and overlap
/// the screen content on top. [height] is the flat height before the curve;
/// the wave adds a little below that.
///
/// [notchCenters] are fractional x positions (0–1) where the green cradles an
/// overlapping tile — the bottom edge dips down at each notch and recedes
/// between them (matching the featured-module notches in `home.png`). When null,
/// a single gentle wave is used.
class WavyHeader extends StatelessWidget {
  final double height;
  final Color? color;
  final Widget? child;
  final List<double>? notchCenters;

  const WavyHeader({super.key, this.height = 220, this.color, this.child, this.notchCenters});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WavyHeaderClipper(notchCenters),
      child: Container(
        height: height,
        width: double.infinity,
        color: color ?? Theme.of(context).primaryColor,
        child: child,
      ),
    );
  }
}

class _WavyHeaderClipper extends CustomClipper<Path> {
  final List<double>? notchCenters;
  _WavyHeaderClipper(this.notchCenters);

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;

    if (notchCenters == null || notchCenters!.length != 2) {
      // Simple single gentle wave.
      final Path path = Path();
      path.lineTo(0, h - 40);
      path.quadraticBezierTo(w * 0.25, h, w * 0.5, h - 30);
      path.quadraticBezierTo(w * 0.75, h - 60, w, h - 20);
      path.lineTo(w, 0);
      path.close();
      return path;
    }

    // Two featured notches: the green edge dips DOWN at each tile centre
    // (cradling it) and recedes UP between and at the edges.
    final double c1 = notchCenters![0];
    final double c2 = notchCenters![1];
    final List<Offset> pts = [
      Offset(0, h - 34),
      Offset(w * ((c1 + 0) / 2), h - 40),   // recede before first tile
      Offset(w * c1, h - 6),                // first notch (green deepest)
      Offset(w * 0.5, h - 48),              // recede between tiles
      Offset(w * c2, h - 6),                // second notch
      Offset(w * ((c2 + 1) / 2), h - 40),   // recede after second tile
      Offset(w, h - 30),
    ];

    final Path path = Path();
    path.lineTo(pts.first.dx, pts.first.dy);
    // Smooth curve through the control points (control = point, end = midpoint).
    for (int i = 0; i < pts.length - 1; i++) {
      final Offset cur = pts[i];
      final Offset next = pts[i + 1];
      final Offset mid = Offset((cur.dx + next.dx) / 2, (cur.dy + next.dy) / 2);
      path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WavyHeaderClipper oldClipper) => oldClipper.notchCenters != notchCenters;
}
