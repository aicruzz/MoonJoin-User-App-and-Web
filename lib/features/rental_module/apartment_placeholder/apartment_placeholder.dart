import 'package:moonjoin/util/images.dart';

/// TODO(BACKEND): TEMPORARY UI-layer placeholder for Short Apartment Rental.
///
/// Short Apartment Rental currently has NO backend (no module, no listing API,
/// no models). This local list exists ONLY to render the approved Rental Home UI
/// (the "Short Apt Rental" hero + the "Popular Short Apt Rentals" row). It is NOT
/// backend data and must NOT be presented as such.
///
/// It is isolated in the UI layer on purpose: when the backend apartment listing
/// exists, replace THIS single data source with it — no widget/UI change needed.
/// See docs/BACKEND_INTEGRATION_QUEUE.md → "Short Apartment Rental".
class ApartmentPlaceholder {
  final String name;
  final String location;
  final double pricePerNight;
  final double rating;
  final String image; // placeholder asset until backend supplies real images

  const ApartmentPlaceholder({
    required this.name,
    required this.location,
    required this.pricePerNight,
    required this.rating,
    required this.image,
  });
}

// TODO(BACKEND): replace with the backend "popular apartments" listing response.
const List<ApartmentPlaceholder> kPlaceholderPopularApartments = <ApartmentPlaceholder>[
  ApartmentPlaceholder(name: 'Luxury 2 Bedroom Apt', location: 'Lekki, Lagos', pricePerNight: 45000, rating: 4.8, image: Images.placeholder),
  ApartmentPlaceholder(name: 'Cozy Studio Apartment', location: 'Victoria Island, Lagos', pricePerNight: 18000, rating: 4.7, image: Images.placeholder),
  ApartmentPlaceholder(name: 'Oceanview Apartment', location: 'Ikoyi, Lagos', pricePerNight: 65000, rating: 4.9, image: Images.placeholder),
  ApartmentPlaceholder(name: 'Modern 1 Bedroom Apt', location: 'Yaba, Lagos', pricePerNight: 25000, rating: 4.6, image: Images.placeholder),
];

// ── Hero card images (dynamic; backend-ready) ──
// TODO(BACKEND): the two Rental Home hero images are admin-uploaded (Car & Apt
// Rental → Dashboard → between Trip Management and Promotion Management). Replace
// these placeholder asset paths with the admin image URLs — no UI change needed.
const String kPlaceholderCarHeroImage = Images.placeholder;
const String kPlaceholderAptHeroImage = Images.placeholder;

// NOTE: Rental categories are NOT placeholders — they come from the REAL existing
// backend (`/api/v1/rental/vehicle/category-list` via
// `TaxiHomeController.getVehicleCategoryList()` → `VehicleCategoryModel`), managed in
// admin under Car & Apt Rental → Vehicle Management → Categories. Nothing about
// category names / images / count is hardcoded in the frontend.
