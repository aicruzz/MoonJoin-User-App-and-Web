/// Availability state of a MoonJoin module on the Home screen.
///
/// This is **architecture only** — the `unavailable` state is not wired to any
/// backend field yet. The future Admin → Settings → System Module Setup will
/// drive it. No temporary APIs and no changes to existing endpoints/logic:
/// today every module resolves to [enabled] (and admin-disabled modules are
/// already omitted from the module list by the backend, i.e. [disabled]).
enum ModuleAvailability {
  /// Visible and fully interactive (current default for every returned module).
  enabled,

  /// Visible but not openable — reserved for Coming Soon / Maintenance /
  /// Temporarily unavailable / Region unavailable / Future rollout /
  /// Admin-controlled availability. Rendered dimmed + desaturated, tap disabled,
  /// with no layout shift. Not connected to a backend field yet.
  unavailable,

  /// Hidden completely — the current backend behaviour (a module disabled from
  /// Admin is simply not present in the module list, so it never renders).
  disabled,
}

/// Resolves a module's availability from its REAL schedule (Glovo-style). The
/// single wiring point for the future Admin → Module Schedule backend. It reads
/// only the adapter fields on [ModuleModel] (`temporaryClose`, `holidayToday`,
/// `openTime`/`closeTime`) — all NULL today, so every module resolves to
/// [enabled] and nothing changes until the backend ships those fields. NEVER
/// hardcodes a time and NEVER invents a schedule: absent data ⇒ available.
///
/// When the backend sends data: a module is [unavailable] (faded, tap disabled,
/// no popup, still visible) if it is temporarily closed, on a holiday override,
/// or the current local time is outside its `open_time`–`close_time` window.
/// See docs/BACKEND_INTEGRATION_QUEUE.md item 19.
ModuleAvailability resolveModuleAvailability(dynamic module) {
  final String? open = _readString(module, (m) => m.openTime);
  final String? close = _readString(module, (m) => m.closeTime);
  final bool tempClose = _readBool(module, (m) => m.temporaryClose);
  final bool holiday = _readBool(module, (m) => m.holidayToday);

  if (tempClose || holiday) return ModuleAvailability.unavailable;

  // No real window configured → available (no fabricated schedule).
  if (open == null || open.isEmpty || close == null || close.isEmpty) {
    return ModuleAvailability.enabled;
  }

  final _Minutes? openM = _parseHm(open);
  final _Minutes? closeM = _parseHm(close);
  if (openM == null || closeM == null) return ModuleAvailability.enabled;

  final DateTime now = DateTime.now();
  final int nowM = now.hour * 60 + now.minute;

  // Supports normal (open < close) and overnight (open > close) windows.
  final bool withinWindow = openM.value <= closeM.value
      ? (nowM >= openM.value && nowM < closeM.value)
      : (nowM >= openM.value || nowM < closeM.value);

  return withinWindow ? ModuleAvailability.enabled : ModuleAvailability.unavailable;
}

class _Minutes { final int value; const _Minutes(this.value); }

_Minutes? _parseHm(String hm) {
  final parts = hm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return _Minutes(h * 60 + m);
}

/// Reads a nullable String field defensively (works for any ModuleModel-shaped
/// object without importing it here, keeping this file dependency-free).
String? _readString(dynamic module, String? Function(dynamic) get) {
  try { return get(module); } catch (_) { return null; }
}

bool _readBool(dynamic module, bool? Function(dynamic) get) {
  try { return get(module) ?? false; } catch (_) { return false; }
}
