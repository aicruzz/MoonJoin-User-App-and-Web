import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_category_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/taxi_banner_model.dart';
import 'package:sixam_mart/features/rental_module/provider_adapter/rental_apartment_adapter.dart';

/// The apartment adapter derives everything from REAL backend data: the live
/// "Short Apt Rental" category and each item's `category_id`. Nothing fabricated.
void main() {
  final cats = VehicleCategoryModel(vehicles: [
    Vehicles(id: 3, name: 'Luxury Cars'),
    Vehicles(id: 2, name: 'Short Apt Rental'),
    Vehicles(id: 1, name: 'Car Rental'),
  ]);

  test('resolves the real Short-Apt category id by name', () {
    expect(RentalApartmentAdapter.apartmentCategoryId(cats), 2);
    expect(RentalApartmentAdapter.apartmentCategoryId(VehicleCategoryModel(vehicles: [Vehicles(id: 1, name: 'Car Rental')])), isNull);
    expect(RentalApartmentAdapter.apartmentCategoryId(null), isNull);
  });

  test('filters real inventory by category — car data never becomes apartment data', () {
    final inventory = [VehicleModel(id: 1, categoryId: 1), VehicleModel(id: 2, categoryId: 2)];
    final apts = RentalApartmentAdapter.filterApartments(inventory, 2);
    expect(apts.map((v) => v.id), [2]);
    expect(RentalApartmentAdapter.filterApartments(inventory, null), isEmpty);
    expect(RentalApartmentAdapter.filterApartments([VehicleModel(id: 1, categoryId: 1)], 2), isEmpty);
  });

  test('isApartmentProvider activates only for predominantly-apartment inventory', () {
    expect(RentalApartmentAdapter.isApartmentProvider([VehicleModel(categoryId: 2), VehicleModel(categoryId: 2)], 2), isTrue);
    expect(RentalApartmentAdapter.isApartmentProvider([VehicleModel(categoryId: 1)], 2), isFalse);
    expect(RentalApartmentAdapter.isApartmentProvider(const [], 2), isFalse);
    expect(RentalApartmentAdapter.isApartmentProvider(null, 2), isFalse);
  });

  test('sectionCategories splits the REAL list — Home keeps all', () {
    expect(RentalApartmentAdapter.sectionCategories(cats, RentalSection.all).length, 3);
    expect(RentalApartmentAdapter.sectionCategories(cats, RentalSection.apartment).map((c) => c.id), [2]);
    expect(RentalApartmentAdapter.sectionCategories(cats, RentalSection.car).map((c) => c.id), [3, 1]);
  });

  test('filterBanners classifies by the provider\'s REAL inventory; no signal → never apartment', () {
    final inventory = [
      VehicleModel(id: 1, providerId: 39, provider: Provider(id: 39), categoryId: 1), // car provider
      VehicleModel(id: 2, providerId: 50, provider: Provider(id: 50), categoryId: 2), // apt provider
    ];
    final banners = [
      Banners(id: 10, providerId: 39),           // car-classified
      Banners(id: 11, providerId: 50),           // apartment-classified
      Banners(id: 12, type: 'default'),          // external link — unclassified
      Banners(id: 13, providerId: 77),           // provider not in feed — unclassified
    ];
    expect(RentalApartmentAdapter.filterBanners(banners, section: RentalSection.all).length, 4);
    expect(RentalApartmentAdapter.filterBanners(banners, section: RentalSection.apartment, loadedInventory: inventory, aptCategoryId: 2).map((b) => b.id), [11]);
    expect(RentalApartmentAdapter.filterBanners(banners, section: RentalSection.car, loadedInventory: inventory, aptCategoryId: 2).map((b) => b.id), [10, 12, 13]);
  });
}
