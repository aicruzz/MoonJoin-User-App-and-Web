// Food Extras addon quantity. Before the redesign, mobile Food opened
// ItemBottomSheet, whose AddonView shows − qty + for a selected addon. The
// redesigned FoodDetailsScreen (commit 84fa9db) renders Extras in _ExtrasSection,
// which never rendered that control, so a selected addon was stuck at quantity 1.
// addOnQtyList, setAddOnQuantity, pricing and the add_on_qtys payload stayed intact.
// The page now renders the same control AddonView uses.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/item_bottom_sheet.dart';
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

/// The real ItemService logic for selection and quantity; only the fetch is faked.
class _ItemService extends ItemService {
  _ItemService() : super(itemRepositoryInterface: _ItemRepository());
  @override
  Future<Item?> getItemDetails(int? itemID, {int? moduleId}) async => _chickenItem();
}

class _Item extends ItemController {
  _Item() : super(itemServiceInterface: _ItemService());
  @override
  Future<int> setExistInCart(Item? item, List<List<bool?>>? selectedVariations, {bool notify = false}) async => -1;
}

const String _chicken = 'Extra Chicken';
const String _plantain = 'Extra Plantains';
const String _rice = 'Extra Rice';

Item _chickenItem() => Item.fromJson(<String, dynamic>{
  'id': 617, 'name': 'CatFish Barbecue', 'module_id': 3, 'module_type': 'food', 'store_id': 1, 'store_name': 'Chruzz', 'price': 10000, 'discount': 0,
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
  late _Item items;
  late _Cart cart;
  late SplashController splash;

  setUp(() async {
    Get.testMode = true;
    splash = SplashController(splashServiceInterface: _SplashService());
    items = _Item();
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
    tester.view.physicalSize = const Size(600 * 3, 1400 * 3); // mobile layout; everything on screen in the test font
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GetMaterialApp(home: screen));
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpFood(WidgetTester tester, {CartModel? editing}) async {
    await start(tester);
    await pump(tester, FoodDetailsScreen(itemId: 617, item: _chickenItem(), cart: editing));
  }

  /// The addon's own card, so the footer's item stepper is never matched.
  Finder card(String name) => find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first;
  Finder inCard(String name, IconData icon) => find.descendant(of: card(name), matching: find.byIcon(icon));
  Finder plus(String name) => inCard(name, Icons.add);
  Finder minus(String name) => inCard(name, Icons.remove);
  Finder trash(String name) => inCard(name, Icons.delete_outline_outlined);
  Finder count(String name, int quantity) => find.descendant(of: card(name), matching: find.text('$quantity'));

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> select(WidgetTester tester, String name) => tap(tester, find.text(name));

  group('FoodDetailsScreen addon quantity', () {
    testWidgets('unselected addon has no quantity control', (WidgetTester tester) async {
      await pumpFood(tester);
      expect(plus(_chicken), findsNothing);
      expect(trash(_chicken), findsNothing);
    });

    testWidgets('selecting an addon exposes its control, starting at 1', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      expect(plus(_chicken), findsOneWidget);
      expect(count(_chicken, 1), findsOneWidget);
      expect(items.addOnQtyList[0], 1);
    });

    testWidgets('increase and decrease change only that addon', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await tap(tester, plus(_chicken));
      await tap(tester, plus(_chicken));
      expect(count(_chicken, 3), findsOneWidget);
      await tap(tester, minus(_chicken));
      expect(count(_chicken, 2), findsOneWidget);
      expect(items.addOnQtyList, <int>[2, 1, 1]);
    });

    testWidgets('multiple selected addons keep independent quantities; others stay unselected', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await select(tester, _plantain);
      await tap(tester, plus(_chicken));
      await tap(tester, plus(_chicken));
      await tap(tester, plus(_plantain));
      expect(count(_chicken, 3), findsOneWidget);
      expect(count(_plantain, 2), findsOneWidget);
      expect(items.addOnActiveList, <bool>[true, true, false]);
      expect(plus(_rice), findsNothing);
    });

    testWidgets('decreasing at 1 deselects, as the existing add-on control does, and removes its cost', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await tap(tester, plus(_chicken));
      await tap(tester, minus(_chicken));
      expect(items.addOnActiveList[0], isTrue);

      await tap(tester, trash(_chicken));
      expect(items.addOnActiveList[0], isFalse);
      expect(plus(_chicken), findsNothing);
      final ItemCartData data = ItemCartHelper.compute(items.item!, items, true);
      expect(data.addonsCost, 0);
      expect(data.addOnIdList, isEmpty);
    });

    testWidgets('tapping the card selects and deselects at quantity 1, as before', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      expect(items.addOnActiveList[0], isTrue);
      await select(tester, _chicken);
      expect(items.addOnActiveList[0], isFalse);
    });

    testWidgets('reselecting after a deselect starts at 1 again', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await tap(tester, plus(_chicken));
      await tap(tester, minus(_chicken));
      await tap(tester, trash(_chicken));
      await select(tester, _chicken);
      expect(count(_chicken, 1), findsOneWidget);
    });

    testWidgets('pricing: price × quantity for selected addons only', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await select(tester, _plantain);
      await tap(tester, plus(_chicken));
      await tap(tester, plus(_chicken));
      await tap(tester, plus(_plantain));
      final ItemCartData data = ItemCartHelper.compute(items.item!, items, true);
      expect(data.addonsCost, 500 * 3 + 300 * 2);
      expect(data.priceWithDiscountAndAddons, 10000 + 500 * 3 + 300 * 2);
    });

    testWidgets('Add To Cart sends each selected addon with its quantity', (WidgetTester tester) async {
      await pumpFood(tester);
      await select(tester, _chicken);
      await select(tester, _plantain);
      await tap(tester, plus(_chicken));
      await tap(tester, plus(_chicken));
      await tap(tester, plus(_plantain));
      await tap(tester, find.text('add_to_cart'));

      expect(cart.added, isNotNull);
      expect(cart.added!.addOnIds, <int>[1, 2]);
      expect(cart.added!.addOnQtys, <int>[3, 2]);
      expect(double.parse(cart.added!.price!), 10000 + 500 * 3 + 300 * 2);
    });

    testWidgets('cart edit: saved quantity is shown, can change, and is sent', (WidgetTester tester) async {
      final CartModel line = CartModel(9, 10000, 11500, <Variation>[], <List<bool?>>[], 0, 1, <AddOn>[AddOn(id: 1, quantity: 3)], <AddOns>[], false, 0, _chickenItem(), null);
      await pumpFood(tester, editing: line);
      expect(count(_chicken, 3), findsOneWidget);
      await tap(tester, minus(_chicken));
      await tap(tester, find.text('update_in_cart'));
      expect(cart.updated!.addOnIds, <int>[1]);
      expect(cart.updated!.addOnQtys, <int>[2]);
    });
  });

  group('AddonQuantityControl', () {
    testWidgets('fits the narrowest Extras card (320pt phone) at a large quantity', (WidgetTester tester) async {
      await start(tester);
      await items.getItemDetails(itemId: 617);
      items.addAddOn(true, 0);
      for (int i = 0; i < 98; i++) {
        items.setAddOnQuantity(true, 0);
      }
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: Center(child: SizedBox(
        width: 82, // (320 − 2×16 page − 2×16 section − 8 gap) / 2 − 2×8 card − 22 icon − 4 gap
        child: AddonQuantityControl(itemController: items, index: 0),
      )))));
      await tester.pump();
      expect(find.text('99'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ItemBottomSheet addon quantity is unchanged', () {
    testWidgets('selected addon shows the control; quantity changes; trash deselects', (WidgetTester tester) async {
      await start(tester);
      await pump(tester, Scaffold(body: ItemBottomSheet(itemId: 617, item: _chickenItem())));
      expect(plus(_chicken), findsNothing);

      await select(tester, _chicken);
      await tap(tester, plus(_chicken));
      expect(count(_chicken, 2), findsOneWidget);
      await tap(tester, minus(_chicken));
      await tap(tester, trash(_chicken));
      expect(items.addOnActiveList[0], isFalse);
    });
  });
}
