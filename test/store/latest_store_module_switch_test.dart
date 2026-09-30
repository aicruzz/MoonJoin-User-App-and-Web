// Slice E2 — switching module must never show the previous module's stores.
// (1) switchModule clears the in-memory latest-store list (not the persistent
// cache), so the new storefront loads its own list instead of reusing the old
// one. (2) A latest-store load that finishes after the module changed is not
// applied, so a slow response from the previous module cannot overwrite the
// new module's list.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/features/store/domain/repositories/store_repository.dart';
import 'package:moonjoin/features/store/domain/services/store_service.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Real SplashController whose active module the test can switch directly.
class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _FakeSplashService());
  ModuleModel? active = ModuleModel(id: 5, moduleType: 'grocery');
  @override
  ModuleModel? get module => active;
}

/// Latest-store service whose local and network answers the test releases.
class _GatedStoreService implements StoreServiceInterface {
  final List<({DataSourceEnum source, Completer<List<Store>?> answer})> calls = <({DataSourceEnum source, Completer<List<Store>?> answer})>[];

  @override
  Future<List<Store>?> getLatestStoreList(String type, {required DataSourceEnum source}) {
    final Completer<List<Store>?> c = Completer<List<Store>?>();
    calls.add((source: source, answer: c));
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Network for the cache tests: answers every GET with the queued body.
class _FakeApiClient implements ApiClient {
  final List<Object> bodies = <Object>[];
  int calls = 0;

  @override
  Map<String, String> getHeader() => <String, String>{'moduleId': '3', 'zoneId': '[7]'};

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    calls++;
    return bodies.isNotEmpty ? Response(statusCode: 200, body: bodies.removeAt(0)) : const Response(statusCode: 500, statusText: 'offline');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Store> _stores(List<int> ids) => <Store>[for (final int id in ids) Store(id: id, name: 'Store $id')];
Map<String, dynamic> _storesBody(List<int> ids) =>
    <String, dynamic>{'stores': <Map<String, dynamic>>[for (final int id in ids) <String, dynamic>{'id': id, 'name': 'Store $id', 'featured': 0}]};

final ModuleModel _food = ModuleModel(id: 3, moduleType: 'food');

Future<void> _settle([int ms = 20]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Directory tmp = Directory.systemTemp.createTempSync('moonjoin_e2_cache_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async => tmp.path,
  );

  late _Splash splash;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Get.put<SharedPreferences>(await SharedPreferences.getInstance());
    splash = _Splash();
    Get.put<SplashController>(splash);
  });

  tearDown(Get.reset);

  group('late responses (gated service)', () {
    late _GatedStoreService service;
    late StoreController controller;
    late int updates;

    setUp(() {
      service = _GatedStoreService();
      controller = StoreController(storeServiceInterface: service);
      updates = 0;
      controller.addListener(() => updates++);
    });

    test('a Grocery network answer that lands after switching to Food is NOT applied and does not repaint', () async {
      // Grocery storefront loads: cache first, then network (left in flight).
      controller.getLatestStoreList(false, 'all', false);
      service.calls[0].answer.complete(_stores(<int>[501]));
      await _settle();
      expect(controller.latestStoreList!.single.id, 501);
      expect(service.calls[1].source, DataSourceEnum.client);

      // User switches to Food; the Food list shows Food's cached stores.
      splash.active = _food;
      controller.clearLatestStoreList();
      controller.getLatestStoreList(false, 'all', false);
      service.calls[2].answer.complete(_stores(<int>[301]));
      await _settle();
      expect(controller.latestStoreList!.single.id, 301);
      final int updatesBeforeStale = updates;

      // The slow Grocery network answer finally arrives.
      service.calls[1].answer.complete(_stores(<int>[502]));
      await _settle();
      expect(controller.latestStoreList!.single.id, 301, reason: 'Food must never show Grocery stores');
      expect(updates, updatesBeforeStale, reason: 'no repaint for a stale answer');

      // Food's own network answer still applies.
      service.calls[3].answer.complete(_stores(<int>[302, 303]));
      await _settle();
      expect(controller.latestStoreList!.map((s) => s.id), <int>[302, 303]);
    });

    test('a Grocery cache read that lands after switching is NOT applied and does not start a Grocery network load', () async {
      controller.getLatestStoreList(false, 'all', false);
      splash.active = _food;
      service.calls[0].answer.complete(_stores(<int>[501]));
      await _settle();
      expect(controller.latestStoreList, isNull);
      expect(updates, 0);
      expect(service.calls, hasLength(1), reason: 'no follow-up network load for the old module');
    });

    test('a load that starts and finishes under the same module applies exactly as before', () async {
      controller.getLatestStoreList(false, 'all', false);
      service.calls[0].answer.complete(_stores(<int>[501]));
      await _settle();
      service.calls[1].answer.complete(_stores(<int>[502, 503]));
      await _settle();
      expect(controller.latestStoreList!.map((s) => s.id), <int>[502, 503]);
      expect(updates, 2, reason: 'one repaint for cache, one for network');
    });

    test('reload=true still refreshes: list is cleared and reloaded', () async {
      controller.getLatestStoreList(false, 'all', false);
      service.calls[0].answer.complete(_stores(<int>[501]));
      await _settle();
      service.calls[1].answer.complete(_stores(<int>[502]));
      await _settle();

      controller.getLatestStoreList(true, 'all', false);
      expect(controller.latestStoreList, isNull, reason: 'reload clears immediately, as before');
      service.calls[2].answer.complete(_stores(<int>[502]));
      await _settle();
      service.calls[3].answer.complete(_stores(<int>[504]));
      await _settle();
      expect(controller.latestStoreList!.single.id, 504);
    });

    test('clearLatestStoreList() sets the list to null; the next non-reload load actually loads', () async {
      controller.getLatestStoreList(false, 'all', false);
      service.calls[0].answer.complete(_stores(<int>[501]));
      await _settle();
      service.calls[1].answer.complete(_stores(<int>[502]));
      await _settle();
      expect(controller.latestStoreList, isNotNull);

      splash.active = _food;
      controller.clearLatestStoreList();
      expect(controller.latestStoreList, isNull);

      // Without the clear, this non-reload call was skipped and kept Grocery.
      controller.getLatestStoreList(false, 'all', false);
      expect(service.calls, hasLength(3));
      service.calls[2].answer.complete(_stores(<int>[301]));
      await _settle();
      expect(controller.latestStoreList!.single.id, 301);
    });
  });

  group('persistent cache (real service + repository + drift cache)', () {
    test('clearLatestStoreList() does not delete the persistent cache: the module still loads its cached stores', () async {
      splash.active = _food;
      final _FakeApiClient api = _FakeApiClient()..bodies.add(_storesBody(<int>[301, 302]));
      final StoreController controller = StoreController(
        storeServiceInterface: StoreService(storeRepositoryInterface: StoreRepository(apiClient: api, sharedPreferences: Get.find())),
      );

      controller.getLatestStoreList(false, 'all', false); // cache (empty) → network (writes cache)
      await _settle(800);
      expect(controller.latestStoreList!.map((s) => s.id), <int>[301, 302]);

      controller.clearLatestStoreList();
      expect(controller.latestStoreList, isNull);

      // Network now fails; the list must come back from the persistent cache.
      controller.getLatestStoreList(false, 'all', false);
      await _settle(800);
      expect(controller.latestStoreList!.map((s) => s.id), <int>[301, 302]);
      expect(api.calls, 2);
    });
  });
}
