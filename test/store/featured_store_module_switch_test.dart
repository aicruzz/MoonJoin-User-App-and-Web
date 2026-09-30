// Slice E2c — Food Top Brands renders StoreController.featuredStoreList, which is
// one list shared by every context (All Module landing, Pharmacy, Food, …). A
// module switch now clears the in-memory list so the destination's existing
// load-if-null path fetches its OWN featured list, and a featured load that
// finishes after the active module changed (to or from the landing, where the
// module is null) is not applied. The persistent, module-scoped cache is untouched.
//
// Answers are released explicitly with Completers — no timing assumptions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/features/location/domain/models/zone_response_model.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/features/store/domain/repositories/store_repository.dart';
import 'package:moonjoin/features/store/domain/services/store_service.dart';
import 'package:moonjoin/features/store/domain/services/store_service_interface.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final ModuleModel _food = ModuleModel(id: 3, moduleType: 'food');
final ModuleModel _pharmacy = ModuleModel(id: 9, moduleType: 'pharmacy');
final ModuleModel _jumboOffer = ModuleModel(id: 11, moduleType: 'food');

/// Real SplashController whose active module the test switches directly
/// (null = the All Module landing).
class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _FakeSplashService());
  ModuleModel? active;
  @override
  ModuleModel? get module => active;
}

/// Zone 7 serves Food, Pharmacy and Jumbo Offer — `_prepareFeaturedStore` keeps
/// only stores whose module is served in the address's zone.
List<Modules> _zoneModules() => <Modules>[
      for (final int id in <int>[3, 9, 11]) Modules(id: id, pivot: Pivot(zoneId: 7, moduleId: id)),
    ];

/// Featured-store service whose cache and network answers the test releases.
class _GatedStoreService implements StoreServiceInterface {
  final List<({DataSourceEnum source, Completer<List<Store>?> answer})> calls = <({DataSourceEnum source, Completer<List<Store>?> answer})>[];

  @override
  Future<List<Store>?> getFeaturedStoreList({required DataSourceEnum source}) {
    final Completer<List<Store>?> c = Completer<List<Store>?>();
    calls.add((source: source, answer: c));
    return c.future;
  }

  @override
  List<Modules> moduleList() => _zoneModules();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Network for the cache tests: answers each GET with the queued body.
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

/// Network whose single GET is held until the test answers it.
class _HeldApiClient implements ApiClient {
  final List<Completer<Response>> pending = <Completer<Response>>[];
  @override
  Map<String, String> getHeader() => <String, String>{'moduleId': '3', 'zoneId': '[7]'};
  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) {
    final Completer<Response> c = Completer<Response>();
    pending.add(c);
    return c.future;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stores as the backend returns them: all featured stores today are Food (3).
List<Store> _stores(List<int> ids, {int moduleId = 3}) =>
    <Store>[for (final int id in ids) Store(id: id, name: 'Store $id', moduleId: moduleId, zoneId: 7)];
Map<String, dynamic> _storesBody(List<int> ids, {int moduleId = 3}) => <String, dynamic>{
      'stores': <Map<String, dynamic>>[
        for (final int id in ids) <String, dynamic>{'id': id, 'name': 'Store $id', 'module_id': moduleId, 'zone_id': 7, 'featured': 1},
      ],
    };

Future<void> _flush() async {
  for (int i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Directory tmp = Directory.systemTemp.createTempSync('moonjoin_e2c_cache_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async => tmp.path,
  );

  late _Splash splash;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{
      // Saved address in zone 7 serving modules 3, 9 and 11 (read by the real
      // StoreService.moduleList() in the cache tests).
      AppConstants.userAddress: jsonEncode(<String, dynamic>{
        'address': 'Ogbomoso', 'latitude': '8.1335', 'longitude': '4.2402', 'zone_id': 7, 'zone_ids': <int>[7],
        'zone_data': <Map<String, dynamic>>[<String, dynamic>{
          'id': 7, 'status': 1,
          'modules': <Map<String, dynamic>>[
            for (final int id in <int>[3, 9, 11]) <String, dynamic>{'id': id, 'pivot': <String, dynamic>{'zone_id': 7, 'module_id': id}},
          ],
        }],
      }),
    });
    Get.put<SharedPreferences>(await SharedPreferences.getInstance());
    splash = _Splash();
    Get.put<SplashController>(splash);
  });

  tearDown(Get.reset);

  group('late responses and switching (gated service)', () {
    late _GatedStoreService service;
    late StoreController c;
    late int updates;

    setUp(() {
      service = _GatedStoreService();
      c = StoreController(storeServiceInterface: service);
      updates = 0;
      c.addListener(() => updates++);
    });

    test('landing: with the module still null, the featured list loads normally (cache then network)', () async {
      splash.active = null;
      c.getFeaturedStoreList();
      service.calls[0].answer.complete(_stores(<int>[1, 2]));
      await _flush();
      expect(c.featuredStoreList!.map((s) => s.id), <int>[1, 2]);
      service.calls[1].answer.complete(_stores(<int>[1, 2, 3]));
      await _flush();
      expect(c.featuredStoreList!.map((s) => s.id), <int>[1, 2, 3]);
      expect(updates, 2);
    });

    test('same module: Food cache and network answers both apply', () async {
      splash.active = _food;
      c.getFeaturedStoreList();
      service.calls[0].answer.complete(_stores(<int>[301]));
      await _flush();
      expect(c.featuredStoreList!.single.id, 301);
      service.calls[1].answer.complete(_stores(<int>[301, 302]));
      await _flush();
      expect(c.featuredStoreList!.map((s) => s.id), <int>[301, 302]);
    });

    test('clearFeaturedStoreList() sets the list to null; Food\'s load-if-null then fetches Food\'s own list', () async {
      splash.active = null;                                     // landing fills the shared list
      c.getFeaturedStoreList();
      service.calls[0].answer.complete(_stores(<int>[1, 2]));
      await _flush();
      service.calls[1].answer.complete(_stores(<int>[1, 2]));
      await _flush();
      expect(c.featuredStoreList, isNotNull);

      splash.active = _food;                                    // switchModule(Food)
      c.clearFeaturedStoreList();
      expect(c.featuredStoreList, isNull);

      // MoonjoinFoodTopBrands.initState: `if (featuredStoreList == null) getFeaturedStoreList()`.
      if (c.featuredStoreList == null) c.getFeaturedStoreList();
      expect(service.calls, hasLength(3), reason: 'Food now loads its own list instead of reusing the landing one');
      service.calls[2].answer.complete(_stores(<int>[301]));
      await _flush();
      expect(c.featuredStoreList!.single.id, 301);
    });

    test('a late LANDING answer after switching to Food is not applied and does not repaint', () async {
      splash.active = null;
      c.getFeaturedStoreList();                                 // landing cache read pending
      splash.active = _food;
      c.clearFeaturedStoreList();
      service.calls[0].answer.complete(_stores(<int>[1, 2]));
      await _flush();
      expect(c.featuredStoreList, isNull);
      expect(updates, 0);
      expect(service.calls, hasLength(1), reason: 'no follow-up network load for the stale landing request');
    });

    test('a late LANDING network answer does not overwrite Food\'s own list', () async {
      splash.active = null;
      c.getFeaturedStoreList();
      service.calls[0].answer.complete(_stores(<int>[1]));
      await _flush();                                           // landing network in flight: calls[1]

      splash.active = _food;
      c.clearFeaturedStoreList();
      c.getFeaturedStoreList();                                 // Food
      service.calls[2].answer.complete(_stores(<int>[301]));
      await _flush();
      service.calls[3].answer.complete(_stores(<int>[301, 302]));
      await _flush();
      final int before = updates;

      service.calls[1].answer.complete(_stores(<int>[1, 2, 3])); // late landing answer
      await _flush();
      expect(c.featuredStoreList!.map((s) => s.id), <int>[301, 302]);
      expect(updates, before);
    });

    test('a late PHARMACY answer (empty featured list) is not applied to Food', () async {
      splash.active = _pharmacy;
      c.getFeaturedStoreList();                                 // Pharmacy loadData
      service.calls[0].answer.complete(<Store>[]);
      await _flush();                                           // Pharmacy network in flight: calls[1]

      splash.active = _food;
      c.clearFeaturedStoreList();
      c.getFeaturedStoreList();                                 // Food Top Brands
      service.calls[2].answer.complete(_stores(<int>[301]));
      await _flush();
      service.calls[3].answer.complete(_stores(<int>[301]));
      await _flush();
      final int before = updates;

      service.calls[1].answer.complete(<Store>[]);              // late Pharmacy answer
      await _flush();
      expect(c.featuredStoreList!.single.id, 301, reason: 'Food Top Brands must not go empty because of Pharmacy');
      expect(updates, before);
    });

    test('Jumbo Offer (food-type) no longer inherits the landing/Food list: it shows its own (empty) list', () async {
      splash.active = null;                                     // landing: Food restaurants
      c.getFeaturedStoreList();
      service.calls[0].answer.complete(_stores(<int>[1, 2, 3, 4]));
      await _flush();
      service.calls[1].answer.complete(_stores(<int>[1, 2, 3, 4]));
      await _flush();

      splash.active = _jumboOffer;                              // switchModule(Jumbo Offer)
      c.clearFeaturedStoreList();
      if (c.featuredStoreList == null) c.getFeaturedStoreList(); // Food Top Brands (food-type)
      service.calls[2].answer.complete(null);                   // no Jumbo Offer cache yet
      await _flush();
      expect(c.featuredStoreList, isNull, reason: 'never the landing list while Jumbo Offer loads');
      service.calls[3].answer.complete(<Store>[]);              // Jumbo Offer has no featured stores
      await _flush();
      expect(c.featuredStoreList, isEmpty, reason: 'empty → Top Brands hides, instead of showing Food restaurants');
    });
  });

  group('persistent cache (real service + repository + drift cache)', () {
    test('clearFeaturedStoreList() does not delete the module\'s persistent cache', () async {
      splash.active = _food;
      final _FakeApiClient api = _FakeApiClient()..bodies.add(_storesBody(<int>[301, 302]));
      final StoreRepository repo = StoreRepository(apiClient: api, sharedPreferences: Get.find());
      final StoreController c = StoreController(storeServiceInterface: StoreService(storeRepositoryInterface: repo));

      c.getFeaturedStoreList();                                  // cache (empty) → network (writes cache)
      for (int i = 0; i < 200 && (c.featuredStoreList?.length ?? 0) < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(c.featuredStoreList!.map((s) => s.id), <int>[301, 302]);
      // The repository writes the cache fire-and-forget; wait until it is readable.
      List<Store>? written;
      for (int i = 0; i < 200 && (written == null || written.isEmpty); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        written = await repo.getList(isFeaturedStoreList: true, source: DataSourceEnum.local) as List<Store>?;
      }

      c.clearFeaturedStoreList();
      expect(c.featuredStoreList, isNull);

      // Network now fails; the list must come back from Food's persistent cache.
      c.getFeaturedStoreList();
      for (int i = 0; i < 200 && c.featuredStoreList == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(c.featuredStoreList!.map((s) => s.id), <int>[301, 302]);
    });

    test('a discarded Food answer is still cached under Food\'s key and read back later', () async {
      splash.active = _food;
      final _HeldApiClient api = _HeldApiClient();
      final StoreRepository repo = StoreRepository(apiClient: api, sharedPreferences: Get.find());
      final StoreController c = StoreController(storeServiceInterface: StoreService(storeRepositoryInterface: repo));

      // Food: cache read (empty) → the network request goes out and is held.
      c.getFeaturedStoreList();
      for (int i = 0; i < 200 && api.pending.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(api.pending, hasLength(1));

      // The user switches to Pharmacy before the Food answer arrives.
      splash.active = _pharmacy;
      c.clearFeaturedStoreList();
      api.pending.single.complete(Response(statusCode: 200, body: _storesBody(<int>[311])));
      await _flush();
      expect(c.featuredStoreList, isNull, reason: 'the Food result is not applied on Pharmacy');

      // Back on Food: its cache holds the store, written under Food's key.
      splash.active = _food;
      List<Store>? cached;
      for (int i = 0; i < 200 && (cached == null || cached.isEmpty); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        cached = await repo.getList(isFeaturedStoreList: true, source: DataSourceEnum.local) as List<Store>?;
      }
      expect(cached!.single.id, 311);
    });
  });
}
