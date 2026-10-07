// FCM token integrity. saveDeviceToken() used to start from '@' and return it
// whenever FirebaseMessaging.getToken() threw or returned null, and updateToken()
// posted that '@' — overwriting the customer's valid server token (FCM rejects
// '@', so every push to that customer failed). A failed fetch now returns null
// and updateToken() keeps the server token; explicit values (the '@' sentinel for
// notifications-off) are unchanged. FCM token rotations (onTokenRefresh) now
// update the server, through one listener per process.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/features/auth/domain/reposotories/auth_repository.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FirebaseMessaging with a scripted getToken() and a controllable onTokenRefresh.
class _FakeMessaging implements FirebaseMessaging {
  Future<String?> Function() token = () async => 'device-token-1';
  final StreamController<String> refresh = StreamController<String>.broadcast();
  int getTokenCalls = 0;

  @override
  Future<String?> getToken({String? vapidKey}) {
    getTokenCalls++;
    return token();
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

/// Records every cm-firebase-token PUT.
class _ApiClient extends GetxService implements ApiClient {
  final List<Object?> sentTokens = <Object?>[];
  @override
  Future<Response> postData(String uri, dynamic body, {Map<String, String>? headers, int? timeout, bool handleError = true}) async {
    if(uri == AppConstants.tokenUri) sentTokens.add((body as Map<String, dynamic>)['cm_firebase_token']);
    return const Response(statusCode: 200);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() async {
  for(int i = 0; i < 3; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeMessaging messaging;
  late _ApiClient api;
  late SharedPreferences prefs;
  late AuthRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.token: 'auth-token',
      AppConstants.notification: true,
      AppConstants.userAddress: jsonEncode(<String, dynamic>{'latitude': '8.16', 'longitude': '4.25', 'zone_id': 7, 'zone_ids': <int>[7]}),
    });
    prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs);
    messaging = _FakeMessaging();
    api = _ApiClient();
    repository = AuthRepository(sharedPreferences: prefs, apiClient: api, firebaseMessaging: messaging);
  });

  tearDown(() async {
    await AuthRepository.resetTokenRefreshListener();
    await messaging.refresh.close();
    Get.reset();
  });

  group('updateToken()', () {
    test('a real token is posted exactly', () async {
      await repository.updateToken();
      expect(api.sentTokens, <Object?>['device-token-1']);
    });

    test('getToken() returning null posts nothing (server token kept)', () async {
      messaging.token = () async => null;
      await repository.updateToken();
      expect(api.sentTokens, isEmpty);
    });

    test('getToken() throwing posts nothing and does not throw', () async {
      messaging.token = () async => throw Exception('APNS token has not been set yet');
      await repository.updateToken();
      expect(api.sentTokens, isEmpty);
    });

    test("explicit '@' (notifications off) is still posted as given, without fetching", () async {
      await repository.updateToken(notificationDeviceToken: '@');
      expect(api.sentTokens, <Object?>['@']);
      expect(messaging.getTokenCalls, 0);
    });

    test('explicit empty value keeps meaning "fetch the current token"', () async {
      await repository.updateToken(notificationDeviceToken: '');
      expect(api.sentTokens, <Object?>['device-token-1']);
    });
  });

  group('saveDeviceToken()', () {
    test("returns null (never '@') when no token is available", () async {
      messaging.token = () async => null;
      expect(await repository.saveDeviceToken(), isNull);
      messaging.token = () async => '';
      expect(await repository.saveDeviceToken(), isNull);
      messaging.token = () async => throw Exception('offline');
      expect(await repository.saveDeviceToken(), isNull);
    });
  });

  group('onTokenRefresh', () {
    test('a rotated token is posted for a signed-in customer', () async {
      await repository.updateToken();
      messaging.refresh.add('device-token-2');
      await _settle();
      expect(api.sentTokens, <Object?>['device-token-1', 'device-token-2']);
    });

    test("empty or '@' refresh values are never posted", () async {
      await repository.updateToken();
      messaging.refresh.add('');
      messaging.refresh.add('@');
      await _settle();
      expect(api.sentTokens, <Object?>['device-token-1']);
    });

    test('no post after logout (signed out) or with notifications off', () async {
      await repository.updateToken();
      await prefs.remove(AppConstants.token);
      messaging.refresh.add('device-token-2');
      await _settle();
      await prefs.setString(AppConstants.token, 'auth-token');
      await prefs.setBool(AppConstants.notification, false);
      messaging.refresh.add('device-token-3');
      await _settle();
      expect(api.sentTokens, <Object?>['device-token-1']);
    });

    test('repeated updateToken() calls register one listener only', () async {
      await repository.updateToken();
      await repository.updateToken();
      await repository.updateToken();
      api.sentTokens.clear();
      messaging.refresh.add('device-token-2');
      await _settle();
      expect(api.sentTokens, <Object?>['device-token-2'], reason: 'one refresh → one post, not one per updateToken call');
    });
  });
}
