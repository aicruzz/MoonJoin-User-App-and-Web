import 'package:get/get.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';

/// MoonJoin **Delivery Man Tip configuration resolver**.
///
/// Tips are a MoonJoin backend/admin-owned configuration; Flutter is a pure
/// consumer. This resolver produces the ordered tip amounts using the MoonJoin
/// priority chain:
///
///   Zone override  →  Global default (Business Settings)  →  Temporary fallback
///
/// - **Zone override** (`zone.dmTips` + zone currency): a documented BACKEND
///   DEPENDENCY — no zone-tip / zone-currency model exists in the payload yet, so
///   this tier is a prepared seam (see the commented block below), not active.
/// - **Global default** (`configModel.dmDefaultTips`, key `dm_default_tips`): a
///   prepared BACKEND DEPENDENCY — consumed the moment MoonJoin Admin "Delivery
///   Tip Settings" starts sending it; null until then.
/// - **Temporary fallback**: a migration-only default. **NOT a permanent
///   constant** — it exists solely so the UI renders until the backend ships tip
///   configuration, and must be removed once `dm_default_tips` is delivered.
///
/// Currency is intentionally NOT handled here — amounts are plain integers and
/// are formatted by `PriceConverter`, which already follows the configured
/// (global today; zone-aware in future) currency. No hardcoded currency symbol.
class DeliveryManTipsConfig {
  DeliveryManTipsConfig._();

  /// TEMPORARY migration fallback — replaced by backend `dm_default_tips` (global)
  /// or zone tips when available. Do NOT treat as a final hardcoded constant.
  static const List<int> migrationFallbackTips = <int>[100, 200, 300, 400];

  /// Ordered tip amounts, resolved by MoonJoin priority (zone → global → fallback).
  static List<int> resolveAmounts() {
    // ── Zone override (BACKEND DEPENDENCY — not yet in payload) ────────────────
    // final zone = <resolved order/zone>;
    // if (zone?.dmTips != null && zone!.dmTips!.isNotEmpty) return zone.dmTips!;

    // ── Global default (Business Settings) ────────────────────────────────────
    final List<int>? global = Get.find<SplashController>().configModel?.dmDefaultTips;
    if (global != null && global.isNotEmpty) return global;

    // ── Temporary migration fallback ──────────────────────────────────────────
    return migrationFallbackTips;
  }

  /// The full option list consumed by the tip UI (and, via `AppConstants.tips`,
  /// by the tip controllers): `['0', ...amounts, 'custom']`. Keeping the leading
  /// `'0'` (Not Now) and trailing `'custom'` preserves the existing index
  /// contract used by `CheckoutController`/`ParcelController` (custom == last).
  static List<String> options() =>
      <String>['0', ...resolveAmounts().map((int e) => e.toString()), 'custom'];
}
