import 'package:moonjoin/features/rental_module/home/domain/models/vehicle_category_model.dart';
import 'package:moonjoin/features/rental_module/vendor/domain/models/vendor_vehicle_category_model.dart' as vendor_models;
import 'dart:convert';

import 'package:moonjoin/features/rental_module/home/domain/models/taxi_banner_model.dart';
import 'package:moonjoin/features/rental_module/home/domain/models/vehicle_details_model.dart';

/// **Apartment Adapter (Temporary Production Adapter)** — same philosophy as
/// [RentalProviderAdapter]: derive the apartment view from REAL backend data.
///
/// The live Rental backend has NO apartment-specific endpoints, but it already
/// models apartments as rental inventory: `category-list` contains the real
/// **"Short Apt Rental"** category and every inventory item carries `category_id`.
/// This adapter (1) resolves that real category from the live category list and
/// (2) filters the real browse feed to items that belong to it.
///
/// **Nothing is fabricated.** If the backend has no apartment category or no
/// apartment inventory, the result is empty and the screen shows the honest empty
/// state. Car Rental data is never converted into apartment data.
///
/// Known limitation (documented in docs/BACKEND_INTEGRATION_QUEUE.md items 5/7/8/13):
/// the category is matched by its real name because the backend has no category
/// `type` field yet, and browse filtering is client-side because the browse API has
/// no category parameter. When those ship, ONLY this adapter changes.
/// Which Rental section a surface belongs to. The Main Rental Home is `all`
/// (Car + Short Apt content together — product-owner rule); each dedicated
/// listing shows only its own section's content.
enum RentalSection { all, car, apartment }

class RentalApartmentAdapter {
  const RentalApartmentAdapter._();

  /// Resolves the real Short-Apartment category id from the LIVE category list.
  /// Returns null when the backend exposes no such category (→ honest empty state).
  static int? apartmentCategoryId(VehicleCategoryModel? categoryModel) {
    final categories = categoryModel?.vehicles;
    if (categories == null) return null;
    for (final c in categories) {
      final String name = (c.name ?? '').toLowerCase();
      if (name.contains('apartment') || name.contains('apt')) return c.id;
    }
    return null;
  }

  /// Keeps only REAL inventory belonging to the apartment category.
  static List<VehicleModel> filterApartments(List<VehicleModel>? vehicles, int? aptCategoryId) {
    if (vehicles == null || aptCategoryId == null) return const [];
    return vehicles.where((v) => v.categoryId == aptCategoryId).toList();
  }

  /// Section split of the REAL category list. The backend has no category `type`
  /// yet (queue items 7/13/18), so classification uses the same real-name
  /// resolution as [apartmentCategoryId]: apartment-matched names are the Short
  /// Apt section; every other REAL rental category belongs to the Car section.
  /// Nothing is invented — both lists are subsets of the live backend list.
  static List<Vehicles> sectionCategories(VehicleCategoryModel? categoryModel, RentalSection section) {
    final categories = categoryModel?.vehicles ?? const <Vehicles>[];
    if (section == RentalSection.all) return categories;
    bool isApt(Vehicles c) {
      final String name = (c.name ?? '').toLowerCase();
      return name.contains('apartment') || name.contains('apt');
    }
    return section == RentalSection.apartment
        ? categories.where(isApt).toList()
        : categories.where((c) => !isApt(c)).toList();
  }

  /// Section filter for the REAL rental banners. The backend has no banner
  /// classification (queue item 18); the only real signal is a banner's
  /// `provider_id` → that provider's REAL loaded inventory decides its section
  /// (via [isApartmentProvider]). External-link banners (`type: 'default'`) and
  /// providers absent from the loaded feed carry NO signal → UNCLASSIFIED:
  /// kept on the Car listing (today's module content is car-oriented) and
  /// excluded from the Apartment listing (never shown as apartment content
  /// without a real signal). When the backend adds classification, ONLY this
  /// method changes.
  static List<Banners> filterBanners(List<Banners>? banners,
      {required RentalSection section, List<VehicleModel>? loadedInventory, int? aptCategoryId}) {
    if (banners == null) return const [];
    if (section == RentalSection.all) return banners;

    bool isApartmentBanner(Banners b) {
      if (b.providerId == null || loadedInventory == null || aptCategoryId == null) return false;
      final providerItems = loadedInventory.where((v) => (v.provider?.id ?? v.providerId) == b.providerId).toList();
      if (providerItems.isEmpty) return false; // no signal → not apartment
      return isApartmentProvider(providerItems, aptCategoryId);
    }

    return section == RentalSection.apartment
        ? banners.where(isApartmentBanner).toList()
        : banners.where((b) => !isApartmentBanner(b)).toList();
  }

  /// Same real-category resolution for the Provider page's category list
  /// (`VehiclesCategory` from the vendor model; the controller prepends an "All"
  /// entry with id -1, which never matches).
  static int? apartmentCategoryIdFromVendorList(List<vendor_models.VehiclesCategory>? categories) {
    if (categories == null) return null;
    for (final c in categories) {
      final String name = (c.name ?? '').toLowerCase();
      if (name.contains('apartment') || name.contains('apt')) return c.id;
    }
    return null;
  }

  /// Parses the REAL provider-entered `tag` value (stringified JSON array, e.g.
  /// `["Wi-Fi","Pool"]`) into clean tokens for the Amenities grid — the same
  /// parsing the provider-card badges use. Empty when the backend sent none.
  static List<String> amenityTags(String? rawTag) {
    final String value = rawTag?.trim() ?? '';
    if (value.isEmpty) return const [];
    if (value.startsWith('[')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {/* fall through */}
    }
    return value.replaceAll(RegExp(r'[\[\]"]'), '').split(',')
        .map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// True when the provider's REAL loaded inventory contains apartment items —
  /// drives the auto-activating apartment wording on the shared Provider page
  /// (no manual flag: it switches by itself the moment real apartment data
  /// exists, and never activates for car providers).
  static bool isApartmentProvider(List<VehicleModel>? vehicles, int? aptCategoryId) {
    if (vehicles == null || vehicles.isEmpty || aptCategoryId == null) return false;
    final int aptCount = vehicles.where((v) => v.categoryId == aptCategoryId).length;
    // Predominantly apartments → apartment presentation.
    return aptCount * 2 > vehicles.length;
  }
}
