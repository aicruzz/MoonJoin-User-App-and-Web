// Item details failure state. A details request that got no item (not found,
// offline, server error) left `item == null`, which both details screens read
// as "still loading" — an endless spinner. A failed fetch now sets
// itemLoadFailed and the screens show the frozen MoonJoin error state with a
// retry; retry goes back to loading and shows the item or the error again.
// Campaign items (rendered from the passed item) never enter the failed state,
// and the item's module (search scope fix) is passed on every attempt.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/moonjoin/error_state_widget.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/models/cart_model.dart';
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/item/screens/food_details_screen.dart';
import 'package:moonjoin/features/item/screens/item_details_screen.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}

class _CartService extends _NoSuch implements CartServiceInterface {
  @override
  int? getCartId(int cartIndex, List<CartModel> cartList) => null;
}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  @override
  ModuleModel? get module => ModuleModel(id: 5, moduleType: 'grocery');
  @override
  ModuleModel? get cacheModule => ModuleModel(id: 5, moduleType: 'grocery');
  @override
  ConfigModel? get configModel => ConfigModel(moduleConfig: ModuleConfig(module: Module(stock: false, addOn: false, showRestaurantText: false)));
  @override
  Module getModuleConfig(String? moduleType) => Module(newVariation: false);
}

/// Each details request answers with the next queued result (null = failed).
class _ItemService extends _NoSuch implements ItemServiceInterface {
  final List<Item?> answers = <Item?>[];
  final List<int?> moduleIds = <int?>[];
  Completer<void>? hold;
  @override
  Future<Item?> getItemDetails(int? itemID, {int? moduleId}) async {
    moduleIds.add(moduleId);
    if (hold != null) await hold!.future;
    return answers.removeAt(0);
  }
}

/// Real getItemDetails / retry logic; the variation/cart preparation after a
/// successful load is outside this slice and recorded only.
class _Item extends ItemController {
  _Item(_ItemService service) : super(itemServiceInterface: service);
  int updates = 0;
  final List<Item?> prepared = <Item?>[];
  @override
  void initData(Item? item, CartModel? cart) => prepared.add(item);
  @override
  Future<int> setExistInCart(Item? item, List<List<bool?>>? selectedVariations, {bool notify = false}) async => -1;
  @override
  void update([List<Object>? ids, bool condition = true]) {
    updates++;
    super.update(ids, condition);
  }
}

final Item _rice = Item(id: 609, name: 'Rice / Perfume / Basmati', moduleId: 10, moduleType: 'grocery', price: 4500, discount: 0);

void main() {
  late _ItemService service;
  late _Item controller;

  setUp(() {
    Get.testMode = true;
    service = _ItemService();
    controller = _Item(service);
    Get.put<SplashController>(_Splash());
    Get.put<CartController>(CartController(cartServiceInterface: _CartService()));
    Get.put<ItemController>(controller);
  });

  tearDown(Get.reset);

  group('ItemController details failure state', () {
    test('successful fetch: item loaded, not failed', () async {
      service.answers.add(_rice);
      await controller.getItemDetails(itemId: 609, moduleId: 10);
      expect(controller.item?.id, 609);
      expect(controller.itemLoadFailed, isFalse);
      expect(controller.prepared.single?.id, 609, reason: 'existing preparation still runs');
    });

    test('failed fetch: item stays null, failed set, listeners notified', () async {
      service.answers.add(null);
      final int before = controller.updates;
      await controller.getItemDetails(itemId: 609, moduleId: 10);
      expect(controller.item, isNull);
      expect(controller.itemLoadFailed, isTrue);
      expect(controller.updates, greaterThan(before));
      expect(controller.prepared, isEmpty);
    });

    test('retry after failure: back to loading, fresh request with the same module, item shown', () async {
      service.answers.add(null);
      await controller.getItemDetails(itemId: 609, moduleId: 10);
      expect(controller.itemLoadFailed, isTrue);

      service.answers.add(_rice);
      service.hold = Completer<void>();
      final int before = controller.updates;
      final Future<void> retry = controller.retryItemDetails(itemId: 609, moduleId: 10);
      expect(controller.itemLoadFailed, isFalse, reason: 'loading state while the retry runs');
      expect(controller.updates, before + 1, reason: 'screen switches to the spinner at once');
      service.hold!.complete();
      await retry;

      expect(controller.item?.id, 609);
      expect(controller.itemLoadFailed, isFalse);
      expect(service.moduleIds, <int?>[10, 10], reason: 'item module kept on retry');
    });

    test('retry that fails again: error state again, never stuck loading', () async {
      service.answers.addAll(<Item?>[null, null]);
      await controller.getItemDetails(itemId: 609, moduleId: 10);
      await controller.retryItemDetails(itemId: 609, moduleId: 10);
      expect(controller.item, isNull);
      expect(controller.itemLoadFailed, isTrue);
      expect(service.moduleIds, hasLength(2));
    });

    test('a new details request resets a previous failure', () async {
      service.answers.add(null);
      await controller.getItemDetails(itemId: 609, moduleId: 10);
      expect(controller.itemLoadFailed, isTrue);

      service.answers.add(Item(id: 273, name: 'Red Globe Grapes', moduleId: 5, price: 1, discount: 0));
      service.hold = Completer<void>();
      final Future<void> next = controller.getItemDetails(itemId: 273, moduleId: 5);
      expect(controller.itemLoadFailed, isFalse, reason: 'the new screen starts in the loading state');
      service.hold!.complete();
      await next;
      expect(controller.item?.id, 273);
    });

    test('campaign item: rendered from the passed item, no request, never failed', () async {
      await controller.getItemDetails(itemId: 609, item: _rice, moduleId: 10);
      expect(service.moduleIds, isEmpty);
      expect(controller.item?.id, 609);
      expect(controller.itemLoadFailed, isFalse);
    });

    test('deep link (no item, no module): failure handled the same way', () async {
      service.answers.add(null);
      await controller.getItemDetails(itemId: 609);
      expect(service.moduleIds.single, isNull);
      expect(controller.itemLoadFailed, isTrue);
    });
  });

  group('details screens', () {
    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(GetMaterialApp(home: screen));
    }

    testWidgets('ItemDetailsScreen: failed details → error state (no endless spinner); retry → loading', (WidgetTester tester) async {
      service.answers.add(null);
      await pumpScreen(tester, ItemDetailsScreen(itemId: 609, inStorePage: false, item: _rice));
      await tester.pump();

      expect(find.byType(MoonjoinErrorState), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(service.moduleIds.single, 10, reason: 'item module passed (search scope fix)');

      service.answers.add(null);
      service.hold = Completer<void>();
      await tester.tap(find.text('try_again'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'loading while retrying');
      service.hold!.complete();
      await tester.pump();
      expect(find.byType(MoonjoinErrorState), findsOneWidget, reason: 'failed again → error state again');
      expect(service.moduleIds, <int?>[10, 10]);
    });

    testWidgets('FoodDetailsScreen: failed details → error state; retry → loading', (WidgetTester tester) async {
      service.answers.add(null);
      await pumpScreen(tester, FoodDetailsScreen(itemId: 609, inStorePage: false, item: _rice));
      await tester.pump();

      expect(find.byType(MoonjoinErrorState), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      service.answers.add(null);
      service.hold = Completer<void>();
      await tester.tap(find.text('try_again'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      service.hold!.complete();
      await tester.pump();
      expect(find.byType(MoonjoinErrorState), findsOneWidget);
      expect(service.moduleIds, <int?>[10, 10]);
    });

    testWidgets('while the first request is pending both screens show the spinner, not the error', (WidgetTester tester) async {
      service.answers.add(_rice);
      service.hold = Completer<void>();
      await pumpScreen(tester, FoodDetailsScreen(itemId: 609, inStorePage: false, item: _rice));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(MoonjoinErrorState), findsNothing);
      service.hold!.complete();
    });
  });
}
