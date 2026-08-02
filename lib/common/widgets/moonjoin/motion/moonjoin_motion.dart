import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// MoonJoin Motion & Status Design Language — model, mapping & theming
/// ─────────────────────────────────────────────────────────────────────────────
///
/// The official MoonJoin motion identity (a permanent design system alongside the
/// Commerce Header, Commerce Action Bar, Cards and Buttons).
///
/// Concept: **an order is a moon.** It *waxes* from a dark new moon to a full moon
/// as it travels to you. The recurring join is a single point of light — the
/// **Node** — that traces the moon's lit rim and settles. Status is a *phase*,
/// never a spinner. 100% Flutter-native — no Lottie, no GIF.
///
/// Motion reveals the state; it never demands attention:
///   Node appears → Arc-Light travels the rim → Moon resolves → Calm settle.

/// The canonical MoonJoin status set (order · payment · wallet · verification · …).
enum MoonJoinMotionState {
  pending, confirmed, accepted, preparing, handover, onTheWay, delivered,
  cancelled, unavailable, attention, failed, refunded,
  paymentSuccess, paymentFailed, walletSuccess, walletFailed,
  verification, kyc, reward, promotion,
}

/// Colour tone that selects the moon's lit hue.
enum MoonJoinMotionTone { brand, neutral, negative }

/// Where the settled Node rests.
enum MoonNode { rim, terminator, center, tip, below, off, none }

/// The single allowed ongoing motion, for genuinely-active states only.
enum MoonAmbient { none, forming, drift }

/// The full visual spec for a state — the "how the moon is drawn" struct. Mirrors
/// the approved MoonJoin visual reference exactly.
class MoonJoinMoonSpec {
  final double p;            // illuminated phase 0..1 (more light = closer to you)
  final MoonJoinMotionTone tone;
  final double tilt;         // degrees (travelling / beacon states)
  final MoonNode node;
  final MoonAmbient ambient;
  final bool forming;        // preparing: inner "being made" arcs
  final bool trail;          // on the way: motion light-trail
  final bool glow;           // delivered / success: soft outer glow ring
  final bool eclipse;        // unavailable: amber shadow bite
  final bool badge;          // unavailable: approved red "!" badge
  final bool brk;            // failed: broken orbit + red accent
  final bool guard;          // verification: protective outer arc
  final bool star;           // reward: node blooms into the MoonJoin star
  final bool beacon;         // promotion: directional light sweep
  final bool sealCore;       // payment success: sealed node ring
  const MoonJoinMoonSpec({
    required this.p,
    this.tone = MoonJoinMotionTone.brand,
    this.tilt = 0,
    this.node = MoonNode.none,
    this.ambient = MoonAmbient.none,
    this.forming = false,
    this.trail = false,
    this.glow = false,
    this.eclipse = false,
    this.badge = false,
    this.brk = false,
    this.guard = false,
    this.star = false,
    this.beacon = false,
    this.sealCore = false,
  });
}

class MoonJoinMotion {
  const MoonJoinMotion._();

  static MoonJoinMoonSpec spec(MoonJoinMotionState s) {
    switch (s) {
      // ── The journey: a waxing moon ──────────────────────────────────────────
      case MoonJoinMotionState.pending:
        return const MoonJoinMoonSpec(p: 0.12, node: MoonNode.rim);
      case MoonJoinMotionState.accepted:
        return const MoonJoinMoonSpec(p: 0.30, node: MoonNode.rim);
      case MoonJoinMotionState.confirmed:
        return const MoonJoinMoonSpec(p: 0.50, node: MoonNode.terminator);
      case MoonJoinMotionState.preparing:
        return const MoonJoinMoonSpec(p: 0.66, forming: true, ambient: MoonAmbient.forming);
      case MoonJoinMotionState.handover:
      case MoonJoinMotionState.onTheWay:
        return const MoonJoinMoonSpec(p: 0.58, tilt: -16, trail: true, node: MoonNode.tip, ambient: MoonAmbient.drift);
      case MoonJoinMotionState.delivered:
        return const MoonJoinMoonSpec(p: 1.0, node: MoonNode.center, glow: true);

      // ── Extended states ─────────────────────────────────────────────────────
      case MoonJoinMotionState.unavailable:
      case MoonJoinMotionState.attention:
        return const MoonJoinMoonSpec(p: 0.9, eclipse: true, badge: true);
      case MoonJoinMotionState.cancelled:
        return const MoonJoinMoonSpec(p: 0.22, tone: MoonJoinMotionTone.neutral, node: MoonNode.below);
      case MoonJoinMotionState.failed:
        return const MoonJoinMoonSpec(p: 0.5, tone: MoonJoinMotionTone.negative, brk: true, node: MoonNode.off);
      case MoonJoinMotionState.paymentSuccess:
      case MoonJoinMotionState.walletSuccess:
        return const MoonJoinMoonSpec(p: 1.0, node: MoonNode.center, sealCore: true, glow: true);
      case MoonJoinMotionState.paymentFailed:
      case MoonJoinMotionState.walletFailed:
        return const MoonJoinMoonSpec(p: 0.6, tone: MoonJoinMotionTone.negative, brk: true, node: MoonNode.off);
      case MoonJoinMotionState.verification:
      case MoonJoinMotionState.kyc:
        return const MoonJoinMoonSpec(p: 0.8, guard: true, node: MoonNode.center);
      case MoonJoinMotionState.reward:
        return const MoonJoinMoonSpec(p: 1.0, node: MoonNode.center, star: true, glow: true);
      case MoonJoinMotionState.promotion:
        return const MoonJoinMoonSpec(p: 0.5, tilt: -12, beacon: true, node: MoonNode.tip);
      case MoonJoinMotionState.refunded:
        return const MoonJoinMoonSpec(p: 0.85, tone: MoonJoinMotionTone.neutral, node: MoonNode.terminator);
    }
  }

  static bool isAmbient(MoonJoinMotionState s) => spec(s).ambient != MoonAmbient.none;

  /// Centralized backend order-status → motion state (was inlined in the popup).
  static MoonJoinMotionState forOrderStatus(String? status) {
    switch (status) {
      case 'pending': return MoonJoinMotionState.pending;
      case 'confirmed': return MoonJoinMotionState.confirmed;
      case 'accepted': return MoonJoinMotionState.accepted;
      case 'processing': return MoonJoinMotionState.preparing;
      case 'handover': return MoonJoinMotionState.handover;
      case 'picked_up': return MoonJoinMotionState.onTheWay;
      case 'delivered': return MoonJoinMotionState.delivered;
      case 'canceled':
      case 'cancelled': return MoonJoinMotionState.cancelled;
      case 'failed': return MoonJoinMotionState.failed;
      case 'refunded':
      case 'refund_requested':
      case 'refund_request_canceled': return MoonJoinMotionState.refunded;
      default: return MoonJoinMotionState.pending;
    }
  }
}

/// The MoonJoin motion palette — moonlight (theme green) on graphite, plus the
/// APPROVED All-Modules-Home unavailable palette (amber `#C98B3E`, red `#E84D4F`),
/// reused exactly. Light/dark aware: the moon's dark side inverts to light-graphite.
class MoonJoinMotionPalette {
  final Color green, rim, graphite, muted, mutedLit, amber, red, hi;
  const MoonJoinMotionPalette({
    required this.green, required this.rim, required this.graphite,
    required this.muted, required this.mutedLit, required this.amber,
    required this.red, required this.hi,
  });

  static const Color amberToken = Color(0xFFC98B3E);
  static const Color redToken = Color(0xFFE84D4F);

  static MoonJoinMotionPalette of(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color green = Theme.of(context).primaryColor;
    return MoonJoinMotionPalette(
      green: green,
      rim: Color.lerp(green, Colors.white, dark ? 0.45 : 0.30)!,
      graphite: dark ? const Color(0xFF333B37) : const Color(0xFFD6DED8),
      muted: dark ? const Color(0xFF5F6E66) : const Color(0xFFAEB8B2),
      mutedLit: dark ? const Color(0xFF3E4A44) : const Color(0xFFC4CCC6),
      amber: amberToken,
      red: redToken,
      hi: Colors.white.withValues(alpha: dark ? 0.16 : 0.50),
    );
  }

  Color litFor(MoonJoinMotionTone tone) {
    switch (tone) {
      case MoonJoinMotionTone.neutral: return muted;
      case MoonJoinMotionTone.negative: return mutedLit;
      case MoonJoinMotionTone.brand: return green;
    }
  }
}
