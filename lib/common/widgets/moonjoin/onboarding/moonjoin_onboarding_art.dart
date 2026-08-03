import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MoonJoin Onboarding — "One Orbit" original illustration system
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 100% programmatic MoonJoin artwork (no raster assets, no external art). An
/// immersive branded twilight — a *living connected city at night* — drawn from
/// our own visual language: organic blobs (the OrganicModuleIcon curve family),
/// MoonJoin green, soft light-arcs and a calm central moon (the frozen Motion
/// System's light model, reused — not modified).
///
/// The four scenes form one story that waxes to a peak then resolves, matching
/// the moon metaphor and the approved story-arc pacing (20 / 40 / 25 / 15):
///   arrival     — calm, minimal, intriguing         (waxing sliver)
///   ecosystem   — the hero: one connected ecosystem  (gibbous, densest)
///   delivery    — trust: a single light is delivered (gibbous, focused)
///   resolution  — quiet full moon, "you're ready"    (full, still)
///
/// Performance: the heavy, unchanging layer is recorded ONCE into a [ui.Picture]
/// per (scene, size, dpr); only a thin light layer (moon breath, one travelling
/// node, drifting particles) animates each frame. No `MaskFilter.blur` / image
/// filters — every glow is a radial-gradient shader (cheap, battery friendly).
enum MoonJoinOnboardingScene { arrival, ecosystem, delivery, resolution }

class MoonJoinOnboardingArt extends StatefulWidget {
  /// Which story beat to render.
  final MoonJoinOnboardingScene scene;

  /// Shared slow ambient (0..1) — a single app-level ticker drives every scene's
  /// calm life (moon breath, travelling light, particle drift).
  final Animation<double> ambient;

  const MoonJoinOnboardingArt({super.key, required this.scene, required this.ambient});

  @override
  State<MoonJoinOnboardingArt> createState() => _MoonJoinOnboardingArtState();
}

class _MoonJoinOnboardingArtState extends State<MoonJoinOnboardingArt> {
  ui.Picture? _static;
  Size? _size;
  MoonJoinOnboardingScene? _scene;

  @override
  void dispose() {
    _static?.dispose();
    super.dispose();
  }

  ui.Picture _record(Size size) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas c = Canvas(recorder);
    MoonJoinOnboardingPainter.paintStatic(c, size, widget.scene);
    return recorder.endRecording();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_static == null || _size != size || _scene != widget.scene) {
          _static?.dispose();
          _static = _record(size);
          _size = size;
          _scene = widget.scene;
        }
        return AnimatedBuilder(
          animation: widget.ambient,
          builder: (context, _) => CustomPaint(
            size: size,
            painter: MoonJoinOnboardingPainter(
              scene: widget.scene,
              ambient: widget.ambient.value,
              staticLayer: _static!,
            ),
          ),
        );
      }),
    );
  }
}

/// The MoonJoin onboarding palette — a consistent branded twilight (the scene is
/// a designed moment, intentionally the same rich night in light & dark). Text
/// and controls live outside the art and remain readable over the bottom scrim.
class MoonJoinOnboardingPalette {
  static const Color bgTop = Color(0xFF06120E);       // near-black green (sky)
  static const Color bgMid = Color(0xFF0A2018);       // deep moss
  static const Color bgHorizon = Color(0xFF10352A);   // horizon glow
  static const Color moonLit = Color(0xFFF3EFE1);     // warm moonlight
  static const Color moonDark = Color(0xFF16352A);    // moon's dark side
  static const Color green = Color(0xFF34C08A);       // MoonJoin light (arcs/node)
  static const Color warm = Color(0xFFF6C983);        // warm window/light accent
  static const Color star = Color(0xFFFFFFFF);

  /// Curated, desaturated module accents — each MoonJoin service woven naturally
  /// into the night (never labelled, never an icon grid). Order maps to the
  /// ecosystem nodes below: Food · Grocery · Pharmacy · Shopping · Car Rental ·
  /// Short Apartment · Fuel · Parcel · Messenger · Wallet · Payments.
  static const List<Color> accents = [
    Color(0xFFE8845E), // Food — warm coral
    Color(0xFF6FB36A), // Grocery — fresh green
    Color(0xFF4FB5A5), // Pharmacy — teal
    Color(0xFF9A7BD0), // Shopping — soft violet
    Color(0xFF6E8FC0), // Car Rental — slate blue
    Color(0xFFD9B87E), // Short Apartment — warm sand
    Color(0xFFE0975A), // Fuel — amber
    Color(0xFFC98B6B), // Parcel — clay
    Color(0xFF5FA9D8), // Messenger — sky
    Color(0xFFE6C25E), // Wallet — gold
    Color(0xFF48C08C), // Payments — emerald
  ];
}

/// A single ecosystem node (a service) placed in the constellation.
class _Node {
  final double x, y;   // fractions of size
  final double r;      // radius fraction of shortest side
  final int accent;    // index into palette accents
  final int shape;     // organic blob shape seed
  final double depth;  // 0 (back, dim/small) .. 1 (front, bright)
  const _Node(this.x, this.y, this.r, this.accent, this.shape, this.depth);
}

/// A soft light-arc connecting two points (fractions of size).
class _Arc {
  final double ax, ay, bx, by, bend;
  const _Arc(this.ax, this.ay, this.bx, this.by, this.bend);
}

class MoonJoinOnboardingPainter extends CustomPainter {
  final MoonJoinOnboardingScene scene;
  final double ambient; // 0..1
  final ui.Picture staticLayer;

  MoonJoinOnboardingPainter({required this.scene, required this.ambient, required this.staticLayer});

  // ── Composition data (deterministic) ──────────────────────────────────────
  // The hero ecosystem: 11 services woven around the moon in two depth layers.
  static const Offset _moonAt = Offset(0.5, 0.40);

  static const List<_Node> _ecosystem = [
    // back layer (dim, small) — the city's distance
    _Node(0.20, 0.30, 0.028, 4, 3, 0.15),
    _Node(0.80, 0.27, 0.026, 8, 5, 0.15),
    _Node(0.30, 0.16, 0.022, 2, 7, 0.10),
    _Node(0.68, 0.14, 0.024, 9, 9, 0.10),
    // front layer (brighter, larger) — the everyday services
    _Node(0.16, 0.50, 0.050, 0, 1, 0.90), // Food
    _Node(0.83, 0.48, 0.048, 1, 2, 0.85), // Grocery
    _Node(0.28, 0.60, 0.044, 2, 4, 0.80), // Pharmacy
    _Node(0.72, 0.61, 0.046, 3, 6, 0.82), // Shopping
    _Node(0.40, 0.30, 0.040, 5, 8, 0.70), // Short Apartment
    _Node(0.60, 0.30, 0.040, 6, 10, 0.70), // Fuel
    _Node(0.50, 0.66, 0.052, 10, 0, 0.95), // Payments (anchor, front)
  ];

  // Arcs weave the ecosystem into ONE system (not scattered points).
  static const List<_Arc> _arcs = [
    _Arc(0.16, 0.50, 0.50, 0.40, -0.10),
    _Arc(0.83, 0.48, 0.50, 0.40, 0.10),
    _Arc(0.28, 0.60, 0.50, 0.66, -0.06),
    _Arc(0.72, 0.61, 0.50, 0.66, 0.06),
    _Arc(0.40, 0.30, 0.50, 0.40, -0.04),
    _Arc(0.60, 0.30, 0.50, 0.40, 0.04),
    _Arc(0.16, 0.50, 0.28, 0.60, 0.08),
    _Arc(0.83, 0.48, 0.72, 0.61, -0.08),
  ];

  // ── Static layer (recorded once) ──────────────────────────────────────────
  static void paintStatic(Canvas c, Size size, MoonJoinOnboardingScene scene) {
    final double w = size.width, h = size.height;
    final double s = math.min(w, h);
    final Rect full = Offset.zero & size;

    // 1) Branded twilight sky — vertical gradient with a soft horizon glow.
    c.drawRect(full, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [MoonJoinOnboardingPalette.bgTop, MoonJoinOnboardingPalette.bgMid, MoonJoinOnboardingPalette.bgHorizon],
        stops: [0.0, 0.55, 1.0],
      ).createShader(full));

    // Horizon moss glow (radial, low, cheap).
    final Rect horizon = Rect.fromCircle(center: Offset(w * 0.5, h * 1.02), radius: w * 0.9);
    c.drawRect(full, Paint()
      ..shader = RadialGradient(
        colors: [MoonJoinOnboardingPalette.green.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(horizon));

    final double weight = _weight(scene); // story-arc intensity

    // 2) Starfield — a few faint, timeless points (denser as the story builds).
    final math.Random rnd = math.Random(7);
    final int stars = (18 + weight * 26).round();
    final Paint sp = Paint();
    for (int i = 0; i < stars; i++) {
      final double sx = rnd.nextDouble() * w;
      final double sy = rnd.nextDouble() * h * 0.62;
      final double sr = 0.5 + rnd.nextDouble() * 1.1;
      sp.color = MoonJoinOnboardingPalette.star.withValues(alpha: 0.05 + rnd.nextDouble() * 0.14 * (0.4 + weight));
      c.drawCircle(Offset(sx, sy), sr, sp);
    }

    // 3) The moon (base disc + phase). Breathing glow is dynamic (drawn later).
    final Offset moon = Offset(w * _moonFor(scene).dx, h * _moonFor(scene).dy);
    final double mr = s * _moonRadius(scene);
    _paintMoon(c, moon, mr, _phase(scene));

    // 4) Ecosystem — scene-dependent composition.
    switch (scene) {
      case MoonJoinOnboardingScene.arrival:
        _paintSkyline(c, size, density: 0.35, alpha: 0.5);
        break;
      case MoonJoinOnboardingScene.ecosystem:
        _paintArcs(c, size, _arcs, alpha: 0.5);
        for (final _Node n in _ecosystem) {
          _paintNode(c, size, n, dim: 1.0);
        }
        _paintSkyline(c, size, density: 1.0, alpha: 0.9);
        break;
      case MoonJoinOnboardingScene.delivery:
        // Focused: a vendor cluster (left) and a home (right) with one big arc.
        _paintArcs(c, size, const [_Arc(0.22, 0.52, 0.80, 0.60, -0.16)], alpha: 0.55);
        _paintNode(c, size, const _Node(0.22, 0.52, 0.052, 0, 1, 0.95), dim: 1.0);
        _paintNode(c, size, const _Node(0.32, 0.44, 0.034, 1, 4, 0.7), dim: 0.9);
        _paintHome(c, size, const Offset(0.80, 0.60), s * 0.075);
        _paintSkyline(c, size, density: 0.6, alpha: 0.7);
        break;
      case MoonJoinOnboardingScene.resolution:
        // Settled + dimmed — the calm after arrival.
        _paintArcs(c, size, _arcs, alpha: 0.18);
        for (final _Node n in _ecosystem) {
          _paintNode(c, size, n, dim: 0.42);
        }
        _paintSkyline(c, size, density: 1.0, alpha: 0.55);
        break;
    }

    // 5) Bottom scrim so overlaid text stays readable (part of the art).
    final Rect scrim = Rect.fromLTRB(0, h * 0.5, w, h);
    c.drawRect(scrim, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, MoonJoinOnboardingPalette.bgTop.withValues(alpha: 0.85)],
      ).createShader(scrim));
  }

  // ── Dynamic layer (per frame) ─────────────────────────────────────────────
  @override
  void paint(Canvas c, Size size) {
    c.drawPicture(staticLayer);

    final double w = size.width, h = size.height;
    final double s = math.min(w, h);
    final Offset moon = Offset(w * _moonFor(scene).dx, h * _moonFor(scene).dy);
    final double mr = s * _moonRadius(scene);

    // Moon breath — a soft moonlight halo that gently swells (~6% ), calm.
    final double breath = 0.5 + 0.5 * math.sin(ambient * 2 * math.pi);
    final double haloR = mr * (2.2 + 0.12 * breath) * (scene == MoonJoinOnboardingScene.resolution ? 1.35 : 1.0);
    c.drawCircle(moon, haloR, Paint()
      ..shader = RadialGradient(
        colors: [
          MoonJoinOnboardingPalette.moonLit.withValues(alpha: (0.14 + 0.05 * breath) * _weight(scene).clamp(0.5, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: moon, radius: haloR)));

    // A single travelling Node of light (ecosystem + delivery only) — the join.
    if (scene == MoonJoinOnboardingScene.ecosystem) {
      final _Arc a = _arcs[(ambient * _arcs.length).floor() % _arcs.length];
      final double local = (ambient * _arcs.length) % 1.0;
      _travellingLight(c, size, a, local, s);
    } else if (scene == MoonJoinOnboardingScene.delivery) {
      _travellingLight(c, size, const _Arc(0.22, 0.52, 0.80, 0.60, -0.16), ambient, s);
    }

    // Drifting organic particles — tiny, few, calm (dust of a living city).
    final int count = (4 + _weight(scene) * 8).round();
    final math.Random rnd = math.Random(31);
    final Paint pp = Paint();
    for (int i = 0; i < count; i++) {
      final double bx = rnd.nextDouble();
      final double by = 0.12 + rnd.nextDouble() * 0.66;
      final double speed = 0.4 + rnd.nextDouble() * 0.8;
      final double drift = ((ambient * speed) + rnd.nextDouble()) % 1.0;
      final double px = (bx + drift * 0.04) * w;
      final double py = (by - drift * 0.05) * h;
      final double tw = 0.4 + 0.6 * math.sin((ambient * speed + i) * 2 * math.pi).abs();
      pp.color = (i.isEven ? MoonJoinOnboardingPalette.warm : MoonJoinOnboardingPalette.green)
          .withValues(alpha: 0.05 + 0.10 * tw);
      c.drawCircle(Offset(px, py), 1.0 + tw * 1.2, pp);
    }
  }

  // ── Drawing helpers ───────────────────────────────────────────────────────
  static double _weight(MoonJoinOnboardingScene s) {
    switch (s) {
      case MoonJoinOnboardingScene.arrival: return 0.20;
      case MoonJoinOnboardingScene.ecosystem: return 1.0;
      case MoonJoinOnboardingScene.delivery: return 0.55;
      case MoonJoinOnboardingScene.resolution: return 0.30;
    }
  }

  static Offset _moonFor(MoonJoinOnboardingScene s) {
    switch (s) {
      case MoonJoinOnboardingScene.arrival: return const Offset(0.62, 0.30);
      case MoonJoinOnboardingScene.ecosystem: return _moonAt;
      case MoonJoinOnboardingScene.delivery: return const Offset(0.5, 0.24);
      case MoonJoinOnboardingScene.resolution: return const Offset(0.5, 0.38);
    }
  }

  static double _moonRadius(MoonJoinOnboardingScene s) {
    switch (s) {
      case MoonJoinOnboardingScene.arrival: return 0.085;
      case MoonJoinOnboardingScene.ecosystem: return 0.11;
      case MoonJoinOnboardingScene.delivery: return 0.075;
      case MoonJoinOnboardingScene.resolution: return 0.16;
    }
  }

  /// Illuminated fraction 0..1 — the moon waxes across the story.
  static double _phase(MoonJoinOnboardingScene s) {
    switch (s) {
      case MoonJoinOnboardingScene.arrival: return 0.18;
      case MoonJoinOnboardingScene.ecosystem: return 0.62;
      case MoonJoinOnboardingScene.delivery: return 0.62;
      case MoonJoinOnboardingScene.resolution: return 1.0;
    }
  }

  static void _paintMoon(Canvas c, Offset center, double r, double phase) {
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    // dark side
    c.drawCircle(center, r, Paint()..color = MoonJoinOnboardingPalette.moonDark);
    // lit side
    if (phase > 0) {
      c.drawCircle(center, r, Paint()..color = MoonJoinOnboardingPalette.moonLit);
      if (phase < 1) {
        final double dx = phase * 2 * r; // shadow bite slides across
        c.drawCircle(Offset(center.dx + dx, center.dy), r, Paint()..color = MoonJoinOnboardingPalette.moonDark);
      }
    }
    // top-left moonlight sheen
    final Rect hi = Rect.fromCircle(center: Offset(center.dx - r * 0.4, center.dy - r * 0.45), radius: r * 1.3);
    c.drawCircle(center, r, Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.0),
      ]).createShader(hi));
    c.restore();
    // a hair-thin lit rim
    c.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.03
      ..color = MoonJoinOnboardingPalette.moonLit.withValues(alpha: 0.25));
  }

  static void _paintArcs(Canvas c, Size size, List<_Arc> arcs, {required double alpha}) {
    final double w = size.width, h = size.height;
    for (final _Arc a in arcs) {
      final Offset p1 = Offset(a.ax * w, a.ay * h);
      final Offset p2 = Offset(a.bx * w, a.by * h);
      final Offset mid = Offset((p1.dx + p2.dx) / 2 + (p2.dy - p1.dy) * a.bend,
          (p1.dy + p2.dy) / 2 - (p2.dx - p1.dx) * a.bend);
      final Path path = Path()..moveTo(p1.dx, p1.dy)..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
      c.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.004).clamp(1.0, 2.4)
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [
          MoonJoinOnboardingPalette.green.withValues(alpha: alpha * 0.06),
          MoonJoinOnboardingPalette.green.withValues(alpha: alpha * 0.35),
          MoonJoinOnboardingPalette.green.withValues(alpha: alpha * 0.06),
        ]).createShader(Rect.fromPoints(p1, p2)));
    }
  }

  static void _paintNode(Canvas c, Size size, _Node n, {required double dim}) {
    final double w = size.width, h = size.height, s = math.min(w, h);
    final Offset ctr = Offset(n.x * w, n.y * h);
    final double r = n.r * s;
    final Color accent = MoonJoinOnboardingPalette.accents[n.accent % MoonJoinOnboardingPalette.accents.length];
    final double front = 0.35 + n.depth * 0.65;
    final double a = front * dim;

    // soft glow
    c.drawCircle(ctr, r * 2.2, Paint()
      ..shader = RadialGradient(colors: [accent.withValues(alpha: 0.16 * a), Colors.transparent])
          .createShader(Rect.fromCircle(center: ctr, radius: r * 2.2)));

    // organic blob body (the OrganicModuleIcon curve family)
    final Path blob = _blob(n.shape, ctr, r);
    c.drawPath(blob, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [Color.lerp(accent, Colors.white, 0.35)!.withValues(alpha: a), accent.withValues(alpha: 0.85 * a)],
      ).createShader(Rect.fromCircle(center: ctr, radius: r)));
    // thin moonlit ring
    c.drawPath(blob, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.10).clamp(1.0, 3.0)
      ..color = MoonJoinOnboardingPalette.moonLit.withValues(alpha: 0.18 * a));
    // tiny warm core light (a "window" — life inside)
    c.drawCircle(Offset(ctr.dx - r * 0.15, ctr.dy - r * 0.15), r * 0.16,
        Paint()..color = MoonJoinOnboardingPalette.warm.withValues(alpha: 0.5 * a));
  }

  static void _paintHome(Canvas c, Size size, Offset at, double r) {
    final double w = size.width, h = size.height;
    final Offset ctr = Offset(at.dx * w, at.dy * h);
    // organic rounded home silhouette with a warm window.
    final Path body = _blob(2, ctr, r);
    c.drawCircle(ctr, r * 2.0, Paint()
      ..shader = RadialGradient(colors: [MoonJoinOnboardingPalette.warm.withValues(alpha: 0.18), Colors.transparent])
          .createShader(Rect.fromCircle(center: ctr, radius: r * 2.0)));
    c.drawPath(body, Paint()..color = MoonJoinOnboardingPalette.bgHorizon);
    c.drawPath(body, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = r * 0.10
      ..color = MoonJoinOnboardingPalette.moonLit.withValues(alpha: 0.20));
    c.drawCircle(ctr, r * 0.28, Paint()..color = MoonJoinOnboardingPalette.warm.withValues(alpha: 0.85));
  }

  static void _paintSkyline(Canvas c, Size size, {required double density, required double alpha}) {
    final double w = size.width, h = size.height;
    final double base = h * 0.86;
    final math.Random rnd = math.Random(13);
    final int count = (10 * density).round().clamp(4, 14);
    final double slot = w / count;
    for (int i = 0; i < count; i++) {
      final double bw = slot * (0.5 + rnd.nextDouble() * 0.4);
      final double bh = h * (0.05 + rnd.nextDouble() * 0.10) * (0.6 + density * 0.6);
      final double bx = i * slot + (slot - bw) / 2;
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, base - bh, bw, bh + h * 0.16),
        Radius.circular(bw * 0.28),
      );
      c.drawRRect(r, Paint()..color = MoonJoinOnboardingPalette.bgTop.withValues(alpha: 0.55 * alpha));
      c.drawRRect(r, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 1.0
        ..color = MoonJoinOnboardingPalette.green.withValues(alpha: 0.10 * alpha));
      // warm windows
      final int win = (bh / (h * 0.03)).floor();
      for (int k = 0; k < win; k++) {
        if (rnd.nextDouble() < 0.5) continue;
        final double wx = bx + bw * (0.3 + rnd.nextDouble() * 0.4);
        final double wy = base - bh + h * 0.02 + k * h * 0.028;
        c.drawCircle(Offset(wx, wy), 1.3,
            Paint()..color = MoonJoinOnboardingPalette.warm.withValues(alpha: 0.5 * alpha));
      }
    }
  }

  void _travellingLight(Canvas c, Size size, _Arc a, double t, double s) {
    final double w = size.width, h = size.height;
    final Offset p1 = Offset(a.ax * w, a.ay * h);
    final Offset p2 = Offset(a.bx * w, a.by * h);
    final Offset mid = Offset((p1.dx + p2.dx) / 2 + (p2.dy - p1.dy) * a.bend,
        (p1.dy + p2.dy) / 2 - (p2.dx - p1.dx) * a.bend);
    // quadratic bezier point at t
    final double u = 1 - t;
    final Offset pos = Offset(
      u * u * p1.dx + 2 * u * t * mid.dx + t * t * p2.dx,
      u * u * p1.dy + 2 * u * t * mid.dy + t * t * p2.dy,
    );
    final double fade = math.sin(t * math.pi); // fade in/out across the arc
    if (fade <= 0.02) return;
    final double gr = s * 0.05;
    c.drawCircle(pos, gr, Paint()
      ..shader = RadialGradient(colors: [
        MoonJoinOnboardingPalette.moonLit.withValues(alpha: 0.9 * fade), Colors.transparent,
      ]).createShader(Rect.fromCircle(center: pos, radius: gr)));
    c.drawCircle(pos, s * 0.008, Paint()..color = MoonJoinOnboardingPalette.moonLit.withValues(alpha: fade));
  }

  // Organic blob path — same "amoeba" curve family as OrganicModuleIcon.
  static Path _blob(int seed, Offset center, double radius) {
    const int n = 26;
    final double f1 = 2 + (seed % 2).toDouble();
    final double f2 = 3 + ((seed + 1) % 2).toDouble();
    final double p1 = seed * 0.9, p2 = seed * 1.7 + 1.1;
    final List<Offset> pts = List.generate(n, (k) {
      final double ang = 2 * math.pi * k / n;
      final double rr = radius * (1 + 0.05 * math.sin(f1 * ang + p1) + 0.024 * math.sin(f2 * ang + p2));
      return Offset(center.dx + math.cos(ang) * rr, center.dy + math.sin(ang) * rr);
    });
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final Path path = Path();
    final Offset start = mid(pts[n - 1], pts[0]);
    path.moveTo(start.dx, start.dy);
    for (int i = 0; i < n; i++) {
      final Offset cur = pts[i];
      final Offset m = mid(cur, pts[(i + 1) % n]);
      path.quadraticBezierTo(cur.dx, cur.dy, m.dx, m.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant MoonJoinOnboardingPainter old) =>
      old.ambient != ambient || old.scene != scene || old.staticLayer != staticLayer;
}
