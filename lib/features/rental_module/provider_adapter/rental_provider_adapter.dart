import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';

/// **Rental Provider Adapter (Temporary Production Adapter)**
///
/// The Rental backend has **no provider list endpoint** — every provider API
/// (`get-provider-details`, provider banners, `get-provider-vehicles`, reviews)
/// requires a provider id that is already known. However, every vehicle returned by
/// the existing vehicle APIs embeds a **real backend `Provider` object**
/// (id / name / logo / cover photo / avg rating / rating count / discount).
///
/// So this adapter derives the provider list from real backend data:
///
/// ```
/// TODAY   Vehicle API → group by provider.id → RentalProviderCard
/// FUTURE  Provider List API →                  RentalProviderCard
/// ```
///
/// **Nothing here is fabricated.** Every value comes from the backend response.
///
/// Known limitation (documented in docs/BACKEND_INTEGRATION_QUEUE.md): the derived
/// list only contains providers that have a vehicle in the currently loaded page, so
/// it is not a complete provider directory and paginates by vehicles, not providers.
///
/// When the Provider List endpoint ships, replace ONLY this adapter — the
/// `RentalProviderCard` UI must not change.
class RentalProvider {
  final int id;
  final String name;
  final String? logoFullUrl;
  final String? coverPhotoFullUrl;
  final double? avgRating;
  final int? ratingCount;
  final Discount? discount;

  /// Feature badges aggregated from this provider's real vehicles (AC, Luxury,
  /// Petrol, Automatic, SUV, 5 Seats, …). Never hardcoded — only values the backend
  /// actually returned appear here.
  final List<String> featureBadges;

  /// How many of the loaded vehicles belong to this provider.
  final int vehicleCount;

  const RentalProvider({
    required this.id,
    required this.name,
    this.logoFullUrl,
    this.coverPhotoFullUrl,
    this.avgRating,
    this.ratingCount,
    this.discount,
    this.featureBadges = const [],
    this.vehicleCount = 0,
  });
}

/// Derives [RentalProvider]s from real backend vehicles.
class RentalProviderAdapter {
  const RentalProviderAdapter._();

  /// Groups [vehicles] by their embedded `provider.id`, preserving backend order,
  /// and aggregates each provider's feature badges from its own vehicles.
  static List<RentalProvider> fromVehicles(List<VehicleModel>? vehicles) {
    if (vehicles == null || vehicles.isEmpty) return const [];

    final Map<int, Provider> providers = {};
    final Map<int, List<VehicleModel>> grouped = {};
    final List<int> order = [];

    for (final v in vehicles) {
      final Provider? p = v.provider;
      final int? id = p?.id ?? v.providerId;
      if (p == null || id == null) continue;
      if (!grouped.containsKey(id)) {
        grouped[id] = [];
        providers[id] = p;
        order.add(id);
      }
      grouped[id]!.add(v);
    }

    return order.map((id) {
      final Provider p = providers[id]!;
      final List<VehicleModel> own = grouped[id]!;
      return RentalProvider(
        id: id,
        name: p.name ?? '',
        logoFullUrl: p.logoFullUrl,
        // Cover mapping, real backend fields only: the vendor-uploaded cover photo,
        // falling back to the provider's meta image when the cover is absent. Nothing
        // is fabricated — if the backend supplies neither, the card shows its neutral
        // placeholder and the gap is documented as Vendor App banner-upload work.
        coverPhotoFullUrl: (p.coverPhotoFullUrl != null && p.coverPhotoFullUrl!.isNotEmpty)
            ? p.coverPhotoFullUrl
            : ((p.metaImageFullUrl != null && p.metaImageFullUrl!.isNotEmpty) ? p.metaImageFullUrl : null),
        avgRating: p.avgRating,
        ratingCount: p.ratingCount,
        discount: p.discount,
        featureBadges: _badgesFor(own),
        vehicleCount: own.length,
      );
    }).toList();
  }

  /// Builds the badge list from REAL vehicle fields only. A badge appears solely
  /// because the backend returned that value — nothing is assumed or invented.
  /// Order is stable so the row does not reshuffle between rebuilds.
  static List<String> _badgesFor(List<VehicleModel> vehicles) {
    final Set<String> badges = <String>{};

    for (final v in vehicles) {
      if (v.airCondition == true) badges.add('AC');

      final String? tag = v.tag?.trim();
      if (tag != null && tag.isNotEmpty) badges.add(_titleCase(tag));

      final String? fuel = v.fuelType?.trim();
      if (fuel != null && fuel.isNotEmpty) badges.add(_titleCase(fuel));

      final String? transmission = v.transmissionType?.trim();
      if (transmission != null && transmission.isNotEmpty) badges.add(_titleCase(transmission));

      final String? type = v.type?.trim();
      if (type != null && type.isNotEmpty) badges.add(_vehicleType(type));

      final String? seats = v.seatingCapacity?.trim();
      if (seats != null && seats.isNotEmpty) badges.add('$seats Seats');
    }

    return badges.toList();
  }

  /// Keeps well-known vehicle types in their conventional casing (SUV, MPV) and
  /// title-cases the rest (Sedan, Coupe, Convertible, Pickup).
  static String _vehicleType(String value) {
    const Set<String> upper = {'suv', 'mpv', 'suv/mpv'};
    return upper.contains(value.toLowerCase()) ? value.toUpperCase() : _titleCase(value);
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[\s_]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
