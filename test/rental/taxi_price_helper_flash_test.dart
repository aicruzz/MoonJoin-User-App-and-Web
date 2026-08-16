import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart' hide Provider;
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/helper/taxi_price_helper.dart';

// Proves the Rental Flash Sale price flows through the actual booking
// calculation (not just the UI), for every Car Rental axis, using ONLY the
// backend-authoritative flash prices — and that non-flash bookings are
// unaffected and flash never double-discounts on the vehicle's own discount.
//
// Rental-level: the helper resolves the rate by rentalType STRING, so the same
// calculation supports any future Rental type (Short Apt) without a rewrite.

VehicleModel _flashVehicle({double vehicleDiscount = 0}) => VehicleModel(
      id: 1,
      status: 1,
      hourlyPrice: 10000,
      distancePrice: 3200,
      dayWisePrice: 50000,
      discountPrice: vehicleDiscount,
      discountType: 'percent',
      flashSale: RentalFlashSale(
        title: 'Peeprate Car',
        discountType: 'percent',
        discount: 50,
        discountAppliesTo: 'unit_price',
        appliesTo: 'all',
        prices: RentalFlashPrices(
          hourly: RentalFlashAxisPrice(originalPrice: 10000, flashPrice: 5000, discountAmount: 5000),
          distanceWise: RentalFlashAxisPrice(originalPrice: 3200, flashPrice: 1600, discountAmount: 1600),
          dayWise: RentalFlashAxisPrice(originalPrice: 50000, flashPrice: 25000, discountAmount: 25000),
        ),
      ),
    );

VehicleModel _plainVehicle() => VehicleModel(
      id: 2,
      status: 1,
      hourlyPrice: 10000,
      distancePrice: 3200,
      dayWisePrice: 50000,
      discountPrice: 0,
      discountType: 'percent',
    );

List<Carts> _cart(VehicleModel v) => [Carts(id: 1, quantity: 1, vehicle: v, provider: Provider(id: 1))];

UserData _userData(String rentalType, {double? hours, double? distance}) =>
    UserData(rentalType: rentalType, estimatedHours: hours, distance: distance);

void main() {
  group('TaxiPriceHelper — Rental Flash Sale pricing', () {
    test('hourly uses the flash rate (5000, not 10000)', () {
      final cart = _cart(_flashVehicle());
      final user = _userData('hourly', hours: 1, distance: 1);
      expect(TaxiPriceHelper.calculateTripCost(cart, user), 5000);
      expect(TaxiPriceHelper.calculateOriginalTripCost(cart, user), 10000);
      expect(TaxiPriceHelper.calculateFlashDiscount(cart, user), 5000);
    });

    test('day_wise uses the flash rate (25000, not 50000)', () {
      final cart = _cart(_flashVehicle());
      final user = _userData('day_wise', hours: 24); // 24h / 24 = 1 day
      expect(TaxiPriceHelper.calculateTripCost(cart, user), 25000);
      expect(TaxiPriceHelper.calculateFlashDiscount(cart, user), 25000);
    });

    test('distance_wise uses the flash rate (1600, not 3200)', () {
      final cart = _cart(_flashVehicle());
      final user = _userData('distance_wise', distance: 1);
      expect(TaxiPriceHelper.calculateTripCost(cart, user), 1600);
      expect(TaxiPriceHelper.calculateFlashDiscount(cart, user), 1600);
    });

    test('non-flash booking is unchanged (original rate, zero flash discount)', () {
      final cart = _cart(_plainVehicle());
      final user = _userData('hourly', hours: 1);
      expect(TaxiPriceHelper.calculateTripCost(cart, user), 10000);
      expect(TaxiPriceHelper.calculateFlashDiscount(cart, user), 0);
    });

    test('flash replaces (does not stack on) the vehicle discount', () {
      // Vehicle has BOTH a 10% own discount and a flash sale. The flash saving
      // is surfaced as its own line; the vehicle discount must be suppressed.
      final cart = _cart(_flashVehicle(vehicleDiscount: 10));
      final user = _userData('hourly', hours: 1);
      expect(
        TaxiPriceHelper.calculateDiscountCost(cart, user, calculateProviderDiscount: false),
        0,
        reason: 'vehicle discount must not stack on top of the flash price',
      );
    });

    test('model resolves applicable vs base rate per axis', () {
      final v = _flashVehicle();
      expect(v.applicableRate('hourly'), 5000);
      expect(v.baseRate('hourly'), 10000);
      expect(v.hasFlashRate('hourly'), true);
      expect(v.applicableRate('day_wise'), 25000);
      expect(v.applicableRate('distance_wise'), 1600);
      // Non-flash vehicle returns the original rate and reports no flash.
      final p = _plainVehicle();
      expect(p.applicableRate('hourly'), 10000);
      expect(p.hasFlashRate('hourly'), false);
    });
  });
}
