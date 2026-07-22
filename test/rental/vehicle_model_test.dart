import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';

/// Regression test for the **Vehicle Details** parse crash.
///
/// `GET /api/v1/rental/vehicle/get-vehicle-details/{id}` serialises `total_vehicles`
/// as a **string** (`"total_vehicles": "1"`) while the list endpoints send integers.
/// `VehicleModel` types it `int?`, so the raw assignment threw
/// `type 'String' is not a subtype of type 'int?'`, aborting `fromJson` — leaving
/// `vehicleDetailsModel` null and the Vehicle Details page stuck loading forever.
///
/// The payload below mirrors the REAL response for vehicle 1 (fields trimmed),
/// with the string-typed counter exactly as the backend sends it.
Map<String, dynamic> _realDetailsJson({dynamic totalVehicles = '1', dynamic totalVehicleCount}) => {
      'id': 1,
      'name': 'ES 350 Lexus',
      'description': 'ES 350 Lexus, Black Car',
      'provider_id': 39,
      'type': 'luxury',
      'seating_capacity': '5',
      'air_condition': 1,
      'fuel_type': 'petrol',
      'transmission_type': 'automatic',
      'trip_hourly': 1,
      'trip_distance': 1,
      'trip_day_wise': 1,
      'day_wise_price': 50000,
      'hourly_price': 10000,
      'distance_price': 3200,
      'discount_type': 'amount',
      'discount_price': 500,
      'total_trip': 83,
      'avg_rating': 5,
      'total_reviews': 1,
      'total_vehicles': totalVehicles, // string, as the details endpoint sends it
      'total_vehicle_count': totalVehicleCount,
      'images_full_url': ['https://admin.moonjoin.com/storage/a.png'],
    };

void main() {
  group('VehicleModel.fromJson counters', () {
    test('parses string-serialised total_vehicles from the real details payload', () {
      final vehicle = VehicleModel.fromJson(_realDetailsJson());

      expect(vehicle.id, 1);
      expect(vehicle.totalVehicles, 1);
      expect(vehicle.tripDayWise, isNotNull);
      expect(vehicle.avgRating, 5.0);
    });

    test('still parses integer counters (list-endpoint shape)', () {
      final vehicle = VehicleModel.fromJson(_realDetailsJson(totalVehicles: 3, totalVehicleCount: 2));

      expect(vehicle.totalVehicles, 3);
      expect(vehicle.vehicleIdentitiesCount, 2);
    });

    test('absent counters stay null — never a fabricated default', () {
      final vehicle = VehicleModel.fromJson(_realDetailsJson(totalVehicles: null));

      expect(vehicle.totalVehicles, isNull);
      expect(vehicle.vehicleIdentitiesCount, isNull);
    });
  });
}
