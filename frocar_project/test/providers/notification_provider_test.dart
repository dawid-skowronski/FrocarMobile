import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/providers/notification_provider.dart';

void main() {
  group('NotificationProvider Tests', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('Początkowy stan licznika powiadomień to 0', () {
      expect(provider.notificationCount, 0);
    });

    test('setNotificationCount ustawia poprawną wartość i powiadamia słuchaczy', () {
      var notifyCalled = false;
      provider.addListener(() {
        notifyCalled = true;
      });

      provider.setNotificationCount(5);
      expect(provider.notificationCount, 5);
      expect(notifyCalled, true);
    });

    test('incrementNotificationCount zwiększa licznik o 1 i powiadamia słuchaczy', () {
      var notifyCalled = false;
      provider.addListener(() {
        notifyCalled = true;
      });

      provider.incrementNotificationCount();
      expect(provider.notificationCount, 1);
      expect(notifyCalled, true);

      provider.incrementNotificationCount();
      expect(provider.notificationCount, 2);
    });

    test('resetNotificationCount resetuje licznik do 0 i powiadamia słuchaczy', () {
      provider.setNotificationCount(10);
      var notifyCalled = false;
      provider.addListener(() {
        notifyCalled = true;
      });

      provider.resetNotificationCount();
      expect(provider.notificationCount, 0);
      expect(notifyCalled, true);
    });
  });
}