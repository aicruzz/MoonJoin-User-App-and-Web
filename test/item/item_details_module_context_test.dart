// Item details module context. An item found by a search scoped to another
// module (e.g. Market while Groceries is active) is only found by the backend
// under its own module: items/details sent with the active module's header
// answered 404 and the item screen kept spinning. The details request now
// carries the item's module on a COPY of the headers — the shared headers and
// the active module are never changed. Without an item module (deep link) or
// with the active module, the usual headers are used, as before.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/repositories/item_repository.dart';
import 'package:moonjoin/features/item/domain/services/item_service_interface.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/util/app_constants.dart';

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  ModuleModel? active = ModuleModel(id: 5, moduleType: 'grocery');
  @override
  ModuleModel? get module => active;
}

/// Shared headers as the app holds them; every GET records the headers it was given.
class _ApiClient extends GetxService implements ApiClient {
  final Map<String, String> shared = <String, String>{
    AppConstants.moduleId: '5', AppConstants.zoneId: '[7]', AppConstants.localizationKey: 'en', 'Authorization': 'Bearer t',
  };
  final List<String> uris = <String>[];
  final List<Map<String, String>?> sentHeaders = <Map<String, String>?>[];
  Response answer = const Response(statusCode: 200, body: <String, dynamic>{
    'id': 609, 'name': 'Rice / Perfume / Basmati', 'module_id': 10, 'module_type': 'grocery', 'store_id': 10, 'price': 4500, 'discount': 0,
  });

  @override
  Map<String, String> getHeader() => shared;

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    uris.add(uri);
    sentHeaders.add(headers == null ? null : Map<String, String>.from(headers));
    return answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records what the controller passes to the service.
class _ItemService extends _NoSuch implements ItemServiceInterface {
  final List<int?> itemIds = <int?>[];
  final List<int?> moduleIds = <int?>[];
  @override
  Future<Item?> getItemDetails(int? itemID, {int? moduleId}) async {
    itemIds.add(itemID);
    moduleIds.add(moduleId);
    return null;
  }
}

void main() {
  late _ApiClient api;
  late ItemRepository repository;
  late _Splash splash;
  late Map<String, String> sharedBefore;

  setUp(() {
    Get.testMode = true;
    api = _ApiClient();
    repository = ItemRepository(apiClient: api);
    splash = _Splash();
    Get.put<SplashController>(splash);
    sharedBefore = Map<String, String>.from(api.shared);
  });

  tearDown(Get.reset);

  group('ItemRepository item details headers', () {
    test('item from another module: request carries the item module; shared headers and active module unchanged', () async {
      final Item? item = await repository.get('609', moduleId: 10);

      expect(api.uris.single, '${AppConstants.itemDetailsUri}609');
      final Map<String, String> sent = api.sentHeaders.single!;
      expect(sent[AppConstants.moduleId], '10');
      expect(<String, String>{...sent}..remove(AppConstants.moduleId), <String, String>{...sharedBefore}..remove(AppConstants.moduleId),
          reason: 'only the module header differs from the shared headers');
      expect(api.shared, sharedBefore, reason: 'shared header map not mutated');
      expect(api.shared[AppConstants.moduleId], '5');
      expect(splash.module?.id, 5, reason: 'active module unchanged');
      expect(item?.id, 609);
      expect(item?.moduleId, 10);
    });

    test('item from the active module: the usual headers (no copy)', () async {
      await repository.get('609', moduleId: 5);
      expect(api.sentHeaders.single, isNull, reason: 'null headers → ApiClient uses its shared headers, as before');
      expect(api.shared, sharedBefore);
    });

    test('no module context (deep link): the usual headers, as before', () async {
      final Item? item = await repository.get('609');
      expect(api.sentHeaders.single, isNull);
      expect(api.shared, sharedBefore);
      expect(item?.id, 609, reason: 'details still parsed and returned');
    });

    test('no module header yet (no module selected): the item module is sent on a copy', () async {
      api.shared.remove(AppConstants.moduleId);
      sharedBefore = Map<String, String>.from(api.shared);
      await repository.get('609', moduleId: 10);
      expect(api.sentHeaders.single![AppConstants.moduleId], '10');
      expect(api.shared, sharedBefore);
      expect(api.shared.containsKey(AppConstants.moduleId), isFalse);
    });

    test('details not found: null, shared headers unchanged', () async {
      api.answer = const Response(statusCode: 404, body: <String, dynamic>{'errors': <String, dynamic>{'code': 'product-001', 'message': 'Not found'}});
      final Item? item = await repository.get('609', moduleId: 10);
      expect(item, isNull);
      expect(api.shared, sharedBefore);
    });

    test('condition-wise items path is untouched by moduleId', () async {
      api.answer = const Response(statusCode: 200, body: <String, dynamic>{'products': <dynamic>[]});
      await repository.get('4', isConditionWiseItem: true, moduleId: 10);
      expect(api.uris.single, isNot(contains(AppConstants.itemDetailsUri)));
      expect(api.sentHeaders.single, isNull);
    });
  });

  group('ItemController.getItemDetails propagation', () {
    test('passes the item module through to the service', () async {
      final _ItemService service = _ItemService();
      final ItemController controller = ItemController(itemServiceInterface: service);
      await controller.getItemDetails(itemId: 609, moduleId: 10);
      expect(service.itemIds.single, 609);
      expect(service.moduleIds.single, 10);
    });

    test('deep link / no item: no module passed, as before', () async {
      final _ItemService service = _ItemService();
      final ItemController controller = ItemController(itemServiceInterface: service);
      await controller.getItemDetails(itemId: 609);
      expect(service.moduleIds.single, isNull);
    });

    test('campaign item (already complete): no details request, as before', () async {
      final _ItemService service = _ItemService();
      final ItemController controller = ItemController(itemServiceInterface: service);
      try {
        await controller.getItemDetails(itemId: 609, item: Item(id: 609, name: 'Campaign', moduleId: 10), moduleId: 10);
      } catch (_) {
        // initData needs module config not provided here; only the request matters.
      }
      expect(service.itemIds, isEmpty, reason: 'campaign items are rendered from the passed item');
    });
  });
}
