import 'dart:math' as math;
import 'package:flutter/material.dart';

/// MoonJoin onboarding progress — the four story beats as **moon phases**
/// (waxing crescent → half → gibbous → full). Replaces childish dots and
/// reinforces the "moon waxing to full" metaphor. Static, cheap, timeless.
class MoonJoinMoonPhaseProgress extends StatelessWidget {
  final int count;
  final int active;
  final double size;
  const MoonJoinMoonPhaseProgress({super.key, required this.count, required this.active, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? size + 4 : size,
          height: isActive ? size + 4 : size,
          child: CustomPaint(
            painter: _PhasePainter(
              phase: (i + 1) / count, // 0.25 .. 1.0
              active: isActive,
            ),
          ),
        );
      }),
    );
  }
}

class _PhasePainter extends CustomPainter {
  final double phase; // illuminated fraction
  final bool active;
  _PhasePainter({required this.phase, required this.active});

  static const Color _lit = Color(0xFFF3EFE1);

  @override
  void paint(Canvas c, Size size) {
    final Offset ctr = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2;
    final Color lit = _lit.withValues(alpha: active ? 1.0 : 0.55);
    final Color dark = _lit.withValues(alpha: active ? 0.22 : 0.14);

    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: ctr, radius: r)));
    c.drawCircle(ctr, r, Paint()..color = dark);
    if (phase > 0) {
      c.drawCircle(ctr, r, Paint()..color = lit);
      if (phase < 1) {
        final double dx = phase * 2 * r;
        c.drawCircle(Offset(ctr.dx + dx, ctr.dy), r, Paint()..color = dark);
      }
    }
    c.restore();
    // subtle rim
    c.drawCircle(ctr, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.08)
      ..color = _lit.withValues(alpha: active ? 0.35 : 0.18));
  }

  @override
  bool shouldRepaint(covariant _PhasePainter old) => old.phase != phase || old.active != active;
}
