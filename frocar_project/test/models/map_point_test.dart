import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/models/map_point.dart';

void main() {
  group('MapPoint Tests', () {
    test('Konstruktor ustawia wszystkie pola poprawnie z id', () {
      final mapPoint = MapPoint(
        id: 1,
        latitude: 52.2297,
        longitude: 21.0122,
        userId: 2,
      );

      expect(mapPoint.id, 1);
      expect(mapPoint.latitude, 52.2297);
      expect(mapPoint.longitude, 21.0122);
      expect(mapPoint.userId, 2);
    });

    test('Konstruktor ustawia wszystkie pola poprawnie bez id', () {
      final mapPoint = MapPoint(
        latitude: 52.2297,
        longitude: 21.0122,
        userId: 2,
      );

      expect(mapPoint.id, isNull);
      expect(mapPoint.latitude, 52.2297);
      expect(mapPoint.longitude, 21.0122);
      expect(mapPoint.userId, 2);
    });

    test('toJson zwraca poprawną mapę', () {
      final mapPoint = MapPoint(
        id: 1,
        latitude: 52.2297,
        longitude: 21.0122,
        userId: 2,
      );

      final json = mapPoint.toJson();

      expect(json['latitude'], 52.2297);
      expect(json['longitude'], 21.0122);
      expect(json['userId'], 2);
      expect(json.containsKey('id'), false); // toJson nie zawiera id
    });

    test('fromJson poprawnie deserializuje dane', () {
      final json = {
        'id': 1,
        'latitude': 52.2297,
        'longitude': 21.0122,
        'userId': 2,
      };

      final mapPoint = MapPoint.fromJson(json);

      expect(mapPoint.id, 1);
      expect(mapPoint.latitude, 52.2297);
      expect(mapPoint.longitude, 21.0122);
      expect(mapPoint.userId, 2);
    });
  });
}