// "Apply to item quantity" (per selected add-on). A marked add-on takes the item
// quantity and follows every change of it, including the item quantity resets in
// setExistInCart. An unmarked add-on stays manual. The quantity lives in the
// existing addOnQtyList, so pricing and the add_on_qtys payload are unchanged, and
// the mark itself is not stored in the cart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/item_bottom_sheet.dart';
import 'package:moonjoin/common/widgets/quantity_button.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/models/cart_model.dart';
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/checkout/domain/models/place_order_body_model.dart';
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/repositories/item_repository_interface.dart';
import 'package:moonjoin/features/item/domain/services/item_service.dart';
import 'package:moonjoin/features/item/screens/food_details_screen.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/helper/item_cart_helper.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _AuthService extends _NoSuch implements AuthServiceInterface {
  @override
  bool isSharedPrefNotificationActive() => false;
}

class _Auth extends AuthController {
  _Auth() : super(authServiceInterface: _AuthService());
  @override
  bool isLoggedIn() => false;
  @override
  bool isGuestLoggedIn() => false;
}

class _FavouriteService extends _NoSuch implements FavouriteServiceInterface {}

class _CartService extends _NoSuch implements CartServiceInterface {
  @override
  int? getCartId(int cartIndex, List<CartModel> cartList) => null;
  @override
  bool existAnotherStoreItem(int? storeID, int? moduleId, List<CartModel> cartList) => false;
}

/// Records the payload the page sends. Answers false so no cart snackbar is shown.
class _Cart extends CartController {
  _Cart() : super(cartServiceInterface: _CartService());
  OnlineCart? added;
  OnlineCart? updated;
  @override
  Future<bool> addToCartOnline(OnlineCart cart, {bool existCartData = false, bool fromDirectlyAdd = false}) async {
    added = cart;
    return false;
  }
  @override
  Future<bool> updateCartOnline(OnlineCart cart) async {
    updated = cart;
    return false;
  }
}

Map<String, dynamic> _moduleConfig({required bool stock, required bool addOn, required bool food}) => <String, dynamic>{
  'stock': stock, 'add_on': addOn, 'show_restaurant_text': food, 'veg_non_veg': food, 'unit': !food, 'order_attachment': false,
  'order_place_to_schedule_interval': !food, 'always_open': false, 'all_zone_service': false, 'item_available_time': food,
  'is_parcel': false, 'organic': !food, 'cutlery': food, 'common_condition': false, 'nutrition': true, 'allergy': true,
  'basic': false, 'halal': true, 'brand': false, 'generic_name': false, 'is_rental': false,
};

Map<String, dynamic> _config() => <String, dynamic>{
  'maintenance_mode': false,
  'app_minimum_version_android': 0,
  'app_minimum_version_ios': 0,
  'currency_symbol': 'NGN',
  'currency_symbol_direction': 'left',
  'digit_after_decimal_point': 0,
  'toggle_veg_non_veg': true,
  'module_config': <String, dynamic>{
    'module_type': <String>['grocery', 'food'],
    'grocery': _moduleConfig(stock: true, addOn: false, food: false),
    'food': _moduleConfig(stock: false, addOn: true, food: true),
  },
};

class _SplashService extends _NoSuch implements SplashServiceInterface {
  ModuleModel? cache;
  @override
  bool? showIntro() => false;
  @override
  Future<Response> getConfigData({required DataSourceEnum source}) async => Response(statusCode: 200, body: _config());
  @override
  Future<void> setModule(ModuleModel? module) async {}
  @override
  Future<ModuleModel?> setCacheModule(ModuleModel? module) async => cache = module;
  @override
  ModuleModel? getCacheModule() => cache;
}

class _ItemRepository extends _NoSuch implements ItemRepositoryInterface {}

/// The real ItemService logic; only the fetch is faked.
class _ItemService extends ItemService {
  _ItemService() : super(itemRepositoryInterface: _ItemRepository());
  @override
  Future<Item?> getItemDetails(int? itemID, {int? moduleId}) async => _food();
}

const String _chicken = 'Extra Chicken';
const String _plantain = 'Extra Plantains';
const String _rice = 'Extra Rice';
const String _apply = 'apply_to_item_quantity';

Item _food() => Item.fromJson(<String, dynamic>{
  'id': 10, 'name': 'Jollof Rice', 'module_id': 3, 'module_type': 'food', 'store_id': 1, 'store_name': 'Perozona', 'price': 10000, 'discount': 0,
  'discount_type': 'percent', 'stock': 0, 'schedule_order': true, 'veg': 0, 'avg_rating': 0, 'rating_count': 0,
  'variations': <dynamic>[], 'food_variations': <dynamic>[], 'choice_options': <dynamic>[], 'attributes': <dynamic>[],
  'available_time_starts': '00:00:00', 'available_time_ends': '23:59:59',
  'add_ons': <dynamic>[
    <String, dynamic>{'id': 1, 'name': _chicken, 'price': 500},
    <String, dynamic>{'id': 2, 'name': _plantain, 'price': 300},
    <String, dynamic>{'id': 3, 'name': _rice, 'price': 200},
  ],
});

void main() {
  late ItemController items;
  late _Cart cart;
  late SplashController splash;

  setUp(() {
    Get.testMode = true;
    splash = SplashController(splashServiceInterface: _SplashService());
    items = ItemController(itemServiceInterface: _ItemService());
    cart = _Cart();
    Get.put<AuthController>(_Auth());
    Get.put<SplashController>(splash);
    Get.put<CartController>(cart);
    Get.put<FavouriteController>(FavouriteController(favouriteServiceInterface: _FavouriteService()));
    Get.put<ItemController>(items);
  });

  tearDown(Get.reset);

  Future<void> start(WidgetTester tester) async {
    await splash.getConfigData(routeAfterLoad: false);
    await tester.pump();
    await splash.setModule(ModuleModel(id: 3, moduleType: 'food'));
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(600 * 3, 1500 * 3); // mobile layout; everything on screen in the test font
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GetMaterialApp(home: screen));
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpFood(WidgetTester tester, {CartModel? editing}) async {
    await start(tester);
    await pump(tester, FoodDetailsScreen(itemId: 10, item: _food(), cart: editing));
  }

  Finder card(String name) => find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first;
  Finder inCard(String name, Finder finder) => find.descendant(of: card(name), matching: finder);
  Finder plus(String name) => inCard(name, find.byIcon(Icons.add));
  Finder minus(String name) => inCard(name, find.byIcon(Icons.remove));
  Finder apply(String name) => inCard(name, find.text(_apply));
  Finder parent(bool increment) => find.byWidgetPredicate((Widget w) => w is QuantityButton && w.isIncrement == increment);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> select(WidgetTester tester, String name) => tap(tester, find.text(name));

  Future<void> setParent(WidgetTester tester, int quantity) async {
    while (items.quantity! < quantity) {
      await tap(tester, parent(true));
    }
    while (items.quantity! > quantity) {
      await tap(tester, parent(false));
    }
    expect(items.quantity, quantity);
  }

  group('FoodDetailsScreen: Apply OFF', () {
    testWidgets('an unselected add-on has no Apply option; selecting shows it, off, at quantity 1', (WidgetTester tester) async {
      await pumpFood(tester);
      expect(find.text(_apply), findsNothing);
      await setParent(tester, 4);

      await select(tester, _chicken);
      expect(apply(_chicken), findsOneWidget);
      expect(items.isAddOnFollowingItemQuantity(0), isFalse);
      expect(items.addOnQtyList[0], 1, reason: 'stays 1 until Apply is turned on, whatever the item quantity');
      expect(apply(_plantain), findsNothing);
    });

    testWidgets('an unmarked add-on stays independent while the item quantity changes', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _plantain);
      await tap(tester, plus(_plantain));
      await setParent(tester, 5);
      expect(items.addOnQtyList[1], 2);
      await setParent(tester, 3);
      expect(items.addOnQtyList[1], 2);
    });
  });

  group('FoodDetailsScreen: Apply ON', () {
    for (final int quantity in <int>[1, 3, 5]) {
      testWidgets('item quantity $quantity: the add-on becomes $quantity', (WidgetTester tester) async {
        await pumpFood(tester);
        await setParent(tester, quantity);
        await select(tester, _chicken);
        await tap(tester, apply(_chicken));
        expect(items.isAddOnFollowingItemQuantity(0), isTrue);
        expect(items.addOnQtyList[0], quantity);
        expect(inCard(_chicken, find.text('$quantity')), findsOneWidget);
      });
    }

    testWidgets('item increase, decrease, down to 1, and repeated changes keep it in step', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 3);
      await select(tester, _chicken);
      await tap(tester, apply(_chicken));

      await setParent(tester, 4);
      expect(items.addOnQtyList[0], 4);
      await setParent(tester, 2);
      expect(items.addOnQtyList[0], 2);
      await setParent(tester, 1);
      expect(items.addOnQtyList[0], 1);
      for (final int quantity in <int>[6, 2, 9, 1, 3]) {
        await setParent(tester, quantity);
        expect(items.addOnQtyList[0], quantity);
      }
      expect(items.addOnQtyList.length, 3, reason: 'no duplicate entries');
      expect(ItemCartHelper.compute(items.item!, items, true).addOnIdList.length, 1);
    });

    testWidgets('two marked add-ons follow; an unmarked one coexists at its own quantity', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 5);
      await select(tester, _chicken);
      await select(tester, _plantain);
      await select(tester, _rice);
      await tap(tester, apply(_chicken));
      await tap(tester, apply(_plantain));
      await tap(tester, plus(_rice));
      expect(items.addOnQtyList, <int>[5, 5, 2]);

      await setParent(tester, 6);
      expect(items.addOnQtyList, <int>[6, 6, 2]);
      expect(items.addOnActiveList, <bool>[true, true, true]);
    });

    testWidgets('its − + do nothing, and tapping them does not deselect it', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 3);
      await select(tester, _chicken);
      await tap(tester, apply(_chicken));

      await tap(tester, plus(_chicken));
      await tap(tester, minus(_chicken));
      expect(items.addOnQtyList[0], 3);
      expect(items.addOnActiveList[0], isTrue);
      items.setAddOnQuantity(true, 0);
      expect(items.addOnQtyList[0], 3, reason: 'blocked in the controller as well');
    });

    testWidgets('at item quantity 1 it shows a disabled minus, not the delete icon', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await tap(tester, apply(_chicken));
      expect(inCard(_chicken, find.byIcon(Icons.delete_outline_outlined)), findsNothing);
      await tap(tester, minus(_chicken));
      expect(items.addOnActiveList[0], isTrue);
    });
  });

  group('FoodDetailsScreen: leaving Apply', () {
    testWidgets('turning it off keeps the quantity, stops following, and re-enables − +', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 5);
      await select(tester, _chicken);
      await tap(tester, apply(_chicken));

      await tap(tester, apply(_chicken));
      expect(items.isAddOnFollowingItemQuantity(0), isFalse);
      expect(items.addOnQtyList[0], 5);

      await setParent(tester, 7);
      expect(items.addOnQtyList[0], 5);
      await tap(tester, plus(_chicken));
      expect(items.addOnQtyList[0], 6);
      await tap(tester, minus(_chicken));
      expect(items.addOnQtyList[0], 5);
    });

    testWidgets('tapping a marked card deselects it, clears Apply, and removes its cost', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 4);
      await select(tester, _chicken);
      await tap(tester, apply(_chicken));

      await select(tester, _chicken);
      expect(items.addOnActiveList[0], isFalse);
      expect(items.isAddOnFollowingItemQuantity(0), isFalse);
      expect(ItemCartHelper.compute(items.item!, items, true).addonsCost, 0);

      await setParent(tester, 6);
      expect(items.addOnQtyList[0], 1, reason: 'no longer follows while unselected');
      await select(tester, _chicken);
      expect(items.isAddOnFollowingItemQuantity(0), isFalse, reason: 'Apply does not come back on reselection');
      expect(items.addOnQtyList[0], 1);
    });

    testWidgets('an unmarked add-on above 1 still does not deselect on a card tap (Issue 2A)', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await tap(tester, plus(_chicken));
      await select(tester, _chicken);
      expect(items.addOnActiveList[0], isTrue);
      expect(items.addOnQtyList[0], 2);
    });
  });

  group('FoodDetailsScreen: pricing and cart', () {
    testWidgets('pricing uses the resulting quantities', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 3);
      await select(tester, _chicken);
      await select(tester, _plantain);
      await tap(tester, apply(_chicken));
      await tap(tester, plus(_plantain));
      await setParent(tester, 5);

      final ItemCartData data = ItemCartHelper.compute(items.item!, items, true);
      expect(data.addonsCost, 500 * 5 + 300 * 2);
      expect(data.addOnIdList.map((AddOn a) => a.quantity), <int>[5, 2]);
    });

    testWidgets('Add To Cart sends the resulting quantities in add_on_qtys', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 3);
      await select(tester, _chicken);
      await select(tester, _plantain);
      await tap(tester, apply(_chicken));
      await tap(tester, plus(_plantain));
      await setParent(tester, 5);
      await tap(tester, find.text('add_to_cart'));

      expect(cart.added!.quantity, 5);
      expect(cart.added!.addOnIds, <int>[1, 2]);
      expect(cart.added!.addOnQtys, <int>[5, 2]);
      expect(cart.added!.toJson().containsKey('apply_to_item_quantity'), isFalse, reason: 'no new API field');
    });
  });

  group('state resets in the existing flows', () {
    testWidgets('an item quantity reset to 1 in setExistInCart (e.g. a variation change) is followed', (WidgetTester tester) async {
      await pumpFood(tester);
      await setParent(tester, 4);
      await select(tester, _chicken);
      await select(tester, _plantain);
      await tap(tester, apply(_chicken));
      await tap(tester, plus(_plantain));

      await items.setExistInCart(items.item, items.selectedVariations, notify: true);
      await tester.pump();
      expect(items.quantity, 1);
      expect(items.addOnQtyList[0], 1, reason: 'marked add-on stays equal to the item');
      expect(items.addOnQtyList[1], 2, reason: 'unmarked add-on unchanged');
    });

    testWidgets('a line found in the cart loads its saved quantities with Apply off', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await tap(tester, apply(_chicken));

      final CartModel saved = CartModel(9, 10000, 11500, <Variation>[], <List<bool?>>[], 0, 4, <AddOn>[AddOn(id: 1, quantity: 7)], <AddOns>[], false, 0, items.item, null);
      cart.cartList.add(saved);
      await items.setExistInCart(items.item, items.selectedVariations, notify: true);
      await tester.pump();

      expect(items.quantity, 4);
      expect(items.addOnQtyList[0], 7, reason: 'saved quantity is not overwritten');
      expect(items.isAddOnFollowingItemQuantity(0), isFalse);
    });

    testWidgets('cart edit: saved quantity kept with Apply off until the customer turns it on', (WidgetTester tester) async {
      final CartModel line = CartModel(9, 10000, 11500, <Variation>[], <List<bool?>>[], 0, 2, <AddOn>[AddOn(id: 1, quantity: 7)], <AddOns>[], false, 0, _food(), null);
      cart.cartList.add(line);
      await pumpFood(tester, editing: line);
      expect(items.quantity, 2);
      expect(items.addOnQtyList[0], 7);
      expect(items.isAddOnFollowingItemQuantity(0), isFalse);

      await tap(tester, apply(_chicken));
      expect(items.addOnQtyList[0], 2);
      await tap(tester, find.text('update_in_cart'));
      expect(cart.updated!.addOnQtys, <int>[2]);
    });

    testWidgets('opening another item clears Apply', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await tap(tester, apply(_chicken));
      await items.getItemDetails(itemId: 10, moduleId: 3);
      await tester.pump();
      expect(items.isAddOnFollowingItemQuantity(0), isFalse);
      expect(items.addOnActiveList[0], isFalse);
    });
  });

  group('narrow layout', () {
    testWidgets('Apply and the control fit the narrowest Extras card (320pt phone)', (WidgetTester tester) async {
      await start(tester);
      await items.getItemDetails(itemId: 10);
      items.addAddOn(true, 0);
      items.setAddOnFollowsItemQuantity(0, true);
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: Center(child: SizedBox(
        width: 82, // (320 − 2×16 page − 2×16 section − 8 gap) / 2 − 2×8 card − 22 icon − 4 gap
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          AddonApplyToItemToggle(itemController: items, index: 0),
          AddonQuantityControl(itemController: items, index: 0),
        ]),
      )))));
      await tester.pump();
      expect(find.text(_apply), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemBottomSheet (quick add and desktop)', () {
    testWidgets('same per add-on behaviour through the shared widgets', (WidgetTester tester) async {
      await start(tester);
      await pump(tester, Scaffold(body: ItemBottomSheet(itemId: 10, item: _food())));
      expect(find.text(_apply), findsNothing);

      await select(tester, _chicken);
      await select(tester, _plantain);
      expect(find.text(_apply), findsNWidgets(2));
      await tester.tap(find.text(_apply).first);
      await tester.pump();
      await setParent(tester, 3);
      expect(items.addOnQtyList.sublist(0, 2), <int>[3, 1]);
      await setParent(tester, 2);
      expect(items.addOnQtyList.sublist(0, 2), <int>[2, 1]);

      await select(tester, _chicken);
      expect(items.addOnActiveList[0], isFalse);
      expect(items.isAddOnFollowingItemQuantity(0), isFalse);
    });
  });
}
