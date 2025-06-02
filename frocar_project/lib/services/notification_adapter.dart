import 'package:test_project/models/notification.dart';

abstract class NotificationAdapter {
  List<NotificationModel> convertToNotifications(List<Map<String, dynamic>> source);
}

class MapToNotificationAdapter implements NotificationAdapter {
  @override
  List<NotificationModel> convertToNotifications(List<Map<String, dynamic>> source) {
    return source.map((json) => NotificationModel.fromJson(json)).toList();
  }
}