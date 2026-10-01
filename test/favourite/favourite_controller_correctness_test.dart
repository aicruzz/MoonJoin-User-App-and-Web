// Favourites correctness slice.
// (1) A failed optimistic add rolls back exactly its own entries without
//     throwing (it used to remove while iterating the same list, which threw
//     ConcurrentModificationError and skipped the error snackbar, left
//     _isRemoving stuck and the UI un-refreshed).
// (2) removeFavourite() (every logout / session clear) clears all favourites
//     memory, including the item/store object lists.
// (3) A wish-list response that arrives after a module switch is not applied.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/models/response_model.dart';
import 'package:moonjoin/features/favourite/controllers/favourite_controller.dart';
import 'package:moonjoin/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';

class _SplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final ModuleModel _food = ModuleModel(id: 3, moduleType: 'food');
final ModuleModel _grocery = ModuleModel(id: 5, moduleType: 'grocery');

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  ModuleModel? active = _food;
  @override
  ModuleModel? get module => active;
}

/// Add/remove answer with the queued result; wish-list answers are held.
class _FakeFavouriteService implements FavouriteServiceInterface {
  bool addSucceeds = true;
  final List<Completer<Response>> listCalls = <Completer<Response>>[];

  @override
  Future<ResponseModel> addFavouriteList(int? id, bool isStore) async =>
      addSucceeds ? ResponseModel(true, 'added_to_wishlist') : ResponseModel(false, 'add_failed');

  @override
  Future<Response> getFavouriteList() {
    final Completer<Response> c = Completer<Response>();
    listCalls.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Response _wishList({List<int> itemIds = const <int>[], List<int> storeIds = const <int>[], int moduleId = 3}) => Response(
      statusCode: 200,
      body: <String, dynamic>{
        'item': <Map<String, dynamic>>[for (final int id in itemIds) <String, dynamic>{'id': id, 'name': 'Item $id', 'module_id': moduleId, 'price': 100, 'discount': 0}],
        'store': <Map<String, dynamic>>[
          for (final int id in storeIds) <String, dynamic>{'id': id, 'name': 'Store $id', 'module_id': moduleId, 'featured': 0},
        ],
      },
    );

void main() {
  late _Splash splash;
  late _FakeFavouriteService service;
  late FavouriteController c;
  late int updates;

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));

  setUp(() {
    Get.testMode = true;
    splash = _Splash();
    Get.put<SplashController>(splash);
    service = _FakeFavouriteService();
    c = FavouriteController(favouriteServiceInterface: service);
    updates = 0;
    c.addListener(() => updates++);
  });

  tearDown(Get.reset);

  /// Loads a wish list for the current module: store 90, item 70.
  Future<void> seedExisting(WidgetTester tester) async {
    c.getFavouriteList();
    service.listCalls.last.complete(_wishList(itemIds: <int>[70], storeIds: <int>[90]));
    await tester.pump();
  }

  group('failed optimistic add rolls back exactly, without throwing', () {
    testWidgets('store: id + placeholder removed, existing store kept, snackbar, not removing, update()', (WidgetTester tester) async {
      await pumpApp(tester);
      await seedExisting(tester);
      final Store existing = c.wishStoreList!.single!;
      service.addSucceeds = false;
      final int before = updates;

      c.addToFavouriteList(null, 91, true);
      expect(c.wishStoreIdList, <int?>[90, 91], reason: 'optimistic entry created');
      expect(c.wishStoreList, hasLength(2));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'no ConcurrentModificationError');
      expect(c.wishStoreIdList, <int?>[90]);
      expect(c.wishStoreList, hasLength(1));
      expect(identical(c.wishStoreList!.single, existing), isTrue, reason: 'only the optimistic placeholder is removed');
      expect(c.isRemoving, isFalse);
      expect(updates, greaterThan(before + 1), reason: 'the final update() ran');
      await tester.pump();
      expect(find.text('add_failed'), findsOneWidget, reason: 'error snackbar shown');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('item: id + that exact product removed, existing item kept, snackbar, not removing', (WidgetTester tester) async {
      await pumpApp(tester);
      await seedExisting(tester);
      final Item? existing = c.wishItemList!.single;
      service.addSucceeds = false;
      final Item product = Item(id: 71, name: 'New');

      c.addToFavouriteList(product, null, false);
      expect(c.wishItemIdList, <int?>[70, 71]);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(c.wishItemIdList, <int?>[70]);
      expect(c.wishItemList, hasLength(1));
      expect(identical(c.wishItemList!.single, existing), isTrue);
      expect(c.isRemoving, isFalse);
      await tester.pump();
      expect(find.text('add_failed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('successful add keeps the optimistic entry (unchanged)', () {
    testWidgets('store', (WidgetTester tester) async {
      await pumpApp(tester);
      c.addToFavouriteList(null, 91, true);
      await tester.pump();
      expect(c.wishStoreIdList, <int?>[91]);
      expect(c.wishStoreList, hasLength(1));
      expect(c.isRemoving, isFalse);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('item', (WidgetTester tester) async {
      await pumpApp(tester);
      final Item product = Item(id: 71, name: 'New');
      c.addToFavouriteList(product, null, false);
      await tester.pump();
      expect(c.wishItemIdList, <int?>[71]);
      expect(identical(c.wishItemList!.single, product), isTrue);
      expect(c.isRemoving, isFalse);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  testWidgets('removeFavourite() clears id lists AND item/store object lists', (WidgetTester tester) async {
    await pumpApp(tester);
    await seedExisting(tester);
    expect(c.wishItemList, isNotEmpty);
    expect(c.wishStoreList, isNotEmpty);

    c.removeFavourite();
    expect(c.wishItemIdList, isEmpty);
    expect(c.wishStoreIdList, isEmpty);
    expect(c.wishItemList, isNull);
    expect(c.wishStoreList, isNull);
  });

  group('module-switch race', () {
    testWidgets('a Food wish-list response arriving after switching to Grocery is not applied, no update()', (WidgetTester tester) async {
      await pumpApp(tester);
      c.getFavouriteList();                                       // Food request held
      splash.active = _grocery;                                   // user switches
      final int before = updates;
      service.listCalls.single.complete(_wishList(itemIds: <int>[70], storeIds: <int>[90], moduleId: 3));
      await tester.pump();

      expect(c.wishItemList, isNull, reason: 'stale Food result not applied');
      expect(c.wishStoreList, isNull);
      expect(c.wishItemIdList, isEmpty);
      expect(c.wishStoreIdList, isEmpty);
      expect(updates, before, reason: 'no update() from the stale response');

      c.getFavouriteList();                                       // Grocery's own request
      service.listCalls.last.complete(_wishList(storeIds: <int>[95], moduleId: 5));
      await tester.pump();
      expect(c.wishStoreIdList, <int?>[95]);
    });

    testWidgets('a response for the unchanged module is applied normally', (WidgetTester tester) async {
      await pumpApp(tester);
      await seedExisting(tester);
      expect(c.wishItemIdList, <int?>[70]);
      expect(c.wishStoreIdList, <int?>[90]);
    });
  });
}
