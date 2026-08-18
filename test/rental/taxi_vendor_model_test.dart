import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/features/rental_module/vendor/domain/models/taxi_vendor_model.dart';

/// Regression test for the Rental **Provider Details** parse crash.
///
/// `GET /api/v1/rental/provider/get-provider-details/{id}` serialises its counters as
/// **strings** (`"order_count": "0"`), while `TaxiVendorModel` types them `int?`. The
/// raw assignment threw `type 'String' is not a subtype of type 'int?'`, aborting
/// `fromJson` — so `taxiVendor` stayed null and the Provider page hung on its loading
/// state forever.
///
/// The payload below is the REAL response for provider 39 (fields trimmed to the ones
/// this test exercises); the string-typed counters are exactly as the backend sends them.
void main() {
  group('TaxiVendorModel.fromJson', () {
    test('parses string-serialised counters from the real provider payload', () {
      final json = <String, dynamic>{
        'id': 39,
        'name': 'Peeprate Car Rental',
        'address': 'Ogbomoso, Oyo State, Nigeria.',
        'logo_full_url': 'https://admin.moonjoin.com/storage/app/public/store/logo.png',
        'cover_photo_full_url': 'https://admin.moonjoin.com/storage/app/public/store/cover.png',
        'order_count': '0', // string, as the backend sends it
        'total_order': '0', // string, as the backend sends it
        'total_vehicle_count': '1', // string, as the backend sends it
        'ratings': [1, 0, 0, 0, 0],
        'avg_rating': 5,
        'rating_count': 1,
        'status': 1,
        'active': true,
      };

      final vendor = TaxiVendorModel.fromJson(json);

      expect(vendor.id, 39);
      expect(vendor.name, 'Peeprate Car Rental');
      expect(vendor.orderCount, 0);
      expect(vendor.totalOrder, 0);
      expect(vendor.totalVehicleCount, 1);
      expect(vendor.avgRating, 5.0);
      expect(vendor.ratingCount, 1);
    });

    test('still parses the same counters when sent as real integers', () {
      final json = <String, dynamic>{
        'id': 39,
        'name': 'Peeprate Car Rental',
        'order_count': 4,
        'total_order': 7,
        'total_vehicle_count': 12,
        'ratings': [1, 0, 0, 0, 0],
        'avg_rating': 5,
        'rating_count': 1,
      };

      final vendor = TaxiVendorModel.fromJson(json);

      expect(vendor.orderCount, 4);
      expect(vendor.totalOrder, 7);
      expect(vendor.totalVehicleCount, 12);
    });

    test('leaves counters null when absent — never a fabricated default', () {
      final json = <String, dynamic>{
        'id': 39,
        'name': 'Peeprate Car Rental',
        'ratings': [1, 0, 0, 0, 0],
      };

      final vendor = TaxiVendorModel.fromJson(json);

      expect(vendor.orderCount, isNull);
      expect(vendor.totalOrder, isNull);
      expect(vendor.totalVehicleCount, isNull);
    });
  });
}
