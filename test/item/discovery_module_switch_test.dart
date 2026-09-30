// Slice E2d — discovery chips ("Special offer" = discounted items, "Most popular"
// = popular items) on the storefront Home.
// (1) A discounted/popular load that finishes after the user switched module is
//     not applied (E2 pattern), so a chip can never show the previous module's
//     items; the repository has already cached it under that module's own key.
// (2) The discovery result area listens to ItemController, so a chip opened
//     before its list arrived repaints when the result lands.
//
// Answers are released explicitly with Completers — no timing assumptions.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/no_data_screen.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/brands/controllers/brands_controller.dart';
import 'package:moonjoin/features/brands/domain/models/brands_model.dart';
import 'package:moonjoin/features/brands/domain/services/brands_service_interface.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/cart/domain/models/cart_model.dart';
import 'package:moonjoin/features/cart/domain/services/cart_service_interface.dart';
import 'package:moonjoin/features/category/controllers/category_controller.dart';
import 'package:moonjoin/features/category/domain/services/category_service_interface.dart';
import 'package:moonjoin/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:moonjoin/features/flash_sale/domain/services/flash_sale_service_interface.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/basic_medicine_model.dart' show Categories;
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';
import 'package:moonjoin/features/store/screens/all_store_screen.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}

final ModuleModel _food = ModuleModel(id: 3, moduleType: 'food');
final ModuleModel _grocery = ModuleModel(id: 5, moduleType: 'grocery');

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  ModuleModel? active = _food;
  @override
  ModuleModel? get module => active;
  @override
  ConfigModel? get configModel => ConfigModel(moduleConfig: ModuleConfig(module: Module(showRestaurantText: true)));
}

/// Item service whose discounted/popular answers the test releases.
class _GatedItemService extends _NoSuch implements ItemServiceInterface {
  final List<({String kind, DataSourceEnum? source, int offset, Completer<ItemModel?> answer})> calls =
      <({String kind, DataSourceEnum? source, int offset, Completer<ItemModel?> answer})>[];

  Future<ItemModel?> _hold(String kind, DataSourceEnum? source, int offset) {
    final Completer<ItemModel?> c = Completer<ItemModel?>();
    calls.add((kind: kind, source: source, offset: offset, answer: c));
    return c.future;
  }

  @override
  Future<ItemModel?> getDiscountedItemList({required String type, DataSourceEnum? source, required int offset, String? search, List<int>? categoryIds, List<String>? filter, int? rating, double? minPrice, double? maxPrice}) =>
      _hold('discounted', source, offset);

  @override
  Future<ItemModel?> getPopularItemList({required String type, DataSourceEnum? source, required int offset, String? search, List<int>? categoryIds, List<String>? filter, int? rating, double? minPrice, double? maxPrice}) =>
      _hold('popular', source, offset);
}

ItemModel _page(List<int> ids, {List<int> categories = const <int>[], int total = 50}) => ItemModel(
      totalSize: total,
      items: <Item>[for (final int id in ids) Item(id: id, name: 'Item $id')],
      categories: <Categories>[for (final int id in categories) Categories(id: id, name: 'Cat $id')],
    );

Future<void> _flush() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// The two discovery lists, addressed uniformly so each case runs for both.
class _Kind {
  const _Kind(this.name, this.load, this.list);
  final String name;
  final Future<void> Function(ItemController c, {required String offset, DataSourceEnum dataSource, bool firstTimeCategoryLoad}) load;
  final List<Item>? Function(ItemController c) list;
}

final List<_Kind> _kinds = <_Kind>[
  _Kind('Discounted (Special offer)',
      (ItemController c, {required String offset, DataSourceEnum dataSource = DataSourceEnum.local, bool firstTimeCategoryLoad = false}) =>
          c.getDiscountedItemList(offset: offset, dataSource: dataSource, firstTimeCategoryLoad: firstTimeCategoryLoad),
      (ItemController c) => c.discountedItemList),
  _Kind('Popular (Most popular)',
      (ItemController c, {required String offset, DataSourceEnum dataSource = DataSourceEnum.local, bool firstTimeCategoryLoad = false}) =>
          c.getPopularItemList(offset: offset, dataSource: dataSource, firstTimeCategoryLoad: firstTimeCategoryLoad),
      (ItemController c) => c.popularItemList),
];

void main() {
  late _Splash splash;

  setUp(() {
    Get.testMode = true;
    splash = _Splash();
    Get.put<SplashController>(splash);
  });

  tearDown(Get.reset);

  for (final _Kind k in _kinds) {
    group(k.name, () {
      late _GatedItemService service;
      late ItemController c;
      late int updates;

      setUp(() {
        service = _GatedItemService();
        c = ItemController(itemServiceInterface: service);
        updates = 0;
        c.addListener(() => updates++);
      });

      test('same module: the cache answer is applied (with update()), then the network answer', () async {
        k.load(c, offset: '1');
        final int before = updates;
        service.calls[0].answer.complete(_page(<int>[1]));
        await _flush();
        // Existing behaviour (unchanged by E2d): the cache answer is applied and
        // repaints, then the follow-up network load (offset 1) resets the list
        // until the network answer arrives.
        expect(updates, greaterThan(before), reason: 'the cache answer was applied');
        expect(service.calls[1].source, DataSourceEnum.client);
        service.calls[1].answer.complete(_page(<int>[2, 3]));
        await _flush();
        expect(k.list(c)!.map((i) => i.id), <int>[2, 3]);
      });

      test('same module: a network-only load applies its answer', () async {
        k.load(c, offset: '1', dataSource: DataSourceEnum.client);
        service.calls[0].answer.complete(_page(<int>[7]));
        await _flush();
        expect(k.list(c)!.single.id, 7);
      });

      test('Food cache answer after switching to Grocery: discarded, no update(), no follow-up load', () async {
        k.load(c, offset: '1');
        splash.active = _grocery;
        c.clearItemLists();
        final int before = updates;
        service.calls[0].answer.complete(_page(<int>[301]));
        await _flush();
        expect(k.list(c), isNull);
        expect(updates, before);
        expect(service.calls, hasLength(1), reason: 'the stale load must not start its network step');
      });

      test('Food network answer after Grocery already loaded: discarded; Grocery stays; no update()', () async {
        k.load(c, offset: '1');                                   // Food
        service.calls[0].answer.complete(_page(<int>[301]));
        await _flush();                                           // Food network in flight: calls[1]

        splash.active = _grocery;
        c.clearItemLists();
        k.load(c, offset: '1');                                   // Grocery
        service.calls[2].answer.complete(_page(<int>[501]));
        await _flush();
        service.calls[3].answer.complete(_page(<int>[502]));
        await _flush();
        expect(k.list(c)!.single.id, 502);
        final int before = updates;

        service.calls[1].answer.complete(_page(<int>[302]));      // late Food answer
        await _flush();
        expect(k.list(c)!.single.id, 502, reason: 'Grocery must never show Food items');
        expect(updates, before);
      });

      test('page 1 resets the list; a later page appends (pagination unchanged)', () async {
        k.load(c, offset: '1', dataSource: DataSourceEnum.client);
        service.calls[0].answer.complete(_page(<int>[1, 2], total: 4));
        await _flush();
        expect(k.list(c)!.map((i) => i.id), <int>[1, 2]);
        expect(c.pageSize, 4);

        k.load(c, offset: '2', dataSource: DataSourceEnum.client);
        service.calls[1].answer.complete(_page(<int>[3, 4], total: 4));
        await _flush();
        expect(k.list(c)!.map((i) => i.id), <int>[1, 2, 3, 4]);

        k.load(c, offset: '1', dataSource: DataSourceEnum.client);
        expect(k.list(c), isNull, reason: 'page 1 resets as before');
        service.calls[2].answer.complete(_page(<int>[9]));
        await _flush();
        expect(k.list(c)!.map((i) => i.id), <int>[9]);
      });

      test('categoryList: set by a same-module first load; a stale answer cannot overwrite it', () async {
        k.load(c, offset: '1', dataSource: DataSourceEnum.client, firstTimeCategoryLoad: true);
        service.calls[0].answer.complete(_page(<int>[1], categories: <int>[10, 11]));
        await _flush();
        expect(c.categoryList!.map((x) => x.id), <int>[10, 11]);

        k.load(c, offset: '1', dataSource: DataSourceEnum.client, firstTimeCategoryLoad: true); // Food again…
        splash.active = _grocery;                                 // …then switch
        service.calls[1].answer.complete(_page(<int>[2], categories: <int>[99]));
        await _flush();
        expect(c.categoryList?.map((x) => x.id), isNot(contains(99)), reason: 'stale categories never applied');
      });
    });
  }

  // ---------------------------------------------------------------------------
  group('Discovery result UI repaints when ItemController updates (AllStoreScreen)', () {
    late _TestItem item;

    setUp(() {
      Get.put<StoreController>(_TestStore());
      Get.put<CategoryController>(_TestCategory());
      Get.put<BannerController>(_TestBanner());
      Get.put<BrandsController>(_TestBrands());
      Get.put<FlashSaleController>(_TestFlash());
      Get.put<CartController>(_TestCart());
      item = _TestItem();
      Get.put<ItemController>(item);
    });

    Future<void> openChip(WidgetTester tester, String label) async {
      await tester.pumpWidget(const GetMaterialApp(home: AllStoreScreen(
        isPopular: false, isFeatured: false, isNearbyStore: false, isTopOfferStore: false, isRecommendedStore: false, fromModule: true,
      )));
      await tester.pump();
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }

    for (final (String label, bool discounted) in <(String, bool)>[('special_offer', true), ('most_popular_items', false)]) {
      testWidgets('"$label" opened while the list is null shows loading, then repaints on update()', (WidgetTester tester) async {
        await openChip(tester, label);
        expect(find.byType(CircularProgressIndicator), findsWidgets, reason: 'list not loaded yet');
        expect(find.byType(NoDataScreen), findsNothing);

        // The result arrives (empty here): ItemController.update() alone must repaint.
        if (discounted) {
          item.discounted = <Item>[];
        } else {
          item.popular = <Item>[];
        }
        item.update();
        await tester.pump();

        expect(find.text('no_item_available'), findsOneWidget, reason: 'empty state shown after the update');
      });
    }
  });
}

// ---- Minimal controllers for the AllStoreScreen widget test (no network) ----

class _StoreService extends _NoSuch implements StoreServiceInterface {}
class _CategoryService extends _NoSuch implements CategoryServiceInterface {}
class _BannerService extends _NoSuch implements BannerServiceInterface {}
class _BrandsService extends _NoSuch implements BrandsServiceInterface {}
class _FlashService extends _NoSuch implements FlashSaleServiceInterface {}
class _CartService extends _NoSuch implements CartServiceInterface {}
class _ItemService extends _NoSuch implements ItemServiceInterface {}

class _TestStore extends StoreController {
  _TestStore() : super(storeServiceInterface: _StoreService());
  @override List<Store>? get latestStoreList => <Store>[];
  @override List<Store>? get featuredStoreList => <Store>[];
  @override Future<void> getLatestStoreList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {}
  @override Future<void> getFeaturedStoreList({DataSourceEnum dataSource = DataSourceEnum.local}) async {}
}

class _TestCategory extends CategoryController {
  _TestCategory() : super(categoryServiceInterface: _CategoryService());
  @override Future<void> getCategoryList(bool reload, {bool allCategory = false, DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {}
}

class _TestBanner extends BannerController {
  _TestBanner() : super(bannerServiceInterface: _BannerService());
  @override Future<void> getBannerList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {}
}

class _TestBrands extends BrandsController {
  _TestBrands() : super(brandsServiceInterface: _BrandsService());
  @override List<BrandModel>? get brandList => <BrandModel>[];
  @override Future<void> getBrandList({DataSourceEnum dataSource = DataSourceEnum.local}) async {}
}

class _TestFlash extends FlashSaleController {
  _TestFlash() : super(flashSaleServiceInterface: _FlashService());
  @override Future<void> getFlashSale(bool reload, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {}
}

class _TestCart extends CartController {
  _TestCart() : super(cartServiceInterface: _CartService());
  @override List<CartModel> get cartList => <CartModel>[];
}

class _TestItem extends ItemController {
  _TestItem() : super(itemServiceInterface: _ItemService());
  List<Item>? discounted;
  List<Item>? popular;
  @override List<Item>? get discountedItemList => discounted;
  @override List<Item>? get popularItemList => popular;
}
