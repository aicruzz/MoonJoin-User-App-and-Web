import 'package:get/get.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/util/app_constants.dart';

/// THE single source of module-aware provider terminology for customer-facing
/// headers (reuse-only — no per-screen hardcoding).
///
/// Priority: the future backend field `module.providerLabelPlural`
/// (`provider_label_plural`) always wins; otherwise a deterministic fallback by
/// module type + backend module name. Parcel & Rental keep their own correct
/// headers and never call this.
class ModuleTerminology {
  ModuleTerminology._();

  /// Plural provider label — e.g. "Restaurants", "Grocery Stores", "Pharmacies",
  /// "Fashion Stores", "Markets", "Fuel Stations".
  static String providerLabelPlural(ModuleModel? module) {
    final String? backend = module?.providerLabelPlural;
    if (backend != null && backend.trim().isNotEmpty) return backend.trim();

    final String type = (module?.moduleType ?? '').toLowerCase();
    final String name = (module?.moduleName ?? '').trim();
    final String nameLower = name.toLowerCase();
    // "{Module name} Stores" (backend-driven), e.g. Grocery → "Grocery Stores",
    // Fashion → "Fashion Stores". Falls back to plain "Stores" when name is empty.
    final String nameStores = name.isNotEmpty ? '$name ${'stores'.tr}' : 'stores'.tr;

    switch (type) {
      case AppConstants.food:
        return 'restaurants'.tr;
      case AppConstants.pharmacy:
        return 'pharmacies'.tr;
      case AppConstants.ecommerce:
        return nameStores;
      case AppConstants.grocery:
        if (nameLower.contains('market')) return 'markets'.tr;
        if (nameLower.contains('fuel') || nameLower.contains('gas')) return 'fuel_stations'.tr;
        if (nameLower.contains('drink')) return 'drink_distributors'.tr;
        return nameStores;
      default:
        return nameStores;
    }
  }

  /// "New {label} on {AppName}" — the "new on" section header
  /// (e.g. "New Restaurants on MoonJoin").
  static String newOnHeader(ModuleModel? module) =>
      '${'header_new'.tr} ${providerLabelPlural(module)} ${'header_on'.tr} ${AppConstants.appName}';
}
