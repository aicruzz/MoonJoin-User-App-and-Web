# MoonJoin User App UI Index

Maps every UI image in `ui-designs/` to its Flutter screen. Always consult this before redesigning a
screen. Screens with **no** image are restyled from the Design System and marked accordingly. See
`MIGRATION_REPORT.md` for full code/API details per screen.

## Storefront / Commerce (`Food_Groceries_Fuel_Fashion_Pharmacy_Market_DrinkDistributor_Solar&Power/`)

| Image | Flutter screen | Status |
|---|---|---|
| `home.png` | module-landing = `home/screens/home_screen.dart` (`showMobileModule` path) → redesigned `home/widgets/module_landing_view.dart`; shell = `dashboard/screens/dashboard_screen.dart` | Redesigned (Phase 4) |
| `restaurant_list.PNG` | `store/screens/all_store_screen.dart` | Redesigned · **Frozen** (All Restaurants / shared store list) |
| `store_or_restaurant.PNG` | `store/screens/store_screen.dart` (+ `store_hero_header`, `store_map_view`, premium `item_widget`) | Redesigned · **Frozen** (shared storefront page for Food/Grocery/Pharmacy/Ecommerce) |
| `items_ search_list.PNG` | `search/screens/search_screen.dart`, `store/screens/store_item_search_screen.dart` | Existing |
| `product_details_for_only_food.PNG` | `item/screens/item_details_screen.dart` (food variant; currently `common/widgets/item_bottom_sheet.dart`) | Existing |
| `product_details_for_grocery_and_others_module.png` | `item/screens/item_details_screen.dart` (grocery/others) | Existing |
| `cart.PNG` | `cart/screens/cart_screen.dart` | Existing |
| `edit_unavailable_items.PNG` | `checkout/widgets/not_available_bottom_sheet_widget.dart` | Existing |
| `checkout.png`, `checkout_scroll_down.png` | `checkout/screens/checkout_screen.dart` | Existing |
| `payment_confirmation_popup.PNG` | `common/widgets/payment_complete_dialog.dart` | Existing |
| `virtual_account_payment.png` | `checkout/widgets/virtual_account_details_widget.dart` | Existing |
| `order_success.png` | `checkout/screens/order_successful_screen.dart` | Existing |
| `IMG_4509.PNG` | Reference/ambient (module storefront) | Existing |

## Car Rental (`Car_Rental/`) — module `rental_module` (internally "taxi")

| Image | Flutter screen | Status |
|---|---|---|
| `rental_home.png`, `car_rental.png` | `rental_module/home/screens/taxi_home_screen.dart` | Existing |
| `car_rental_provider_item_list.PNG` | `rental_module/vendor/screens/vendor_detail_screen.dart` | Existing |
| `car_rental_search_list.PNG` | `rental_module/select_vehicle_screen/{search_vehicle,select_vehicle}_screen.dart` | Existing |
| `car_rental_details.PNG`, `car_rental_details_trip_type.PNG` | `rental_module/vehicle_details_screen/vehicle_details_screen.dart` | Existing |
| `car_rental_checkout.PNG` | `rental_module/rental_checkout_screen/taxi_checkout_screen.dart` | Existing |
| `booking_request_successful.png` | `rental_module/widgets/confirm_booking_request_bottom_sheet.dart` | Existing |
| `my_trip.png` | `rental_module/rental_order/screens/taxi_order_screen.dart` | Existing |
| `trip_details.PNG`, `trip_details_scroll_down.PNG` | `rental_module/rental_order/screens/taxi_order_details_screen.dart` | Existing |

## Apartment Rental (`Apartment_Rental/`) — NEW FEATURE (mock repositories)

| Image | Flutter screen (to build in `lib/features/apartment_rental/`) | Status |
|---|---|---|
| `apt_rental.PNG` | `screens/apartment_home_screen.dart` | New (mock) |
| `apartment_ search_list.PNG` | `screens/apartment_search_screen.dart` | New (mock) |
| `apt_rental_provider_item_list.PNG` | `screens/apartment_provider_screen.dart` | New (mock) |
| `apt_rental_details.PNG` | `screens/apartment_details_screen.dart` | New (mock) |
| `apt_rental_checkout.PNG` | `screens/apartment_checkout_screen.dart` | New (mock) |
| `booking_successful.PNG` | `screens/apartment_booking_success_screen.dart` | New (mock) |
| `my_booking_history.PNG` | `screens/apartment_booking_history_screen.dart` | New (mock) |
| `view_my_booking.PNG` | `screens/apartment_booking_details_screen.dart` | New (mock) |
| `Example_cancel_my_booking_history.PNG` | booking cancel bottom sheet | New (mock) |

## Parcel (`Parcel/`) — module `parcel`

| Image | Flutter screen | Status |
|---|---|---|
| `parcel_home.png` | `parcel/screens/parcel_category_screen.dart` | Existing |
| `parcel_request.PNG`, `parcel_request_scroll_down.PNG` | `parcel/screens/parcel_request_screen.dart` | Existing |
| `parcel_details.png` | shared `order/screens/order_details_screen.dart` (or new parcel details — TBD) | Existing |

## Profile / Location / Notification / Order status / Select address / Voice search

| Image | Flutter screen | Status |
|---|---|---|
| `profile.png`, `profile_scroll down.png` | `profile/screens/profile_screen.dart` (becomes Account tab) | Existing |
| `notification.png` | `notification/screens/notification_screen.dart` | Existing |
| `set_location.png` | `location/screens/{access_location,pick_map,map}_screen.dart` | Existing |
| `select_address_pop_up.png` | `address/screens/address_screen.dart`, `common/widgets/address_widget.dart` | Existing |
| `order_status_pop_up.png` | `order/widgets/cancellation_dialogue_widget.dart` + tracking steppers | Existing |
| `voice_search.png` | `search/widgets/voice_search_bottom_sheet.dart` | Existing |

## Screens with NO design image — "Restyled using Design System (No Dedicated Mockup)"

sign_in / sign_up / new_user_setup, verification / forget_pass / new_pass, splash, onboard, language,
interest, wallet, loyalty, coupon, refer_and_earn, review, chat, support, brands, flash_sale, favourite,
add_address, orders list & order details/tracking/refund. Restyle only; keep all logic/APIs. If a screen
needs a genuinely new layout not derivable from the design system, stop and request a mockup.
