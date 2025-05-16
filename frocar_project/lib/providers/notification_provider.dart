import 'package:flutter/foundation.dart';

class NotificationProvider with ChangeNotifier {
  int _notificationCount = 0;

  int get notificationCount => _notificationCount;

  void setNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }

  void incrementNotificationCount() {
    _notificationCount++;
    notifyListeners();
  }

  void resetNotificationCount() {
    _notificationCount = 0;
    notifyListeners();
  }
}