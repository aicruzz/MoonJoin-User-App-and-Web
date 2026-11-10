// False "Out of Stock" on item details. Stock is tracked per module: production
// config has grocery/pharmacy/ecommerce stock=true and food stock=false, and a
// food item is stored with stock=0 by design. The details screens read the flag
// from configModel.moduleConfig.module, a single mutable value that:
//  - a config response rebuilds from module_type[0] (grocery) while a module is
//    active, so the network config finishing after the customer opened Food left
//    Food reading grocery's flag for the rest of the session; and
//  - follows the active module, not the module of the item on screen.
// The flag now follows the item's own module, and a config response keeps the
// active module's config. Genuine out of stock still disables Add To Cart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/features/auth/domain/services/auth_service_interface.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/models/cart_model.dart';
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/repositories/item_repository.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/item/screens/food_details_screen.dart';
import 'package:moonjoin/features/item/screens/item_details_screen.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';

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
  final List<bool> quantityStockFlags = <bool>[];
  @override
  int? getCartId(int cartIndex, List<CartModel> cartList) => null;
  @override
  Future<int> decideItemQuantity(bool isIncrement, List<CartModel> cartList, int cartIndex, int? stock, int? quantityLimit, bool moduleStock) async {
    quantityStockFlags.add(moduleStock);
    return cartList[cartIndex].quantity!;
  }
  @override
  Future<double> calculateDiscountedPrice(CartModel cartModel, int quantity, bool isFood) async => 0;
}

class _Cart extends CartController {
  _Cart(_CartService service) : super(cartServiceInterface: service);
  @override
  double calculationCart() => 0;
  @override
  Future<void> updateCartQuantityOnline(int cartId, double price, int quantity) async {}
}

/// Answers every GET with [answer], as ApiClient does for failures (status 1 = no
/// connection or timeout, an empty Response = a server error already handled).
class _ApiClient extends GetxService implements ApiClient {
  Response answer = const Response();
  @override
  Map<String, String> getHeader() => <String, String>{};
  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async => answer;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Same module_config shape and values as production /api/v1/config.
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
    'module_type': <String>['grocery', 'food', 'pharmacy', 'ecommerce', 'parcel', 'rental'],
    'grocery': _moduleConfig(stock: true, addOn: false, food: false),
    'food': _moduleConfig(stock: false, addOn: true, food: true),
    'pharmacy': _moduleConfig(stock: true, addOn: false, food: false),
    'ecommerce': _moduleConfig(stock: true, addOn: false, food: false),
  },
};

/// Cached config answers at once; the network config waits on [network] when set.
class _SplashService extends _NoSuch implements SplashServiceInterface {
  Completer<void>? network;
  int setModuleCalls = 0;
  ModuleModel? cache;
  @override
  bool? showIntro() => false;
  @override
  Future<Response> getConfigData({required DataSourceEnum source}) async {
    if (source == DataSourceEnum.client && network != null) await network!.future;
    return Response(statusCode: 200, body: _config());
  }
  @override
  Future<void> setModule(ModuleModel? module) async => setModuleCalls++;
  @override
  Future<ModuleModel?> setCacheModule(ModuleModel? module) async => cache = module;
  @override
  ModuleModel? getCacheModule() => cache;
}

class _ItemService extends _NoSuch implements ItemServiceInterface {
  final List<Item?> answers = <Item?>[];
  int requests = 0;
  Completer<void>? hold;
  final List<bool> quantityStockFlags = <bool>[];
  @override
  Future<Item?> getItemDetails(int? itemID, {int? moduleId}) async {
    requests++;
    if (hold != null) await hold!.future;
    return answers.removeAt(0);
  }
  @override
  List<List<bool?>> initializeSelectedVariation(List<FoodVariation>? foodVariations) => <List<bool?>>[];
  @override
  List<bool> initializeCollapseVariation(List<FoodVariation>? foodVariations) => <bool>[];
  @override
  List<int> initializeVariationIndexes(List<ChoiceOptions>? choiceOptions) => <int>[];
  @override
  List<bool> initializeAddonActiveList(List<AddOns>? addOns) => <bool>[];
  @override
  List<int> initializeAddonQtyList(List<AddOns>? addOns) => <int>[];
  @override
  Future<int> setQuantity(bool isIncrement, bool moduleStock, int? stock, int qty, int? quantityLimit, {bool getxSnackBar = false}) async {
    quantityStockFlags.add(moduleStock);
    return qty;
  }
}

class _Item extends ItemController {
  _Item(_ItemService service) : super(itemServiceInterface: service);
  @override
  Future<int> setExistInCart(Item? item, List<List<bool?>>? selectedVariations, {bool notify = false}) async => -1;
}

Item _catfish({int stock = 0}) => Item.fromJson(<String, dynamic>{
  'id': 617, 'name': 'CatFish Barbecue', 'module_id': 3, 'module_type': 'food', 'store_id': 1, 'store_name': 'Chruzz', 'price': 10000, 'discount': 0,
  'discount_type': 'percent', 'stock': stock, 'schedule_order': true, 'veg': 0, 'avg_rating': 0, 'rating_count': 0,
  'variations': <dynamic>[], 'food_variations': <dynamic>[], 'choice_options': <dynamic>[], 'add_ons': <dynamic>[], 'attributes': <dynamic>[],
  'available_time_starts': '00:00:00', 'available_time_ends': '23:59:59',
});

Item _rice({int stock = 0}) => Item.fromJson(<String, dynamic>{
  'id': 609, 'name': 'Basmati Rice', 'module_id': 5, 'module_type': 'grocery', 'store_id': 2, 'store_name': 'Mart', 'price': 4500, 'discount': 0,
  'discount_type': 'percent', 'stock': stock, 'schedule_order': true, 'veg': 0, 'avg_rating': 0, 'rating_count': 0,
  'variations': <dynamic>[], 'food_variations': <dynamic>[], 'choice_options': <dynamic>[], 'add_ons': <dynamic>[], 'attributes': <dynamic>[],
  'available_time_starts': '00:00:00', 'available_time_ends': '23:59:59',
});

final ModuleModel _food = ModuleModel(id: 3, moduleType: 'food');
final ModuleModel _grocery = ModuleModel(id: 5, moduleType: 'grocery');

void main() {
  late _SplashService splashService;
  late SplashController splash;
  late _ItemService itemService;
  late _Item items;
  late _CartService cartService;
  late DateTime now;

  setUp(() {
    Get.testMode = true;
    splashService = _SplashService();
    splash = SplashController(splashServiceInterface: splashService);
    itemService = _ItemService();
    items = _Item(itemService);
    cartService = _CartService();
    now = DateTime(2026, 11, 4, 8);
    items.availabilityClock = () => now;
    Get.put<AuthController>(_Auth());
    Get.put<SplashController>(splash);
    Get.put<CartController>(_Cart(cartService));
    Get.put<FavouriteController>(FavouriteController(favouriteServiceInterface: _FavouriteService()));
    Get.put<ItemController>(items);
  });

  tearDown(Get.reset);

  /// Cold start: cached config, then (optionally held) network config.
  Future<void> loadConfig() => splash.getConfigData(routeAfterLoad: false);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(600 * 3, 900 * 3); // mobile layout; wide enough for the test font
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GetMaterialApp(home: screen));
    await tester.pump();
    await tester.pump();
  }

  CustomButton cartButton(WidgetTester tester, String text) =>
      tester.widget<CustomButton>(find.ancestor(of: find.text(text), matching: find.byType(CustomButton)));

  group('config response while a module is active', () {
    test('network config finishing after the customer opened Food keeps Food\'s flag (the idle cold-start race)', () async {
      splashService.network = Completer<void>();
      await loadConfig();
      await splash.setModule(_food);
      expect(splash.configModel!.moduleConfig!.module!.stock, isFalse);

      splashService.network!.complete();
      await pumpEventQueue();

      expect(splash.configModel!.moduleConfig!.module!.stock, isFalse, reason: 'a config refresh must not switch Food to grocery\'s config');
      expect(splash.configModel!.moduleConfig!.module!.addOn, isTrue, reason: 'every module field is restored, not only stock');
    });

    test('active Grocery keeps its stock tracking after a config response', () async {
      splashService.network = Completer<void>();
      await loadConfig();
      await splash.setModule(_grocery);
      splashService.network!.complete();
      await pumpEventQueue();
      expect(splash.configModel!.moduleConfig!.module!.stock, isTrue);
    });

    test('the refresh restores config only: no module side effects are repeated', () async {
      splashService.network = Completer<void>();
      await loadConfig();
      await splash.setModule(_food);
      final int calls = splashService.setModuleCalls;
      splashService.network!.complete();
      await pumpEventQueue();
      expect(splashService.setModuleCalls, calls);
    });

    test('no active module: config response behaves as before', () async {
      await loadConfig();
      await pumpEventQueue();
      expect(splash.module, isNull);
      expect(splash.configModel!.moduleConfig!.module!.stock, isTrue, reason: 'module_type[0] default unchanged');
    });
  });

  group('item details button', () {
    testWidgets('food item (stock 0), Food active, network config arrived after opening Food: Add To Cart', (WidgetTester tester) async {
      splashService.network = Completer<void>();
      await loadConfig();
      await tester.pump(); // network config finished before the module opens
      await splash.setModule(_food);
      splashService.network!.complete();
      await tester.pump();

      itemService.answers.add(_catfish());
      await pump(tester, FoodDetailsScreen(itemId: 617, item: _catfish()));

      expect(find.text('out_of_stock'), findsNothing);
      expect(cartButton(tester, 'add_to_cart').onPressed, isNotNull);
    });

    testWidgets('food item (stock 0) opened while Grocery is active, e.g. a Food-scoped search: Add To Cart', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump(); // network config finished before the module opens
      await splash.setModule(_grocery);
      itemService.answers.add(_catfish());
      await pump(tester, FoodDetailsScreen(itemId: 617, item: _catfish()));

      expect(find.text('out_of_stock'), findsNothing);
      expect(cartButton(tester, 'add_to_cart').onPressed, isNotNull);
    });

    testWidgets('food item (stock 0) opened with no active module and a Grocery cache: Add To Cart', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump(); // network config finished before the module opens
      await splash.setModule(_grocery);
      await splash.setModule(null);
      expect(splash.cacheModule?.moduleType, 'grocery');
      itemService.answers.add(_catfish());
      await pump(tester, FoodDetailsScreen(itemId: 617, item: _catfish()));

      expect(find.text('out_of_stock'), findsNothing);
      expect(cartButton(tester, 'add_to_cart').onPressed, isNotNull);
    });

    testWidgets('grocery item genuinely out of stock: disabled Out of Stock', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump(); // network config finished before the module opens
      await splash.setModule(_grocery);
      itemService.answers.add(_rice());
      await pump(tester, ItemDetailsScreen(itemId: 609, inStorePage: false, item: _rice()));

      expect(find.text('add_to_cart'), findsNothing);
      expect(cartButton(tester, 'out_of_stock').onPressed, isNull);
    });

    testWidgets('grocery item out of stock opened while Food is active is still blocked', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump(); // network config finished before the module opens
      await splash.setModule(_food);
      itemService.answers.add(_rice());
      await pump(tester, ItemDetailsScreen(itemId: 609, inStorePage: false, item: _rice()));

      expect(find.text('add_to_cart'), findsNothing);
      expect(cartButton(tester, 'out_of_stock').onPressed, isNull);
    });

    testWidgets('grocery item in stock: Add To Cart', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump(); // network config finished before the module opens
      await splash.setModule(_grocery);
      itemService.answers.add(_rice(stock: 8));
      await pump(tester, ItemDetailsScreen(itemId: 609, inStorePage: false, item: _rice(stock: 8)));

      expect(find.text('out_of_stock'), findsNothing);
      expect(cartButton(tester, 'add_to_cart').onPressed, isNotNull);
    });

    testWidgets('failed details request is never presented as Out of Stock', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump(); // network config finished before the module opens
      await splash.setModule(_grocery);
      itemService.answers.add(null);
      await pump(tester, ItemDetailsScreen(itemId: 609, inStorePage: false, item: _rice()));

      expect(find.text('out_of_stock'), findsNothing);
      expect(find.text('try_again'), findsOneWidget);
    });
  });

  group('stock module of the item, not of the active module', () {
    test('isStockManaged follows the requested module whichever module is active', () async {
      await loadConfig();
      await pumpEventQueue();
      await splash.setModule(_grocery);
      expect(splash.isStockManaged('food'), isFalse);
      expect(splash.isStockManaged('grocery'), isTrue);
      await splash.setModule(_food);
      expect(splash.isStockManaged('food'), isFalse);
      expect(splash.isStockManaged('pharmacy'), isTrue);
    });

    test('unknown or missing module type falls back to the active module', () async {
      await loadConfig();
      await pumpEventQueue();
      await splash.setModule(_food);
      expect(splash.isStockManaged(null), isFalse);
      expect(splash.isStockManaged('unknown'), isFalse);
      await splash.setModule(_grocery);
      expect(splash.isStockManaged(null), isTrue);
    });

    test('details quantity stepper validates against the item\'s module', () async {
      await loadConfig();
      await pumpEventQueue();
      await splash.setModule(_grocery);
      itemService.answers.add(_catfish());
      await items.getItemDetails(itemId: 617, moduleId: 3);
      await items.setQuantity(true, 0, null);
      itemService.answers.add(_rice(stock: 1));
      await items.getItemDetails(itemId: 609, moduleId: 5);
      await items.setQuantity(true, 1, null);
      expect(itemService.quantityStockFlags, <bool>[false, true], reason: 'food untracked, grocery still validated');
    });

    testWidgets('cart stepper validates each line against its own module', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump();
      await splash.setModule(_grocery);
      final CartController cart = Get.find<CartController>();
      cart.cartList.addAll(<CartModel>[
        CartModel(1, 10000, 0, <Variation>[], <List<bool?>>[], 0, 1, <AddOn>[], <AddOns>[], false, 0, _catfish(), null),
        CartModel(2, 4500, 0, <Variation>[], <List<bool?>>[], 0, 1, <AddOn>[], <AddOns>[], false, 1, _rice(stock: 1), null),
      ]);
      await cart.setQuantity(true, 0, 0, null);
      await cart.setQuantity(true, 1, 1, null);
      await tester.pump(const Duration(milliseconds: 600)); // debounced sync
      expect(cartService.quantityStockFlags, <bool>[false, true]);
    });
  });

  group('availability refresh on resume', () {
    const Duration idle = Duration(hours: 6);

    Future<void> loadItem(Item item) async {
      await loadConfig();
      await pumpEventQueue();
      await splash.setModule(_grocery);
      itemService.answers.add(item);
      await items.getItemDetails(itemId: item.id!, moduleId: item.moduleId);
      itemService.requests = 0;
    }

    test('resume before availability is stale: no request', () async {
      await loadItem(_rice(stock: 3));
      now = now.add(ItemController.itemAvailabilityStaleAfter - const Duration(seconds: 1));
      await items.refreshItemAvailability();
      expect(itemService.requests, 0);
    });

    test('long idle, unavailable to available: stock updated', () async {
      await loadItem(_rice());
      now = now.add(idle);
      itemService.answers.add(_rice(stock: 8));
      await items.refreshItemAvailability();
      expect(items.item!.stock, 8);
    });

    test('long idle, available to unavailable: stock updated', () async {
      await loadItem(_rice(stock: 8));
      now = now.add(idle);
      itemService.answers.add(_rice());
      await items.refreshItemAvailability();
      expect(items.item!.stock, 0);
    });

    test('refresh updates variation stock and keeps the customer\'s quantity', () async {
      Item withVariation(int stock) {
        final Item item = _rice(stock: 8);
        item.variations = <Variation>[Variation(type: '5kg', price: 4500, stock: stock)];
        return item;
      }
      await loadItem(withVariation(0));
      await items.setQuantity(true, 1, null);
      final int? quantity = items.quantity;
      final List<int>? selection = items.variationIndex;
      now = now.add(idle);
      itemService.answers.add(withVariation(4));
      await items.refreshItemAvailability();
      expect(items.item!.variations!.single.stock, 4);
      expect(items.quantity, quantity);
      expect(identical(items.variationIndex, selection), isTrue);
    });

    test('network failure or timeout: last known stock kept, retried on the next resume', () async {
      await loadItem(_rice(stock: 8));
      now = now.add(idle);
      itemService.answers.add(null);
      await items.refreshItemAvailability();
      expect(items.item!.stock, 8, reason: 'a failed request is not proof of zero stock');
      expect(items.itemLoadFailed, isFalse, reason: 'the loaded page is not replaced by an error');

      itemService.answers.add(_rice(stock: 2));
      await items.refreshItemAvailability();
      expect(items.item!.stock, 2);
      expect(itemService.requests, 2);
    });

    test('repeated resumes: one request in flight, then none until stale again', () async {
      await loadItem(_rice(stock: 8));
      now = now.add(idle);
      itemService.answers.add(_rice(stock: 7));
      itemService.hold = Completer<void>();
      final List<Future<void>> resumes = <Future<void>>[for (int i = 0; i < 5; i++) items.refreshItemAvailability()];
      expect(itemService.requests, 1);
      itemService.hold!.complete();
      await Future.wait(resumes);
      itemService.hold = null;

      for (int i = 0; i < 5; i++) {
        await items.refreshItemAvailability();
      }
      expect(itemService.requests, 1);
    });

    test('a response for an item the customer left is ignored', () async {
      await loadItem(_rice(stock: 8));
      now = now.add(idle);
      final Completer<void> slowRefresh = itemService.hold = Completer<void>();
      final Future<void> refresh = items.refreshItemAvailability();
      itemService.hold = null;
      itemService.answers.add(_catfish());
      await items.getItemDetails(itemId: 617, moduleId: 3);
      itemService.answers.add(_rice());
      slowRefresh.complete();
      await refresh;
      expect(items.item!.id, 617);
      expect(items.item!.stock, 0);
    });

    test('campaign item from a passed payload: never refreshed', () async {
      await loadConfig();
      await pumpEventQueue();
      await splash.setModule(_food);
      await items.getItemDetails(itemId: 617, item: _catfish(), moduleId: 3);
      now = now.add(idle);
      await items.refreshItemAvailability();
      expect(itemService.requests, 0);
    });

    testWidgets('real resume on the page updates the button; leaving the page stops refreshes', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump();
      await splash.setModule(_grocery);
      itemService.answers.add(_rice());
      await pump(tester, ItemDetailsScreen(itemId: 609, inStorePage: false, item: _rice()));
      expect(cartButton(tester, 'out_of_stock').onPressed, isNull);
      itemService.requests = 0;

      Future<void> backgroundAndResume() async {
        for (final AppLifecycleState state in <AppLifecycleState>[AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pump();
        await tester.pump();
      }

      await backgroundAndResume();
      expect(itemService.requests, 0, reason: 'not stale yet');

      now = now.add(idle);
      itemService.answers.add(_rice(stock: 8));
      await backgroundAndResume();
      expect(itemService.requests, 1);
      expect(find.text('out_of_stock'), findsNothing);
      expect(cartButton(tester, 'add_to_cart').onPressed, isNotNull);

      await tester.pumpWidget(const SizedBox());
      now = now.add(idle);
      await backgroundAndResume();
      expect(itemService.requests, 1, reason: 'no request once the page is gone');
    });

    testWidgets('resume with a failed refresh keeps Add To Cart on an in-stock item', (WidgetTester tester) async {
      await loadConfig();
      await tester.pump();
      await splash.setModule(_grocery);
      itemService.answers.add(_rice(stock: 8));
      await pump(tester, ItemDetailsScreen(itemId: 609, inStorePage: false, item: _rice(stock: 8)));

      now = now.add(idle);
      itemService.answers.add(null);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();

      expect(itemService.requests, greaterThan(0));
      expect(find.text('out_of_stock'), findsNothing);
      expect(cartButton(tester, 'add_to_cart').onPressed, isNotNull);
    });
  });

  group('details request failures are not an item', () {
    late _ApiClient api;
    late ItemRepository repository;

    setUp(() {
      api = _ApiClient();
      repository = ItemRepository(apiClient: api);
    });

    test('no connection or timeout (status 1)', () async {
      api.answer = const Response(statusCode: 1, statusText: 'connection_to_api_server_failed');
      expect(await repository.get('617', moduleId: 3), isNull);
    });

    test('server error already handled by ApiClient', () async {
      api.answer = const Response();
      expect(await repository.get('617', moduleId: 3), isNull);
    });

    test('200 with a non-JSON body from the edge', () async {
      api.answer = const Response(statusCode: 200, body: '<html>Please wait</html>');
      expect(await repository.get('617', moduleId: 3), isNull);
    });

    test('200 with an item', () async {
      api.answer = const Response(statusCode: 200, body: <String, dynamic>{'id': 617, 'name': 'CatFish Barbecue', 'module_type': 'food', 'stock': 0, 'price': 10000, 'discount': 0});
      final Item? item = await repository.get('617', moduleId: 3);
      expect(item?.stock, 0);
    });
  });
}
