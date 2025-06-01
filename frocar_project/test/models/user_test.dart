import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/models/user.dart';

void main() {
  group('User Tests', () {
    test('Konstruktor ustawia wszystkie pola poprawnie', () {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'Admin',
      );

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.role, 'Admin');
    });

    test('toJson zwraca poprawną mapę', () {
      final user = User(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        role: 'Admin',
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['username'], 'testuser');
      expect(json['email'], 'test@example.com');
      expect(json['role'], 'Admin');
    });

    test('fromJson poprawnie deserializuje dane', () {
      final json = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'role': 'Admin',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.role, 'Admin');
    });

    test('fromJson ustawia domyślną rolę User, jeśli brak roli', () {
      final json = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.role, 'User'); // Domyślna rola
    });
  });
}