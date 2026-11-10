// Food Extras follow the item's module. The Extras gate read the add_on flag from
// configModel.moduleConfig.module, which holds the active module's config, or
// module_type[0] (grocery, add_on=false) when no module is active. A Food item
// opened from a Food-scoped search while another module was active, or with no
// active module, was orderable with its Extras hidden. The gate now reads the
// flag of the item's own module on both surfaces: FoodDetailsScreen and the
// quick-add ItemBottomSheet. An item without Extras still shows none.

import 'dart:async';

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
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/item/screens/food_details_screen.dart';
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
  @override
  int? getCartId(int cartIndex, List<CartModel> cartList) => null;
}

Map<String, dynamic> _moduleConfig({required bool stock, required bool addOn, required bool food}) => <String, dynamic>{
  'stock': stock, 'add_on': addOn, 'show_restaurant_text': food, 'veg_non_veg': food, 'unit': !food, 'order_attachment': false,
  'order_place_to_schedule_interval': !food, 'always_open': false, 'all_zone_service': false, 'item_available_time': food,
  'is_parcel': false, 'organic': !food, 'cutlery': food, 'common_condition': false, 'nutrition': true, 'allergy': true,
  'basic': false, 'halal': true, 'brand': false, 'generic_name': false, 'is_rental': false,
};

/// Same module flags and order as production /api/v1/config.
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

class _SplashService extends _NoSuch implements SplashServiceInterface {
  Completer<void>? network;
  ModuleModel? cache;
  @override
  bool? showIntro() => false;
  @override
  Future<Response> getConfigData({required DataSourceEnum source}) async {
    if (source == DataSourceEnum.client && network != null) await network!.future;
    return Response(statusCode: 200, body: _config());
  }
  @override
  Future<void> setModule(ModuleModel? module) async {}
  @override
  Future<ModuleModel?> setCacheModule(ModuleModel? module) async => cache = module;
  @override
  ModuleModel? getCacheModule() => cache;
}

class _ItemService extends _NoSuch implements ItemServiceInterface {
  final List<Item?> answers = <Item?>[];
  @override
  Future<Item?> getItemDetails(int? itemID, {int? moduleId}) async => answers.removeAt(0);
  @override
  List<List<bool?>> initializeSelectedVariation(List<FoodVariation>? foodVariations) => <List<bool?>>[];
  @override
  List<bool> initializeCollapseVariation(List<FoodVariation>? foodVariations) => <bool>[];
  @override
  List<int> initializeVariationIndexes(List<ChoiceOptions>? choiceOptions) => <int>[];
  @override
  List<bool> initializeAddonActiveList(List<AddOns>? addOns) => List<bool>.filled(addOns?.length ?? 0, false, growable: true);
  @override
  List<int> initializeAddonQtyList(List<AddOns>? addOns) => List<int>.filled(addOns?.length ?? 0, 1, growable: true);
}

class _Item extends ItemController {
  _Item(_ItemService service) : super(itemServiceInterface: service);
  @override
  Future<int> setExistInCart(Item? item, List<List<bool?>>? selectedVariations, {bool notify = false}) async => -1;
}

const String _extraName = 'Extra Pepper';

Item _item({required int id, required int moduleId, required String moduleType, required List<dynamic> addOns}) => Item.fromJson(<String, dynamic>{
  'id': id, 'name': 'Item $id', 'module_id': moduleId, 'module_type': moduleType, 'store_id': 1, 'store_name': 'Chruzz', 'price': 10000, 'discount': 0,
  'discount_type': 'percent', 'stock': 5, 'schedule_order': true, 'veg': 0, 'avg_rating': 0, 'rating_count': 0,
  'variations': <dynamic>[], 'food_variations': <dynamic>[], 'choice_options': <dynamic>[], 'add_ons': addOns, 'attributes': <dynamic>[],
  'available_time_starts': '00:00:00', 'available_time_ends': '23:59:59',
});

const List<dynamic> _extras = <dynamic>[<String, dynamic>{'id': 1, 'name': _extraName, 'price': 500}];

Item _foodWithExtras() => _item(id: 617, moduleId: 3, moduleType: 'food', addOns: _extras);
Item _foodWithoutExtras() => _item(id: 618, moduleId: 3, moduleType: 'food', addOns: <dynamic>[]);
Item _groceryWithAddOnData() => _item(id: 609, moduleId: 5, moduleType: 'grocery', addOns: _extras);

final ModuleModel _food = ModuleModel(id: 3, moduleType: 'food');
final ModuleModel _grocery = ModuleModel(id: 5, moduleType: 'grocery');

void main() {
  late _SplashService splashService;
  late SplashController splash;
  late _ItemService itemService;
  late _Item items;

  setUp(() {
    Get.testMode = true;
    splashService = _SplashService();
    splash = SplashController(splashServiceInterface: splashService);
    itemService = _ItemService();
    items = _Item(itemService);
    Get.put<AuthController>(_Auth());
    Get.put<SplashController>(splash);
    Get.put<CartController>(CartController(cartServiceInterface: _CartService()));
    Get.put<FavouriteController>(FavouriteController(favouriteServiceInterface: _FavouriteService()));
    Get.put<ItemController>(items);
  });

  tearDown(Get.reset);

  /// Config fully loaded (cached, then network), then the given module opened.
  Future<void> start(WidgetTester tester, ModuleModel? module) async {
    await splash.getConfigData(routeAfterLoad: false);
    await tester.pump();
    await splash.setModule(module);
  }

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(600 * 3, 900 * 3); // mobile layout; wide enough for the test font
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GetMaterialApp(home: screen));
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpFood(WidgetTester tester, Item item) async {
    itemService.answers.add(item);
    await pump(tester, FoodDetailsScreen(itemId: item.id!, item: item));
  }

  Future<void> pumpSheet(WidgetTester tester, Item item) async {
    itemService.answers.add(item);
    await pump(tester, Scaffold(body: ItemBottomSheet(itemId: item.id!, item: item)));
  }

  group('FoodDetailsScreen', () {
    testWidgets('Food item, Food active: Extras shown', (WidgetTester tester) async {
      await start(tester, _food);
      await pumpFood(tester, _foodWithExtras());
      expect(find.text('extras'), findsOneWidget);
      expect(find.text(_extraName), findsOneWidget);
    });

    testWidgets('Food item, Grocery active: Extras shown and selectable', (WidgetTester tester) async {
      await start(tester, _grocery);
      await pumpFood(tester, _foodWithExtras());
      expect(find.text('extras'), findsOneWidget);
      expect(find.text(_extraName), findsOneWidget);

      await tester.ensureVisible(find.text(_extraName));
      await tester.pump();
      await tester.tap(find.text(_extraName));
      await tester.pump();
      expect(items.addOnActiveList, <bool>[true]);
    });

    testWidgets('Food item, no active module and a Grocery cache: Extras shown', (WidgetTester tester) async {
      await start(tester, _grocery);
      await splash.setModule(null);
      await pumpFood(tester, _foodWithExtras());
      expect(find.text('extras'), findsOneWidget);
    });

    testWidgets('Food item, no active module and no cache: Extras shown', (WidgetTester tester) async {
      await start(tester, null);
      expect(splash.cacheModule, isNull);
      await pumpFood(tester, _foodWithExtras());
      expect(find.text('extras'), findsOneWidget);
    });

    testWidgets('Food item, network config arrives while no module is active: Extras stay', (WidgetTester tester) async {
      splashService.network = Completer<void>();
      await splash.getConfigData(routeAfterLoad: false);
      await tester.pump();
      await pumpFood(tester, _foodWithExtras());
      splashService.network!.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('extras'), findsOneWidget);
    });

    testWidgets('Food item without Extras: section absent whichever module is active', (WidgetTester tester) async {
      await start(tester, _food);
      await pumpFood(tester, _foodWithoutExtras());
      expect(find.text('extras'), findsNothing);
      expect(find.text('add_to_cart'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await splash.setModule(_grocery);
      await pumpFood(tester, _foodWithoutExtras());
      expect(find.text('extras'), findsNothing);
      expect(find.text('add_to_cart'), findsOneWidget);
    });
  });

  group('ItemBottomSheet (quick add)', () {
    testWidgets('Food item, Food active: add-ons shown', (WidgetTester tester) async {
      await start(tester, _food);
      await pumpSheet(tester, _foodWithExtras());
      expect(find.text(_extraName), findsOneWidget);
    });

    testWidgets('Food item, Grocery active: add-ons shown', (WidgetTester tester) async {
      await start(tester, _grocery);
      await pumpSheet(tester, _foodWithExtras());
      expect(find.text(_extraName), findsOneWidget);
    });

    testWidgets('Food item, no active module: add-ons shown', (WidgetTester tester) async {
      await start(tester, null);
      await pumpSheet(tester, _foodWithExtras());
      expect(find.text(_extraName), findsOneWidget);
    });

    testWidgets('Food item without Extras: add-ons absent', (WidgetTester tester) async {
      await start(tester, _grocery);
      await pumpSheet(tester, _foodWithoutExtras());
      expect(find.text('addons'), findsNothing);
    });

    testWidgets('Grocery item, Grocery active: no add-ons, as before', (WidgetTester tester) async {
      await start(tester, _grocery);
      await pumpSheet(tester, _groceryWithAddOnData());
      expect(find.text(_extraName), findsNothing);
    });

    testWidgets('Grocery item, Food active: follows Grocery, no add-ons', (WidgetTester tester) async {
      await start(tester, _food);
      await pumpSheet(tester, _groceryWithAddOnData());
      expect(find.text(_extraName), findsNothing);
    });
  });

  group('isAddOnEnabled', () {
    testWidgets('follows the requested module whichever module is active', (WidgetTester tester) async {
      await start(tester, _grocery);
      expect(splash.isAddOnEnabled('food'), isTrue);
      expect(splash.isAddOnEnabled('grocery'), isFalse);
      await splash.setModule(_food);
      expect(splash.isAddOnEnabled('food'), isTrue);
      expect(splash.isAddOnEnabled('grocery'), isFalse);
    });

    testWidgets('unknown or missing module type falls back to the active module', (WidgetTester tester) async {
      await start(tester, _food);
      expect(splash.isAddOnEnabled(null), isTrue);
      expect(splash.isAddOnEnabled('unknown'), isTrue);
      await splash.setModule(_grocery);
      expect(splash.isAddOnEnabled(null), isFalse);
    });

    test('before any config has loaded: false, no crash', () {
      expect(splash.isAddOnEnabled('food'), isFalse);
    });
  });
}
