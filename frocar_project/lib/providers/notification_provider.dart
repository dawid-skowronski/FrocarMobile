import 'package:flutter/foundation.dart';

class NotificationProvider with ChangeNotifier {
  int _notificationCount = 0;

  int get notificationCount => _notificationCount;

  void setNotificationCount(int count) {
    if (_notificationCount != count) {
      _notificationCount = count;
      notifyListeners();
    }
  }

  void incrementNotificationCount() {
    _notificationCount++;
    notifyListeners();
  }

  void resetNotificationCount() {
    if (_notificationCount != 0) {
      _notificationCount = 0;
      notifyListeners();
    }
  }
}