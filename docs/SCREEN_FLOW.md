# MoonJoin Screen Flow

Documents navigation between screens. Every redesign must keep navigation destinations consistent. Update
whenever navigation changes. Routes are defined in `lib/helper/route_helper.dart`.

## App shell — bottom navigation (NEW MoonJoin architecture — implemented in Phase 3)

`DashboardScreen` hosts 4 tabs. Cart + Notifications are **header icons** (with count badges), not tabs.
The old **Menu** tab is folded into **Account**. All routes, pages, controllers, and logic are preserved —
only access changes. Deep-link tab indices in `route_helper.dart` `/main` map: home→0, order→1,
favourite→2, menu→3 (legacy `cart`→Home, since cart is now a header action).

```
[ Home ] [ Orders ] [ Favorites ] [ Account ]        (home header: 🔔 Notifications · 🛒 Cart)
```

- Home → **module-landing grid** (Food, Groceries, Fuel, Fashion, Pharmacy, Market, Package Delivery, Car
  Rental, Drink Distributor, Solar & Power, +Apartment Rental) + offers. Ref image `home.png`.
  Tapping a module → `SplashController.switchModule` → that module's home. Module-aware content is
  preserved on the fixed tabs (taxi → Trips / Wishlist; parcel → Address manager under Favorites; parcel
  Home body = `ParcelCategoryScreen`).
- Orders → `order_screen` (running + history; taxi → trips via `OrderScreen(index:1)`).
- Favorites → `favourite_screen` (taxi → `VehicleFavouriteScreen`; parcel → `AddressScreen`).
- Account → `menu_screen` = profile + former menu-drawer entries (address, wallet, loyalty, coupon,
  support, refer & earn, language, policies, logout, store/DM registration).

## Storefront / Commerce flow

```
Home → Module → Store list → Store details → Product details → Cart → Checkout → Payment → Order Success
                                                                                    ↓
                                                                        Orders → Order details → Track order
```
- Food product details: `product_details_for_only_food` (option groups + footer bar).
- Grocery/Fuel/Fashion/Pharmacy/Market/Drink/Solar: `product_details_for_grocery_and_others_module`.

## Car Rental flow (module `rental_module`, direct `Get.to()` navigation)

```
Rental Home → Provider / Vehicle list → Vehicle details (+ trip type) → Checkout → Booking success
My Trips → Trip details → (cancel / pay)
```

## Parcel flow (named routes)

```
Parcel Home (/parcel-category) → Parcel Location (/parcel-location) → Parcel Request (/parcel-request)
→ Checkout/Payment → Order Success → Order details (shared)
```

## Apartment Rental flow (NEW, mock repositories)

```
Apartment Home → Search list → Provider item list → Apartment details → Checkout → Booking successful
My Booking History → View booking → Cancel booking
```

## Auth / entry flow

```
Splash → (Onboarding) → Access Location → Sign In (otp/manual/social per CentralizeLoginHelper)
→ Verification → (New User Setup) → Home
```

Every new feature must be added here.
