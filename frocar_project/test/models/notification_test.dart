import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/models/notification.dart';

void main() {
  group('NotificationModel Tests', () {
    test('Konstruktor ustawia wszystkie pola poprawnie', () {
      final createdAt = DateTime(2025, 5, 26);

      final notification = NotificationModel(
        notificationId: 1,
        userId: 2,
        message: 'Nowe wypożyczenie!',
        createdAt: createdAt,
        isRead: false,
      );

      expect(notification.notificationId, 1);
      expect(notification.userId, 2);
      expect(notification.message, 'Nowe wypożyczenie!');
      expect(notification.createdAt, createdAt);
      expect(notification.isRead, false);
    });

    test('toJson zwraca poprawną mapę', () {
      final createdAt = DateTime(2025, 5, 26);

      final notification = NotificationModel(
        notificationId: 1,
        userId: 2,
        message: 'Nowe wypożyczenie!',
        createdAt: createdAt,
        isRead: false,
      );

      final json = notification.toJson();

      expect(json['notificationId'], 1);
      expect(json['userId'], 2);
      expect(json['message'], 'Nowe wypożyczenie!');
      expect(json['createdAt'], createdAt.toIso8601String());
      expect(json['isRead'], false);
    });

    test('fromJson poprawnie deserializuje dane', () {
      final createdAt = DateTime(2025, 5, 26);

      final json = {
        'notificationId': 1,
        'userId': 2,
        'message': 'Nowe wypożyczenie!',
        'createdAt': createdAt.toIso8601String(),
        'isRead': false,
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.notificationId, 1);
      expect(notification.userId, 2);
      expect(notification.message, 'Nowe wypożyczenie!');
      expect(notification.createdAt, createdAt);
      expect(notification.isRead, false);
    });
  });
}