// Slice D1 — AdvertisementRepository must make exactly ONE network call per
// network load, and none on the local (cache) read. Previously an unconditional
// trailing apiClient.getData ran after the switch: the local read hit the
// network once and the client read twice (3 calls per controller load).

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/features/home/controllers/advertisement_controller.dart';
import 'package:moonjoin/features/home/domain/models/advertisement_model.dart';
import 'package:moonjoin/features/home/domain/repositories/advertisement_repository.dart';
import 'package:moonjoin/features/home/domain/services/advertisement_service.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Counts GETs and answers each with the next queued response.
class _FakeApiClient implements ApiClient {
  final List<String> calls = <String>[];
  final List<Response> responses = <Response>[];

  @override
  Map<String, String> getHeader() => <String, String>{'moduleId': '3', 'zoneId': '[7]'};

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    calls.add(uri);
    return responses.isNotEmpty ? responses.removeAt(0) : const Response(statusCode: 500, statusText: 'no response queued');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Holds the network answer until the test releases it.
class _GatedApiClient implements ApiClient {
  _GatedApiClient(this._answer);
  final Future<Response> _answer;
  int calls = 0;

  @override
  Map<String, String> getHeader() => <String, String>{'moduleId': '3', 'zoneId': '[7]'};

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) {
    calls++;
    return _answer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Response _ok(List<Map<String, dynamic>> ads) => Response(statusCode: 200, body: ads);
const Response _fail = Response(statusCode: 500, statusText: 'Server error');
Map<String, dynamic> _ad(int id) => <String, dynamic>{'id': id, 'add_type': 'store_promotion', 'title': 'Ad $id'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // LocalClient's mobile cache is a real drift database; point path_provider at a
  // throwaway directory so the cache can actually be written and read here.
  final Directory tmp = Directory.systemTemp.createTempSync('moonjoin_ads_cache_');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async => tmp.path,
  );

  late _FakeApiClient api;
  late AdvertisementRepository repo;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Get.put<SharedPreferences>(await SharedPreferences.getInstance());
    Get.put<SplashController>(SplashController(splashServiceInterface: _FakeSplashService()));
    api = _FakeApiClient();
    repo = AdvertisementRepository(apiClient: api);
  });

  tearDown(Get.reset);

  group('AdvertisementRepository.getList', () {
    test('local (cache) read makes NO network call', () async {
      await repo.getList(source: DataSourceEnum.local);
      expect(api.calls, isEmpty);
    });

    test('network read with no cache makes exactly ONE call and returns its data', () async {
      api.responses.add(_ok(<Map<String, dynamic>>[_ad(1), _ad(2)]));
      final List<AdvertisementModel>? list = await repo.getList(source: DataSourceEnum.client);
      expect(api.calls, hasLength(1));
      expect(list!.map((a) => a.id), <int>[1, 2]);
    });

    test('a failed network read returns null (existing list is kept by the controller) and does not retry itself', () async {
      api.responses.add(_fail);
      final List<AdvertisementModel>? list = await repo.getList(source: DataSourceEnum.client);
      expect(list, isNull);
      expect(api.calls, hasLength(1));
    });

    test('a successful network read writes the cache; a later local read serves it with NO network call', () async {
      api.responses.add(_ok(<Map<String, dynamic>>[_ad(41), _ad(42)]));
      await repo.getList(source: DataSourceEnum.client);
      await Future<void>.delayed(const Duration(milliseconds: 300)); // cache write is fire-and-forget
      final List<AdvertisementModel>? cached = await repo.getList(source: DataSourceEnum.local);
      expect(cached!.map((a) => a.id), <int>[41, 42]);
      expect(api.calls, hasLength(1));
    });

    test('a failure does not poison the next load', () async {
      api.responses..add(_fail)..add(_ok(<Map<String, dynamic>>[_ad(7)]));
      expect(await repo.getList(source: DataSourceEnum.client), isNull);
      final List<AdvertisementModel>? retry = await repo.getList(source: DataSourceEnum.client);
      expect(retry!.single.id, 7);
      expect(api.calls, hasLength(2));
    });
  });

  group('AdvertisementController load (real repository + service)', () {
    late AdvertisementController controller;

    setUp(() {
      controller = AdvertisementController(
        advertisementServiceInterface: AdvertisementService(advertisementRepositoryInterface: repo),
      );
    });

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

    test('one logical load (cache-first, then refresh) makes exactly ONE network call — not three', () async {
      api.responses.add(_ok(<Map<String, dynamic>>[_ad(1)]));
      await controller.getAdvertisementList();
      await settle();
      expect(api.calls, hasLength(1));
      expect(controller.advertisementList!.single.id, 1);
    });

    test('an explicit reload makes exactly ONE more network call', () async {
      api.responses..add(_ok(<Map<String, dynamic>>[_ad(1)]))..add(_ok(<Map<String, dynamic>>[_ad(2)]));
      await controller.getAdvertisementList();
      await settle();
      await controller.getAdvertisementList();
      await settle();
      expect(api.calls, hasLength(2));
      expect(controller.advertisementList!.single.id, 2);
    });

    test('with a warm cache: cached ads are shown first, then exactly ONE refresh call replaces them', () async {
      api.responses.add(_ok(<Map<String, dynamic>>[_ad(51)]));
      await repo.getList(source: DataSourceEnum.client); // warm the cache
      await Future<void>.delayed(const Duration(milliseconds: 300));
      api.calls.clear();

      final Completer<Response> refresh = Completer<Response>();
      final _GatedApiClient gated = _GatedApiClient(refresh.future);
      final AdvertisementController c = AdvertisementController(
        advertisementServiceInterface: AdvertisementService(
          advertisementRepositoryInterface: AdvertisementRepository(apiClient: gated),
        ),
      );
      await c.getAdvertisementList();
      expect(c.advertisementList!.single.id, 51, reason: 'cache must render before the network answers');
      refresh.complete(_ok(<Map<String, dynamic>>[_ad(52)]));
      await settle();
      expect(c.advertisementList!.single.id, 52);
      expect(gated.calls, 1);
    });

    test('offline with a warm cache: the cached list stays when the refresh fails', () async {
      api.responses.add(_ok(<Map<String, dynamic>>[_ad(61)]));
      await repo.getList(source: DataSourceEnum.client); // warm the cache
      await Future<void>.delayed(const Duration(milliseconds: 300));
      api.responses.add(_fail);
      await controller.getAdvertisementList();
      await settle();
      expect(controller.advertisementList!.single.id, 61);
    });

    test('offline / failed refresh keeps the list already shown', () async {
      api.responses..add(_ok(<Map<String, dynamic>>[_ad(1)]))..add(_fail);
      await controller.getAdvertisementList();
      await settle();
      await controller.getAdvertisementList();
      await settle();
      expect(controller.advertisementList!.single.id, 1);
    });
  });
}
