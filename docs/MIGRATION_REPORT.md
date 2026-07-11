# MoonJoin User App — UI Redesign Migration Report

Frontend-only redesign of the `sixam_mart` (6amMart-based) app to the MoonJoin design language. Backend
(`https://admin.moonjoin.com`) is live and unchanged. **Backend status is "Exists (live)" for every screen
except Apartment Rental.** Routes: `lib/helper/route_helper.dart`. API constants: `lib/util/app_constants.dart`.
Architecture per feature: `screens/ → controllers/ → domain/{repositories,services,models}`.

## Confirmed decisions
1. **Navigation** → 4-tab bottom nav (Home · Orders · Favorites · Account); Cart moved to a header icon;
   old Menu folded into Account. All routes/pages/controllers/logic preserved.
2. **Brand color** → `#2C9C44` authoritative (replaces `#039D55`).
3. **No-mockup screens** → restyled from Design System, logic unchanged, marked
   "Restyled using Design System (No Dedicated Mockup)".

## Module design-sharing rule
`home_screen.dart` fans out by `moduleType` into food/grocery/pharmacy/shop variants. Fuel, Fashion,
Market, Drink Distributor, Solar & Power render through the shared **shop (ecommerce)** UI — no separate
code. Food differs only at the item entry point (bottom sheet vs full details page).

---

### A. Storefront / Commerce (Food · Grocery · Fuel · Fashion · Pharmacy · Market · Drink · Solar)

| Screen | UI image | Existing screen | Route | Controller | Repo / Service | Model(s) | Key widgets | API | Missing integration |
|---|---|---|---|---|---|---|---|---|---|
| Home / module grid | `home.png` | `home/screens/home_screen.dart` (+ `modules/*_home_screen.dart`), shell `dashboard/screens/dashboard_screen.dart` | `/`, `/main` | `HomeController`, `BannerController`, `StoreController`, `ItemController`, `CategoryController`, `SplashController` | `home_repository`/`_service`, `advertisement_*` | `advertisement_model`, `cashback_model` | `menu_drawer`, `paginated_list_view`, `item_view`, `title_widget`, `card_design/*` | `bannerUri`, `storeUri`, `popularItemUri`, `categoryUri`, `flashSaleUri` | Nav shell rebuild; module grid + offers + unavailable-items banner |
| Store list | `restaurant_list.PNG` | `store/screens/all_store_screen.dart` | `/stores` | `StoreController`, `CategoryController` | `store_repository`/`_service` | `store_model`, `store_banner_model` | `filter_widget`, `paginated_list_view`, `card_design/store_card*` | `storeUri`, `popularStoreUri`, `latestStoreUri` | Restyle cards/filters |
| Item search list | `items_ search_list.PNG` | `search/screens/search_screen.dart`, `store/screens/store_item_search_screen.dart` | `/search`, `/search-store-item` | `SearchController` | `search_repository`/`_service` | `search_suggestion_model`, `popular_categories_model` | `search_field_widget`, `search_result_widget`, `voice_search_bottom_sheet` | `searchUri`, `searchSuggestionsUri` | Restyle |
| Product details (Food) | `product_details_for_only_food.PNG` | `common/widgets/item_bottom_sheet.dart` (+ `item/screens/item_details_screen.dart`) | `/item-details` | `ItemController`, `CartController` | `item_repository`/`_service` | `item_model` | `quantity_button`, `custom_button`, option-group cards | `itemDetailsUri`, `setMenuUri` | Promote food to full-page layout (option groups + footer). Confirm during build. |
| Product details (others) | `product_details_for_grocery_and_others_module.png` | `item/screens/item_details_screen.dart` | `/item-details` | `ItemController`, `CartController` | `item_repository`/`_service` | `item_model` | image carousel, variation chips, `quantity_button` | `itemDetailsUri` | Carousel + chips + In-Stock badge + footer |
| Cart | `cart.PNG` | `cart/screens/cart_screen.dart` | `/cart` | `CartController` | `cart_repository`/`_service` | `cart_model`, `online_cart_model` | `cart_item_widget`, `quantity_button`, `not_available_widget` | `getCartListUri`, `addCartUri`, `updateCartUri` | Restyle; entered from header icon |
| Edit unavailable items | `edit_unavailable_items.PNG` | `checkout/widgets/not_available_bottom_sheet_widget.dart` | `/cart`, `/checkout` | `CartController`, `CheckoutController` | cart/checkout repos | `cart_model` | `not_available_bottom_sheet_widget` | cart/order APIs | Restyle |
| Checkout | `checkout.png`, `checkout_scroll_down.png` | `checkout/screens/checkout_screen.dart` | `/checkout` | `CheckoutController` (+ `CartController`, `CouponController`) | `checkout_repository`/`_service` | `place_order_body_model`, `payment_model`, `distance_model`, `timeslote_model` | `{delivery,payment,coupon,time_slot,bottom}_section`, `payment_method_bottom_sheet` | `placeOrderUri`, `distanceMatrixUri`, `couponApplyUri`, `getOrderTaxUri` | Restyle; preserve prescription/partial-pay/tips |
| Payment confirmation popup | `payment_confirmation_popup.PNG` | `common/widgets/payment_complete_dialog.dart` | — | `PaymentController`, `CheckoutController` | `payment_*` | `payment_model` | `payment_complete_dialog` | `codSwitchUri`, `walletSwitchUri` | Restyle dialog |
| Virtual account payment | `virtual_account_payment.png` | `checkout/widgets/virtual_account_details_widget.dart` | `/payment` | `ProfileController.generateVirtualAccount`, `PaymentController` | `profile_repository`, `payment_*` | `payment_model` | `virtual_account_details_widget` | `generateVirtualAccountUri` | Restyle |
| Order success | `order_success.png` | `checkout/screens/order_successful_screen.dart` | `/order-successful` | `OrderController` | `order_repository`/`_service` | `order_model` | `order_successfull_dialog` | `orderDetailsUri` | Restyle |

### B. Orders

| Screen | UI image | Existing screen | Route | Controller | API | Notes |
|---|---|---|---|---|---|---|
| Order status popup | `order_status_pop_up.png` | `order/widgets/cancellation_dialogue_widget.dart` + tracking steppers | — | `OrderController` | `trackUri`, `orderCancelUri` | Restyle popup |
| Orders list | *(none)* | `order/screens/order_screen.dart` | `/order` | `OrderController` | `runningOrderListUri`, `historyOrderListUri` | Restyled (No Mockup); now a bottom-nav tab |
| Order details / tracking / refund | *(none)* | `order/screens/{order_details,order_tracking,guest_track_order,refund_request,order_edit}_screen.dart` | `/order-details`, `/track-order`, `/refund` | `OrderController`, `OrderEditController` | `orderDetailsUri`, `trackUri`, `refundRequestUri` | Restyled (No Mockup) |

### C. Car Rental (`rental_module`; internally "taxi"; direct `Get.to()`, no named routes)

| Screen | UI image | Existing screen | Controller | Repo/Service | API |
|---|---|---|---|---|---|
| Rental home | `rental_home.png`, `car_rental.png` | `rental_module/home/screens/taxi_home_screen.dart` | `TaxiHomeController` | `taxi_home_*` | `getTopRatedCarsUri`, `getTaxiBannerUri`, `getVehicleCategoriesUri` |
| Provider/vehicle list | `car_rental_provider_item_list.PNG` | `vendor/screens/vendor_detail_screen.dart`, `home/screens/all_vehicle_screen.dart` | `TaxiVendorController`, `TaxiHomeController` | `taxi_vendor_*` | `getProviderDetailsUri`, `getProviderVehicleListUri` |
| Search list | `car_rental_search_list.PNG` | `select_vehicle_screen/{search_vehicle,select_vehicle}_screen.dart` | `TaxiHomeController` | `taxi_home_*` | `getSelectVehiclesUri`, `getSearchVehicleSuggestionUri` |
| Vehicle details + trip type | `car_rental_details.PNG`, `car_rental_details_trip_type.PNG` | `vehicle_details_screen/vehicle_details_screen.dart` | `TaxiHomeController` | `taxi_home_*` | `getVehicleDetailsUri` |
| Checkout | `car_rental_checkout.PNG` | `rental_checkout_screen/taxi_checkout_screen.dart` (+ `rental_cart_screen/taxi_cart_screen.dart`) | `TaxiCartController` | `taxi_cart_*` | `tripBookingUri`, `getTripTaxUri`, `taxiCouponApplyUri` |
| Booking success | `booking_request_successful.png` | `widgets/confirm_booking_request_bottom_sheet.dart` | `TaxiOrderController` | `taxi_order_*` | (post-booking) |
| My trips | `my_trip.png` | `rental_order/screens/taxi_order_screen.dart` | `TaxiOrderController` | `taxi_order_*` | `tripListUri` |
| Trip details | `trip_details.PNG`, `trip_details_scroll_down.PNG` | `rental_order/screens/taxi_order_details_screen.dart` | `TaxiOrderController` | `taxi_order_*` | `tripDetailsUri`, `tripCancelUri`, `tripPaymentUri` |

### D. Parcel (`parcel`; named routes)

| Screen | UI image | Existing screen | Route | Controller | API |
|---|---|---|---|---|---|
| Parcel home | `parcel_home.png` | `parcel/screens/parcel_category_screen.dart` | `/parcel-category` | `ParcelController` | `parcelCategoryUri`, `parcelOtherBannerUri` |
| Parcel request | `parcel_request.PNG`, `..._scroll_down.PNG` | `parcel/screens/parcel_request_screen.dart` (+ `parcel_location_screen.dart`) | `/parcel-request`, `/parcel-location` | `ParcelController` | `parcelInstructionUri`, `placeOrderUri` |
| Parcel details | `parcel_details.png` | shared `order/screens/order_details_screen.dart` | `/order-details` | `OrderController` | `orderDetailsUri`, `customerParcelReturn` |

### E. Apartment Rental — NEW FEATURE (no backend / no Flutter code → mock repositories)

No apartment/property/stay/booking support exists. Build `lib/features/apartment_rental/` with mock
repository/service + local models so swapping to a live API later touches only the service/repository
layer. Clone `rental_module` (provider→list→details→checkout→booking-success→my-bookings→details→cancel
maps ~1:1). Register in `lib/helper/get_di.dart`; add to the Home module grid.

| Apartment screen | Clone from |
|---|---|
| `apt_rental.PNG` (home) | `taxi_home_screen.dart` |
| `apartment_ search_list.PNG` | `select_vehicle_screen.dart` + `search_vehicle_screen.dart` |
| `apt_rental_provider_item_list.PNG` | `vendor_detail_screen.dart` |
| `apt_rental_details.PNG` | `vehicle_details_screen.dart` |
| `apt_rental_checkout.PNG` | `taxi_checkout_screen.dart` + `taxi_cart_screen.dart` |
| `booking_successful.PNG` | `confirm_booking_request_bottom_sheet.dart` |
| `my_booking_history.PNG` | `taxi_order_screen.dart` |
| `view_my_booking.PNG` | `taxi_order_details_screen.dart` |
| `Example_cancel_my_booking_history.PNG` | `booking_cancel_bottomsheet.dart` |

### F. Cross-cutting screens with mockups

| Screen | UI image | Existing screen | Route | Controller / Repo | Notes |
|---|---|---|---|---|---|
| Profile / Account | `profile.png`, `profile_scroll down.png` | `profile/screens/profile_screen.dart` (+ `menu/menu_screen.dart`, `menu_drawer.dart`) | `/profile` | `ProfileController` / `profile_repository` | Becomes Account tab; absorb menu-drawer entries |
| Notification | `notification.png` | `notification/screens/notification_screen.dart` | `/notification` | `NotificationController` | Restyle |
| Set location | `set_location.png` | `location/screens/{access_location,pick_map,map}_screen.dart` | `/access-location`, `/pick-map`, `/map` | `LocationController` | Restyle |
| Select address popup | `select_address_pop_up.png` | `address/screens/address_screen.dart`, `common/widgets/address_widget.dart` | `/address` | `AddressController` | Restyle sheet |
| Voice search | `voice_search.png` | `search/widgets/voice_search_bottom_sheet.dart` | `/search` | `SearchController` | Restyle mic sheet |

### G. No-mockup screens → "Restyled using Design System (No Dedicated Mockup)"

`auth/screens/{sign_in,sign_up,new_user_setup}_screen.dart` (honor `CentralizeLoginHelper` variants),
`verification/screens/{verification,forget_pass,new_pass}_screen.dart`, `splash/`, `onboard/`, `language/`,
`interest/`, `wallet/`, `loyalty/`, `coupon/`, `refer_and_earn/`, `review/`, `chat/`, `support/`, `brands/`,
`flash_sale/`, `favourite/screens/favourite_screen.dart`, `add_address_screen.dart`. Restyle only; keep
logic/APIs. No login mockup exists — sign-in restyled from the design system (wavy header + card form),
not invented.

## Highest-risk regression areas (verify carefully)
Auth (all `CentralizeLoginHelper` login variants) and Payment (COD / wallet / gateway / virtual account).
