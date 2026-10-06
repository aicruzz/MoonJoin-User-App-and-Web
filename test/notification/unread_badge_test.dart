// Home notification badge shows UNREAD notifications only. The redesigned Home
// header was given notificationList.length (every notification), so the badge
// never went down. It now gets NotificationController.unreadNotificationCount:
// the list minus the IDs the customer has opened (addSeenNotificationId, kept in
// SharedPreferences under notification_id_list). The header itself is unchanged:
// > 99 → "99+", 0 → no badge.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/api/api_client.dart';
import 'package:moonjoin/common/widgets/moonjoin/module_header.dart';
import 'package:moonjoin/features/notification/controllers/notification_controller.dart';
import 'package:moonjoin/features/notification/domain/repository/notification_repository.dart';
import 'package:moonjoin/features/notification/domain/service/notification_service.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves the notification list the backend would return.
class _ApiClient extends GetxService implements ApiClient {
  List<Map<String, dynamic>> notifications = <Map<String, dynamic>>[];
  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true}) async {
    return Response(statusCode: 200, body: uri == AppConstants.notificationUri ? notifications : <dynamic>[]);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _notification(int id) => <String, dynamic>{
      'id': id,
      'data': <String, dynamic>{'title': 'Order #$id', 'description': 'Status update', 'type': 'order_status'},
      'created_at': '2026-10-06T10:00:00.000000Z',
      'updated_at': '2026-10-06T10:00:${(id % 60).toString().padLeft(2, '0')}.000000Z',
    };

void main() {
  late _ApiClient api;

  /// Real controller → service → repository, with [seenIds] already opened.
  Future<NotificationController> controllerWith(List<int> ids, {List<int> seenIds = const <int>[]}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppConstants.notificationIdList: seenIds.map((int id) => '$id').toList(),
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    api = _ApiClient()..notifications = ids.map(_notification).toList();
    final NotificationController controller = NotificationController(
      notificationServiceInterface: NotificationService(
        notificationRepositoryInterface: NotificationRepository(apiClient: api, sharedPreferences: prefs),
      ),
    );
    await controller.getNotificationList(true);
    return controller;
  }

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  group('NotificationController.unreadNotificationCount', () {
    test('total notifications minus seen IDs', () async {
      final NotificationController controller = await controllerWith(<int>[1, 2, 3, 4, 5], seenIds: <int>[2, 4]);
      expect(controller.notificationList!.length, 5);
      expect(controller.unreadNotificationCount, 3);
    });

    test('all notifications seen → 0', () async {
      final NotificationController controller = await controllerWith(<int>[1, 2, 3], seenIds: <int>[1, 2, 3]);
      expect(controller.unreadNotificationCount, 0);
    });

    test('opening a notification (addSeenNotificationId) lowers the count by 1', () async {
      final NotificationController controller = await controllerWith(<int>[1, 2, 3]);
      expect(controller.unreadNotificationCount, 3);
      controller.addSeenNotificationId(2);
      expect(controller.unreadNotificationCount, 2);
    });

    test('seen IDs no longer in the list do not affect the count; no list → 0', () async {
      final NotificationController controller = await controllerWith(<int>[10, 11], seenIds: <int>[1, 2, 10]);
      expect(controller.unreadNotificationCount, 1);
      controller.clearNotification();
      expect(controller.unreadNotificationCount, 0);
    });
  });

  group('MoonjoinModuleHeader notification badge', () {
    Future<void> pumpHeader(WidgetTester tester, int count) async {
      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: MoonjoinModuleHeader(title: 'Home', notificationCount: count, onNotificationTap: () {}),
        ),
      ));
    }

    testWidgets('shows the unread count', (WidgetTester tester) async {
      await pumpHeader(tester, 3);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows 99+ above 99', (WidgetTester tester) async {
      await pumpHeader(tester, 120);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('120'), findsNothing);
    });

    testWidgets('shows no badge at 0 (never "0")', (WidgetTester tester) async {
      await pumpHeader(tester, 0);
      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget, reason: 'bell still shown');
    });
  });
}
