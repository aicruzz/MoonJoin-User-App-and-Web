import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/moonjoin/motion/moonjoin_motion.dart';

/// Flutter-native renderer of the MoonJoin moon. Draws the state's moon phase and
/// choreographs the **Arc-Light** reveal from a single [reveal] value (0..1):
///   0.00–0.60  Node (arc-light) travels the lit rim while the moon waxes to phase
///   0.60–1.00  the light *joins* — settles onto the Node position; accents fade in
///   ≥1.00      still (terminal), or a refined [ambient] motion (Preparing/On-the-way)
/// No rotation, no loop, no loader.
class MoonJoinMoonPainter extends CustomPainter {
  final MoonJoinMoonSpec spec;
  final double reveal;   // 0..1 one-shot
  final double ambient;  // 0..1 slow loop (active states only)
  final MoonJoinMotionPalette palette;

  MoonJoinMoonPainter({required this.spec, required this.reveal, required this.ambient, required this.palette});

  static const double _rimStart = math.pi * 0.72;
  static const double _rimSpan = math.pi * 0.60;

  @override
  void paint(Canvas c, Size size) {
    final double s = size.width;
    final double cx = s / 2, cy = s / 2, r = s * 0.34;
    final Offset ctr = Offset(cx, cy);
    final Color lit = palette.litFor(spec.tone);

    final double fillFrac = reveal < 0.55 ? (reveal / 0.55) : 1.0;
    final double curP = spec.p * fillFrac;
    final double accent = ((reveal - 0.5) / 0.4).clamp(0.0, 1.0);

    c.save();
    // tilt + gentle forward drift (on-the-way) — refined, ≤4%
    if (spec.tilt != 0) {
      c.translate(cx, cy);
      c.rotate(spec.tilt * math.pi / 180);
      c.translate(-cx, -cy);
    }
    if (spec.ambient == MoonAmbient.drift && reveal >= 1.0) {
      c.translate(math.sin(ambient * 2 * math.pi) * r * 0.05, 0);
    }

    // trail (behind the travelling moon)
    if (spec.trail && curP > 0.1) {
      final tp = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = s * 0.03..color = lit;
      for (int i = 1; i <= 3; i++) {
        tp.color = lit.withValues(alpha: (0.22 - i * 0.05) * accent.clamp(0.4, 1.0));
        c.drawArc(Rect.fromCircle(center: Offset(cx + i * s * 0.10, cy), radius: r * 0.9), math.pi * 0.72, math.pi * 0.56, false, tp);
      }
    }

    // ── moon body (clipped) ──
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: ctr, radius: r)));
    c.drawCircle(ctr, r, Paint()..color = palette.graphite);
    if (curP > 0) {
      c.drawCircle(ctr, r, Paint()..color = lit);
      if (curP < 1) {
        final double dx = curP * 2 * r;
        c.drawCircle(Offset(cx + dx, cy), r, Paint()..color = spec.eclipse ? palette.amber : palette.graphite);
      }
    }
    // top-left moonlight
    final Rect hiRect = Rect.fromCircle(center: Offset(cx - r * 0.42, cy - r * 0.5), radius: r * 1.35);
    c.drawCircle(ctr, r, Paint()
      ..shader = RadialGradient(colors: [palette.hi, palette.hi.withValues(alpha: 0)]).createShader(hiRect));
    c.restore();

    // ── moonlight rim, traced by the arc-light during reveal ──
    if (curP > 0.02) {
      final double traced = reveal < 0.62 ? (reveal / 0.62) : 1.0;
      c.drawArc(Rect.fromCircle(center: ctr, radius: r), _rimStart, _rimSpan * traced, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.02..strokeCap = StrokeCap.round..color = palette.rim);
    }

    _accents(c, s, cx, cy, r, accent);

    // ── Node / Arc-Light ──
    if (reveal < 0.62) {
      final double a = _rimStart + _rimSpan * (reveal / 0.62);
      _arcLight(c, Offset(cx + math.cos(a) * r, cy + math.sin(a) * r), s);
    } else {
      final Offset? finalPos = _nodePos(cx, cy, r);
      final Offset rimEnd = Offset(cx + math.cos(_rimStart + _rimSpan) * r, cy + math.sin(_rimStart + _rimSpan) * r);
      final double k = _easeOutBack(((reveal - 0.62) / 0.38).clamp(0.0, 1.0));
      if (finalPos != null) {
        final Offset np = Offset.lerp(rimEnd, finalPos, k.clamp(0.0, 1.0))!;
        if (spec.star) {
          _star(c, np, s * 0.055, palette.rim);
        } else {
          c.drawCircle(np, s * 0.046, Paint()..color = lit);
          if (spec.sealCore) {
            c.drawCircle(np, s * 0.088, Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.014..color = palette.rim);
          }
        }
      } else {
        // no persistent node — the arc-light dissolves as it lands
        _arcLight(c, rimEnd, s, alpha: (1 - k).clamp(0.0, 1.0));
      }
    }

    // Subtle periodic Arc-Light "reminder" sweep (action-required states only):
    // once the reveal has settled, a faint light traces a short rim segment then
    // quiets — never a loop, never a spinner. Occupies ~40% of the ambient cycle.
    if (spec.ambient == MoonAmbient.sweep && reveal >= 1.0) {
      const double window = 0.4;
      if (ambient < window) {
        final double sk = ambient / window;
        final double a = _rimStart + _rimSpan * 0.5 * sk; // short segment
        final double glow = math.sin(sk * math.pi) * 0.55; // gentle fade in/out
        if (glow > 0.02) {
          _arcLight(c, Offset(cx + math.cos(a) * r, cy + math.sin(a) * r), s, alpha: glow);
        }
      }
    }
    c.restore();
  }

  void _accents(Canvas c, double s, double cx, double cy, double r, double a) {
    final Offset ctr = Offset(cx, cy);
    if (spec.forming) {
      final double breath = spec.ambient == MoonAmbient.forming ? (0.45 + 0.28 * math.sin(ambient * 2 * math.pi)) : 0.55;
      final p = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..color = palette.rim.withValues(alpha: breath * a);
      p.strokeWidth = s * 0.016;
      c.drawArc(Rect.fromCircle(center: ctr, radius: r * 0.50), math.pi * 0.15, math.pi * 0.90, false, p);
      p.color = palette.rim.withValues(alpha: breath * 0.6 * a);
      c.drawArc(Rect.fromCircle(center: ctr, radius: r * 0.30), math.pi * 0.40, math.pi * 0.95, false, p);
    }
    if (spec.guard) {
      c.drawArc(Rect.fromCircle(center: ctr, radius: r * 1.30), math.pi * 0.58, math.pi * 0.84, false,
          Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = s * 0.02..color = palette.rim.withValues(alpha: 0.5 * a));
    }
    if (spec.glow) {
      c.drawCircle(ctr, r * 1.22, Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.014..color = palette.litFor(spec.tone).withValues(alpha: 0.26 * a));
    }
    if (spec.beacon) {
      for (int d = 0; d < 3; d++) {
        final double o1 = r * 0.28 + d * s * 0.05, o2 = r * 0.62 + d * s * 0.05;
        c.drawLine(Offset(cx + o1, cy - o1), Offset(cx + o2, cy - o2),
            Paint()..strokeCap = StrokeCap.round..strokeWidth = s * 0.016..color = palette.rim.withValues(alpha: (0.5 - d * 0.15) * a));
      }
    }
    if (spec.brk) {
      c.drawLine(Offset(cx - r * 0.46, cy - r * 0.30), Offset(cx + r * 0.08, cy - r * 0.02),
          Paint()..strokeCap = StrokeCap.round..strokeWidth = s * 0.05..color = palette.graphite.withValues(alpha: a));
      c.drawCircle(Offset(cx - r * 0.46, cy - r * 0.30), s * 0.028, Paint()..color = palette.red.withValues(alpha: a));
    }
    if (spec.badge) {
      final Offset b = Offset(cx + r * 0.74, cy + r * 0.72);
      c.drawCircle(b, s * 0.058, Paint()..color = palette.red.withValues(alpha: a));
      final tp = TextPainter(
        text: TextSpan(text: '!', style: TextStyle(color: Colors.white.withValues(alpha: a), fontSize: s * 0.075, fontWeight: FontWeight.w800, height: 1)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(c, b - Offset(tp.width / 2, tp.height / 2));
    }
  }

  Offset? _nodePos(double cx, double cy, double r) {
    switch (spec.node) {
      case MoonNode.rim: return Offset(cx + math.cos(2.55) * r * 0.9, cy + math.sin(2.55) * r * 0.9);
      case MoonNode.terminator: return Offset(cx + r * (2 * spec.p - 1) * 0.92, cy);
      case MoonNode.center: return Offset(cx, cy);
      case MoonNode.tip: return Offset(cx - r * 0.02, cy - r * 0.88);
      case MoonNode.below: return Offset(cx, cy + r * 1.16);
      case MoonNode.off: return Offset(cx + r * 0.18, cy - r * 0.30);
      case MoonNode.none: return null;
    }
  }

  void _arcLight(Canvas c, Offset p, double s, {double alpha = 1}) {
    final double gr = s * 0.12;
    c.drawCircle(p, gr, Paint()
      ..shader = RadialGradient(colors: [palette.rim.withValues(alpha: alpha), palette.rim.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: p, radius: gr)));
    c.drawCircle(p, s * 0.028, Paint()..color = palette.rim.withValues(alpha: alpha));
  }

  void _star(Canvas c, Offset p, double r, Color col) {
    final ray = Paint()..strokeCap = StrokeCap.round..strokeWidth = r * 0.34..color = col;
    for (int i = 0; i < 4; i++) {
      final double a = i * math.pi / 2;
      c.drawLine(p + Offset(math.cos(a) * r * 0.35, math.sin(a) * r * 0.35),
          p + Offset(math.cos(a) * r * 1.25, math.sin(a) * r * 1.25), ray);
    }
    c.drawCircle(p, r * 0.45, Paint()..color = col);
  }

  double _easeOutBack(double t) {
    const double c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }

  @override
  bool shouldRepaint(covariant MoonJoinMoonPainter old) =>
      old.reveal != reveal || old.ambient != ambient || old.spec != spec || old.palette.green != palette.green;
}
