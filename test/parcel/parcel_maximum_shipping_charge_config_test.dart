import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/common/models/config_model.dart';

/// The parcel screen caps its displayed base shipping estimate with
/// `parcel_maximum_shipping_charge` from /api/v1/config. These tests pin the
/// config contract that cap depends on: absent stays null (treated as no cap),
/// 0 stays 0 (no cap), and positive values parse as doubles.
void main() {
  Map<String, dynamic> config(Map<String, dynamic> parcel) => <String, dynamic>{
        'parcel_per_km_shipping_charge': 250,
        'parcel_minimum_shipping_charge': 700,
        ...parcel,
      };

  test('absent key parses to null, existing parcel fields unchanged', () {
    final model = ConfigModel.fromJson(config({}));
    expect(model.parcelMaximumShippingCharge, isNull);
    expect(model.parcelPerKmShippingCharge, 250.0);
    expect(model.parcelMinimumShippingCharge, 700.0);
  });

  test('explicit 0 parses to 0 (no cap)', () {
    final model = ConfigModel.fromJson(config({'parcel_maximum_shipping_charge': 0}));
    expect(model.parcelMaximumShippingCharge, 0.0);
  });

  test('positive int and double values parse as doubles', () {
    expect(ConfigModel.fromJson(config({'parcel_maximum_shipping_charge': 1500})).parcelMaximumShippingCharge, 1500.0);
    expect(ConfigModel.fromJson(config({'parcel_maximum_shipping_charge': 1500.5})).parcelMaximumShippingCharge, 1500.5);
  });

  test('toJson round-trips the key', () {
    final json = ConfigModel.fromJson(config({'parcel_maximum_shipping_charge': 1500})).toJson();
    expect(json['parcel_maximum_shipping_charge'], 1500.0);
    expect(ConfigModel.fromJson(json).parcelMaximumShippingCharge, 1500.0);
  });
}
