import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';

class TaxiPriceHelper {

  /// The applicable (charged) trip cost. When an active percent Flash Sale
  /// targets the selected rental type, `vehicle.applicableRate` returns the
  /// backend flash price, so the flash rate flows through the whole pipeline
  /// (cart → checkout → tax base → total → payload). When no flash applies,
  /// `applicableRate` returns the original rate, so behaviour is unchanged.
  static double calculateTripCost(List<Carts> cartList, UserData userData) {
    double tripCost = 0;
    String rentalType = userData.rentalType!;
    double distanceOrHour = rentalType == 'hourly' ? userData.estimatedHours ?? 1 : rentalType == 'day_wise' ? (userData.estimatedHours ?? 0) / 24 : userData.distance??1;
    if(cartList.isEmpty) {
      return tripCost;
    }

    for (Carts cart in cartList) {
      tripCost = tripCost + (cart.vehicle!.applicableRate(rentalType) * cart.quantity!);
    }
    tripCost = tripCost * distanceOrHour;

    return tripCost;
  }

  /// The original (pre-flash) trip cost — used only to display the struck-out
  /// base cost and the Flash Sale saving in Bill Details. Identical to
  /// [calculateTripCost] but always uses the vehicle's original rate.
  static double calculateOriginalTripCost(List<Carts> cartList, UserData userData) {
    double tripCost = 0;
    String rentalType = userData.rentalType!;
    double distanceOrHour = rentalType == 'hourly' ? userData.estimatedHours ?? 1 : rentalType == 'day_wise' ? (userData.estimatedHours ?? 0) / 24 : userData.distance??1;
    if(cartList.isEmpty) {
      return tripCost;
    }

    for (Carts cart in cartList) {
      tripCost = tripCost + (cart.vehicle!.baseRate(rentalType) * cart.quantity!);
    }
    tripCost = tripCost * distanceOrHour;

    return tripCost;
  }

  /// The Flash Sale saving = original trip cost − applicable (flash) trip cost.
  /// Zero when no per-unit flash applies, so non-flash bookings are unaffected.
  static double calculateFlashDiscount(List<Carts> cartList, UserData userData) {
    final double diff = calculateOriginalTripCost(cartList, userData) - calculateTripCost(cartList, userData);
    return diff > 0 ? diff : 0;
  }

  static double calculateDiscountCost(List<Carts> cartList, UserData userData, {required bool calculateProviderDiscount, double? tripCost}) {
    double tripDiscountCost = 0;
    double discountPrice = 0;
    String discountType = '';
    String rentalType = userData.rentalType!;
    double distanceOrHour = rentalType == 'hourly' ? userData.estimatedHours??1 : rentalType == 'day_wise' ? ((userData.estimatedHours ?? 0) / 24) : userData.distance??1;
    if(cartList.isEmpty) {
      return tripDiscountCost;
    }

    for (Carts cart in cartList) {
      double p = 0;
      bool usedProviderDiscount = cart.provider!.discount != null && calculateProviderDiscount && tripCost != null && cart.provider!.discount!.minPurchase! <= tripCost;
      if(usedProviderDiscount) {
        discountPrice = cart.provider!.discount!.discount!;
        discountType = cart.provider!.discount!.discountType!;
      } else {
        discountPrice = cart.vehicle!.discountPrice!;
        discountType = cart.vehicle!.discountType!;
      }

      // Flash Sale replaces the vehicle's own promotional discount: when a
      // per-unit flash rate applies to the selected axis it already embeds the
      // saving (surfaced separately as the Flash Sale bill line), so the vehicle
      // discount must not stack on top. Provider-wide promos still apply, but to
      // the corrected (flash) subtotal.
      if(!usedProviderDiscount && cart.vehicle!.hasFlashRate(rentalType)) {
        discountPrice = 0;
      }

      // Base amount uses the applicable (flash-aware) rate so any surviving
      // discount is computed on the corrected subtotal, never the pre-flash rate.
      p = PriceConverter.calculation(cart.vehicle!.applicableRate(rentalType) * distanceOrHour, discountPrice, discountType, cart.quantity!);

      tripDiscountCost = tripDiscountCost + p;
    }

    if(calculateProviderDiscount) {
      if (tripCost != null) {
        if (cartList[0].provider!.discount != null && cartList[0].provider!.discount!.minPurchase! <= tripCost &&
            cartList[0].provider!.discount!.maxDiscount! < tripDiscountCost) {
          tripDiscountCost = cartList[0].provider!.discount!.maxDiscount!;
        } else {
          tripDiscountCost = tripDiscountCost;
        }
      }

      else if (tripCost == null && cartList[0].provider!.discount != null &&
          cartList[0].provider!.discount!.maxDiscount! < tripDiscountCost) {
        tripDiscountCost = cartList[0].provider!.discount!.maxDiscount!;
      }
    }

    if(tripDiscountCost > 0) {
      return tripDiscountCost;
    } else {
      return 0;
    }
  }

  static double calculateDistanceWiseDiscount(VehicleModel vehicle, double discount, String discountType) {
    double distanceWiseDiscount = 0;
    double discount0 = discount;
    String discountType0 = discountType;

    distanceWiseDiscount = PriceConverter.calculation(vehicle.distancePrice!, discount0, discountType0, 1);

    if(vehicle.provider != null && vehicle.provider!.discount != null) {
      discount0 = vehicle.provider!.discount!.discount??0;
      discountType0 = vehicle.provider!.discount!.discountType ?? 'percent';

      distanceWiseDiscount = PriceConverter.calculation(vehicle.distancePrice!, discount, discountType, 1);

      if(vehicle.provider!.discount!.maxDiscount != 0 && vehicle.provider!.discount!.maxDiscount! < distanceWiseDiscount) {
        distanceWiseDiscount = vehicle.provider!.discount!.maxDiscount!;
      }
    }
    return distanceWiseDiscount;
  }

  static double calculateHourlyDiscount(VehicleModel vehicle, double discount, String discountType) {

    double hourlyDiscount = 0;
    double discount0 = discount;
    String discountType0 = discountType;

    hourlyDiscount = PriceConverter.calculation(vehicle.hourlyPrice!, discount0, discountType0, 1);

    if(vehicle.provider != null && vehicle.provider!.discount != null) {
      discount0 = vehicle.provider!.discount!.discount??0;
      discountType0 = vehicle.provider!.discount!.discountType ?? 'percent';

      hourlyDiscount = PriceConverter.calculation(vehicle.hourlyPrice!, discount0, discountType0, 1);

      if(vehicle.provider!.discount!.maxDiscount != 0 && vehicle.provider!.discount!.maxDiscount! < hourlyDiscount) {
        hourlyDiscount = vehicle.provider!.discount!.maxDiscount!;
      }
    }

    return hourlyDiscount;
  }

  static double getDiscountPrice(double providerDiscountPrice, double productDiscountPrice, double totalPrice) {
    double discountPrice = 0;
    if(providerDiscountPrice > productDiscountPrice) {
      discountPrice = providerDiscountPrice;
    } else if(productDiscountPrice > providerDiscountPrice) {
      discountPrice = productDiscountPrice;
    } else {
      discountPrice = productDiscountPrice;
    }
    return discountPrice > totalPrice ? totalPrice : discountPrice;
  }

  static double getExtraDiscountPrice(double providerDiscountPrice, double productDiscountPrice) {
    double extraDiscount = 0;
    if(providerDiscountPrice > productDiscountPrice) {
      extraDiscount = providerDiscountPrice - productDiscountPrice;
    } else if(productDiscountPrice > providerDiscountPrice) {
      extraDiscount = 0;
    } else {
      extraDiscount = 0;
    }
    return extraDiscount;
  }

}