// Quick add ("+" on an item card → ItemController.itemDirectlyAddToCart).
// (1) The details request carries the item's own module (the item-details
//     module-context mechanism): a Market item found by a search scoped to
//     Market while Groceries is active was requested as a Groceries item → 404.
//     The shared headers and the active module are never changed.
// (2) A failed details request returns quietly: it used to dereference the
//     missing item (_item!) and throw.
// (3) Items with variations open the existing sheet/details screen WITH the
//     fetched item, so their own details request keeps the item's module.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/item_bottom_sheet.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/models/cart_model.dart';
import 'package:moonjoin/features/checkout/domain/models/place_order_body_model.dart' show OnlineCart;
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/repositories/item_repository.dart';
import 'package:moonjoin/features/item/domain/services/item_service.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/item/screens/item_details_screen.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/app_constants.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}
class _CartService extends _NoSuch implements CartServiceInterface {}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  @override
  ModuleModel? get module => ModuleModel(id: 5, moduleType: 'grocery');
  @override
  ConfigModel? get configModel => ConfigModel(moduleConfig: ModuleConfig(module: Module(stock: false, showRestaurantText: false, addOn: false)));
  @override
  Module getModuleConfig(String? moduleType) => Module(newVariation: false);
}

/// Records cart adds; never another store's item in the cart.
class _Cart extends CartController {
  _Cart() : super(cartServiceInterface: _CartService());
  final List<OnlineCart> added = <OnlineCart>[];
  @override
  bool existAnotherStoreItem(int? storeID, int? moduleId) => false;
  @override
  Future<bool> addToCartOnline(OnlineCart cart) async {
    added.add(cart);
    return true;
  }
}

/// Shared headers as the app holds them; records each GET's headers.
class _ApiClient extends GetxService implements ApiClient {
  final Map<String, String> shared = <String, String>{AppConstants.moduleId: '5', AppConstants.zoneId: '[7]', AppConstants.localizationKey: 'en'};
  final List<Map<String, String>?> sentHeaders = <Map<String, String>?>[];
  final List<Response> answers = <Response>[];
  @override
  Map<String, String> getHeader() => shared;
  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    sentHeaders.add(headers == null ? null : Map<String, String>.from(headers));
    return answers.removeAt(0);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records the module of each details request; the follow-on screen's own
/// request is held so it stays in its loading state.
class _RecordingItemService extends _NoSuch implements ItemServiceInterface {
  final List<int?> moduleIds = <int?>[];
  Item? firstAnswer;
  @override
  Future<Item?> getItemDetails(int? itemID, {int? moduleId}) {
    moduleIds.add(moduleId);
    if (moduleIds.length == 1) return Future<Item?>.value(firstAnswer);
    return Completer<Item?>().future;
  }
}

/// Real getItemDetails / itemDirectlyAddToCart; variation/cart preparation recorded only.
class _Item extends ItemController {
  _Item(ItemServiceInterface service) : super(itemServiceInterface: service);
  @override
  void initData(Item? item, CartModel? cart) {}
  @override
  Future<int> setExistInCart(Item? item, List<List<bool?>>? selectedVariations, {bool notify = false}) async => -1;
}

Map<String, dynamic> _json(int id, int moduleId) => <String, dynamic>{
      'id': id, 'name': 'Rice / Perfume / Basmati', 'module_id': moduleId, 'module_type': 'grocery', 'store_id': 10,
      'price': 4500, 'discount': 0, 'discount_type': 'percent', 'variations': <dynamic>[], 'stock': 10,
    };

Item _searchResult(int moduleId) => Item(id: 609, name: 'Rice / Perfume / Basmati', moduleId: moduleId, moduleType: 'grocery', price: 4500, discount: 0);

void main() {
  late _Cart cart;
  late _Splash splash;
  late List<RouteSettings> pushed;

  Future<BuildContext> pumpApp(WidgetTester tester) async {
    pushed = <RouteSettings>[];
    await tester.pumpWidget(GetMaterialApp(
      navigatorObservers: <NavigatorObserver>[_Pushes(pushed)],
      home: const Scaffold(body: Text('search results')),
      getPages: <GetPage<dynamic>>[
        GetPage<dynamic>(name: RouteHelper.itemDetails, page: () => const Scaffold(body: Text('item details'))),
      ],
    ));
    pushed.clear();
    return tester.element(find.text('search results'));
  }

  setUp(() {
    Get.testMode = true;
    splash = _Splash();
    cart = _Cart();
    Get.put<SplashController>(splash);
    Get.put<CartController>(cart);
  });

  tearDown(Get.reset);

  group('through the real item service/repository (request headers)', () {
    late _ApiClient api;
    late _Item controller;
    late Map<String, String> sharedBefore;

    setUp(() {
      api = _ApiClient();
      controller = _Item(ItemService(itemRepositoryInterface: ItemRepository(apiClient: api)));
      Get.put<ItemController>(controller);
      sharedBefore = Map<String, String>.from(api.shared);
    });

    testWidgets('cross-module quick add: details request carries the item module; active module and shared headers unchanged; added once', (WidgetTester tester) async {
      final BuildContext context = await pumpApp(tester);
      api.answers.add(Response(statusCode: 200, body: _json(609, 10)));

      controller.itemDirectlyAddToCart(_searchResult(10), context);
      await tester.pump();

      expect(api.sentHeaders.single![AppConstants.moduleId], '10');
      expect(api.shared, sharedBefore, reason: 'shared headers not mutated');
      expect(splash.module?.id, 5, reason: 'active module unchanged (no setModule)');
      expect(cart.added, hasLength(1));
      expect(cart.added.single.itemId, 609);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('same-module quick add: usual headers, added once, as before', (WidgetTester tester) async {
      final BuildContext context = await pumpApp(tester);
      api.answers.add(Response(statusCode: 200, body: _json(273, 5)));

      controller.itemDirectlyAddToCart(Item(id: 273, name: 'Grapes', moduleId: 5, moduleType: 'grocery'), context);
      await tester.pump();

      expect(api.sentHeaders.single, isNull, reason: 'null → ApiClient uses its shared headers');
      expect(api.shared, sharedBefore);
      expect(cart.added.single.itemId, 273);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('details not found (404) or offline: returns quietly — no null-check crash, nothing added', (WidgetTester tester) async {
      final BuildContext context = await pumpApp(tester);
      api.answers.add(const Response(statusCode: 404, body: <String, dynamic>{'errors': <String, dynamic>{'code': 'product-001', 'message': 'Not found'}}));

      controller.itemDirectlyAddToCart(_searchResult(10), context);
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'used to throw on _item!');
      expect(cart.added, isEmpty);
      expect(controller.itemLoadFailed, isTrue, reason: 'failed-details state kept');
      expect(pushed, isEmpty, reason: 'no follow-on screen');
    });
  });

  group('follow-on screens keep the fetched item (and its module)', () {
    late _RecordingItemService service;
    late _Item controller;

    setUp(() {
      service = _RecordingItemService();
      controller = _Item(service);
      Get.put<ItemController>(controller);
    });

    testWidgets('food with variations: ItemBottomSheet gets the item; its own request keeps module 10', (WidgetTester tester) async {
      final BuildContext context = await pumpApp(tester);
      service.firstAnswer = Item(
        id: 700, name: 'Jollof', moduleId: 10, moduleType: AppConstants.food, price: 2000, discount: 0, storeId: 10,
        foodVariations: <FoodVariation>[FoodVariation(name: 'Size', multiSelect: false, required: true, variationValues: <VariationValue>[])],
      );

      controller.itemDirectlyAddToCart(Item(id: 700, name: 'Jollof', moduleId: 10, moduleType: AppConstants.food), context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final ItemBottomSheet sheet = tester.widget<ItemBottomSheet>(find.byType(ItemBottomSheet));
      expect(sheet.item?.moduleId, 10);
      expect(service.moduleIds, <int?>[10, 10], reason: 'quick add and the sheet both ask with the item module');
      expect(cart.added, isEmpty);
    });

    testWidgets('other item with variations: ItemDetailsScreen gets the item (module 10)', (WidgetTester tester) async {
      final BuildContext context = await pumpApp(tester);
      service.firstAnswer = Item(
        id: 609, name: 'Rice', moduleId: 10, moduleType: 'grocery', price: 4500, discount: 0, storeId: 10,
        variations: <Variation>[Variation(type: '1kg', price: 4500, stock: 3)],
      );

      controller.itemDirectlyAddToCart(_searchResult(10), context);
      await tester.pump();

      final RouteSettings route = pushed.single;
      expect(route.name, startsWith(RouteHelper.itemDetails));
      final ItemDetailsScreen screen = route.arguments as ItemDetailsScreen;
      expect(screen.item?.moduleId, 10);
      expect(screen.isCampaign, isFalse);
      expect(service.moduleIds, <int?>[10]);
      expect(cart.added, isEmpty);
    });
  });
}

class _Pushes extends NavigatorObserver {
  _Pushes(this.settings);
  final List<RouteSettings> settings;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null && route.settings.name != '/') settings.add(route.settings);
  }
}
