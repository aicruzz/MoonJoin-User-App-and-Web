// Store "All Products" pagination. PaginatedListView asked for the next page only
// when the scroll position was exactly at the bottom, so the list always ran out
// first: scrolling stopped as if the products had ended, a spinner appeared, and a
// second swipe showed the next batch. The next page is now requested while about
// one screen of loaded products is still left. The existing guards (one request in
// flight, each page once, stop at the last page) are unchanged.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/paginated_list_view.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';

const double _rowHeight = 200; // page 1 = 2000px of products, 1200px scrollable
const double _viewportHeight = 800;

/// A store list fed page by page, like StoreScreen: the host appends a page and
/// passes the new offset back, as storeItemModel.offset does.
class _Host extends StatefulWidget {
  final int totalSize;
  final Future<bool> Function(int page) load;
  final ScrollController controller;
  const _Host({required this.totalSize, required this.load, required this.controller});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final List<int> rows = List<int>.generate(10, (int i) => i + 1);
  int offset = 1;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.controller,
      child: PaginatedListView(
        scrollController: widget.controller,
        totalSize: widget.totalSize,
        offset: offset,
        onPaginate: (int? page) async {
          final bool ok = await widget.load(page!);
          if (ok) {
            setState(() {
              rows.addAll(List<int>.generate(10, (int i) => (page - 1) * 10 + i + 1));
              offset = page;
            });
          }
        },
        itemView: Column(children: <Widget>[
          for (final int row in rows) SizedBox(height: _rowHeight, child: Text('product $row')),
        ]),
      ),
    );
  }
}

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _StoreService extends _NoSuch implements StoreServiceInterface {
  final List<ItemModel?> answers = <ItemModel?>[];
  final List<int> offsets = <int>[];

  @override
  Future<ItemModel?> getStoreItemList({int? storeID, required int offset, int? categoryID, String? type, List<String>? filter, int? rating, double? lowerValue, double? upperValue}) async {
    offsets.add(offset);
    return answers.removeAt(0);
  }
}

ItemModel _page(int offset, List<int> ids, {int totalSize = 26}) =>
    ItemModel(totalSize: totalSize, offset: offset, items: <Item>[for (final int id in ids) Item(id: id, name: 'item $id')]);

void main() {
  group('PaginatedListView (store products)', () {
    late ScrollController controller;
    late List<int> requested;
    Completer<bool>? hold;

    setUp(() {
      controller = ScrollController();
      requested = <int>[];
      hold = null;
    });

    Future<void> pumpHost(WidgetTester tester, {int totalSize = 30}) async {
      tester.view.physicalSize = const Size(400, _viewportHeight);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: _Host(
        totalSize: totalSize, controller: controller,
        load: (int page) async {
          requested.add(page);
          return hold != null ? hold!.future : true;
        },
      ))));
    }

    testWidgets('first page shows; no request until the customer is within one screen of the end', (WidgetTester tester) async {
      await pumpHost(tester);
      expect(find.text('product 1'), findsOneWidget);
      expect(controller.position.maxScrollExtent, 1200);
      controller.jumpTo(300); // 900px of products still below the screen
      await tester.pump();
      expect(requested, isEmpty);
    });

    testWidgets('next page starts before the absolute end, once, while the customer is still scrolling', (WidgetTester tester) async {
      hold = Completer<bool>();
      await pumpHost(tester);
      controller.jumpTo(450); // 750px before the end, not at it
      await tester.pump();
      expect(controller.position.pixels, lessThan(controller.position.maxScrollExtent));
      expect(requested, <int>[2]);

      controller.jumpTo(900);
      controller.jumpTo(1200);
      await tester.pump();
      expect(requested, <int>[2], reason: 'no second request while page 2 is loading');

      hold!.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('product 11', skipOffstage: false), findsOneWidget);
      expect(find.text('product 20', skipOffstage: false), findsOneWidget);
      expect(find.text('product 1', skipOffstage: false), findsOneWidget, reason: 'appended, not replaced');
      expect(controller.position.maxScrollExtent, 3200, reason: 'the list keeps going: no end reached');
    });

    testWidgets('pages are requested in order, each once, and stop at the last page', (WidgetTester tester) async {
      await pumpHost(tester);
      for (int i = 0; i < 6; i++) {
        controller.jumpTo(controller.position.maxScrollExtent - 100);
        await tester.pumpAndSettle();
      }
      expect(requested, <int>[2, 3], reason: '30 products = 3 pages, nothing beyond');
      for (int row = 1; row <= 30; row++) {
        expect(find.text('product $row', skipOffstage: false), findsOneWidget, reason: 'no duplicate or skipped product $row');
      }
      expect(find.byType(CircularProgressIndicator, skipOffstage: false), findsNothing);
    });

    testWidgets('a single page (no more products) never requests', (WidgetTester tester) async {
      await pumpHost(tester, totalSize: 10);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(requested, isEmpty);
    });

    testWidgets('a failed page shows the spinner only while loading and is retried on the next scroll', (WidgetTester tester) async {
      hold = Completer<bool>();
      await pumpHost(tester);
      controller.jumpTo(500);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator, skipOffstage: false), findsOneWidget);

      hold!.complete(false); // request failed: nothing appended, offset unchanged
      hold = null;
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator, skipOffstage: false), findsNothing);
      expect(find.text('product 11', skipOffstage: false), findsNothing);
      expect(requested, <int>[2], reason: 'no automatic retry loop');

      controller.jumpTo(550);
      await tester.pumpAndSettle();
      expect(requested, <int>[2, 2], reason: 'the customer scrolling again retries the same page');
      expect(find.text('product 11', skipOffstage: false), findsOneWidget);
    });
  });

  group('StoreController.getStoreItemList', () {
    late _StoreService service;
    late StoreController store;

    setUp(() {
      Get.testMode = true;
      service = _StoreService();
      store = StoreController(storeServiceInterface: service);
    });

    tearDown(Get.reset);

    test('page 2 is appended once after page 1, in server order', () async {
      service.answers.addAll(<ItemModel?>[_page(1, <int>[1, 2, 3]), _page(2, <int>[4, 5])]);
      await store.getStoreItemList(7, 1, 'all', false);
      await store.getStoreItemList(7, 2, 'all', false);
      expect(store.storeItemModel!.items!.map((Item i) => i.id), <int>[1, 2, 3, 4, 5]);
      expect(store.storeItemModel!.offset, 2);
      expect(service.offsets, <int>[1, 2]);
    });

    test('a failed next page keeps the loaded products and the offset', () async {
      service.answers.addAll(<ItemModel?>[_page(1, <int>[1, 2, 3]), null]);
      await store.getStoreItemList(7, 1, 'all', false);
      await store.getStoreItemList(7, 2, 'all', false);
      expect(store.storeItemModel!.items!.map((Item i) => i.id), <int>[1, 2, 3]);
      expect(store.storeItemModel!.offset, 1, reason: 'the page is requested again on the next scroll');
    });
  });
}
