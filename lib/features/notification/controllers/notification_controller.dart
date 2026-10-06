import 'package:moonjoin/features/notification/domain/models/notification_model.dart';
import 'package:moonjoin/helper/date_converter.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/notification/domain/service/notification_service_interface.dart';

class NotificationController extends GetxController implements GetxService {
  final NotificationServiceInterface notificationServiceInterface;
  NotificationController({required this.notificationServiceInterface});

  List<NotificationModel>? _notificationList;
  List<NotificationModel>? get notificationList => _notificationList;

  bool _hasNotification = false;
  bool get hasNotification => _hasNotification;

  Future<int> getNotificationList(bool reload) async {
    if(_notificationList == null || reload) {
      List<NotificationModel>? notificationList = await notificationServiceInterface.getNotificationList();
      if (notificationList != null) {
        _notificationList = [];
        _notificationList!.addAll(notificationList);
        _notificationList!.sort((a, b) {
          return DateConverter.isoStringToLocalDate(a.updatedAt!).compareTo(DateConverter.isoStringToLocalDate(b.updatedAt!));
        });
        Iterable iterable = _notificationList!.reversed;
        _notificationList = iterable.toList() as List<NotificationModel>?;
        _hasNotification = _notificationList!.length != getSeenNotificationCount();
      }
      update();
    }
    return _notificationList!.length;
  }

  void saveSeenNotificationCount(int count) {
    notificationServiceInterface.saveSeenNotificationCount(count);
  }

  int? getSeenNotificationCount() {
    return notificationServiceInterface.getSeenNotificationCount();
  }

  void clearNotification() {
    _notificationList = null;
  }

  List<int>? getSeenNotificationIdList() {
    return notificationServiceInterface.getNotificationIdList();
  }

  /// Notifications in the list the customer has not opened yet (seen IDs are the
  /// ones recorded by addSeenNotificationId).
  int get unreadNotificationCount {
    final List<int> seen = getSeenNotificationIdList() ?? const <int>[];
    return _notificationList?.where((NotificationModel n) => n.id != null && !seen.contains(n.id)).length ?? 0;
  }

  void addSeenNotificationId(int id) {
    List<int> idList = [];
    idList.addAll(notificationServiceInterface.getNotificationIdList());
    idList.add(id);
    notificationServiceInterface.addSeenNotificationIdList(idList);
    update();
  }

}