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

/// Resolves a module's availability. Placeholder that returns [enabled] for
/// every module until the Admin availability field exists on the backend; the
/// single place to wire it later (e.g. `module.availabilityStatus`), keeping the
/// Home UI already fully capable of all three states.
ModuleAvailability resolveModuleAvailability(dynamic module) {
  return ModuleAvailability.enabled;
}
