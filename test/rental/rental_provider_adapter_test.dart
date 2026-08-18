import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:moonjoin/features/rental_module/provider_adapter/rental_provider_adapter.dart';

/// Regression test for the Screen 2 provider-card **badge formatting** fix.
///
/// The backend `tag` field is a stringified JSON array (`["Lexus"]`). The provider
/// card previously rendered the raw string as a badge — `["lexus"]` — which is not
/// production quality. The adapter now parses it into clean, title-cased tokens.
/// This is a presentation-only fix: the backend model and the adapter architecture
/// (group real vehicles by `provider.id`) are unchanged.
VehicleModel _vehicle({
  int providerId = 39,
  String? tag,
  bool airCondition = true,
  String fuelType = 'petrol',
  String transmissionType = 'automatic',
  String type = 'luxury',
  String seatingCapacity = '5',
}) {
  return VehicleModel(
    id: 1,
    providerId: providerId,
    provider: Provider(id: providerId, name: 'Peeprate Car Rental'),
    tag: tag,
    airCondition: airCondition,
    fuelType: fuelType,
    transmissionType: transmissionType,
    type: type,
    seatingCapacity: seatingCapacity,
  );
}

void main() {
  group('RentalProviderAdapter tag badge formatting', () {
    test('parses a single-element JSON-array tag into a clean title-cased badge', () {
      final providers = RentalProviderAdapter.fromVehicles([_vehicle(tag: '["Lexus"]')]);

      expect(providers, hasLength(1));
      expect(providers.first.featureBadges, contains('Lexus'));
      // The raw, unformatted form must never appear.
      expect(providers.first.featureBadges.any((b) => b.contains('[') || b.contains(']') || b.contains('"')), isFalse);
    });

    test('parses a multi-element JSON-array tag into separate badges', () {
      final providers = RentalProviderAdapter.fromVehicles([_vehicle(tag: '["Luxury","Premium"]')]);

      expect(providers.first.featureBadges, containsAll(<String>['Luxury', 'Premium']));
    });

    test('handles a plain (non-JSON) tag string', () {
      final providers = RentalProviderAdapter.fromVehicles([_vehicle(tag: 'SUV')]);

      // `_titleCase('SUV')` → 'Suv'; the point is it is clean, never bracketed.
      expect(providers.first.featureBadges, contains('Suv'));
      expect(providers.first.featureBadges.any((b) => b.contains('[')), isFalse);
    });

    test('empty / null tag contributes no tag badge but keeps other real badges', () {
      final providers = RentalProviderAdapter.fromVehicles([_vehicle(tag: null)]);

      final badges = providers.first.featureBadges;
      expect(badges, contains('AC'));
      expect(badges, contains('Petrol'));
      expect(badges, contains('Automatic'));
      expect(badges, contains('5 Seats'));
      expect(badges.any((b) => b.contains('[')), isFalse);
    });
  });
}
