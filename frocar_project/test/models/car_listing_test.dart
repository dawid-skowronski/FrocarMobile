import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/models/car_listing.dart';

void main() {
  group('CarListing Tests', () {
    test('Konstruktor ustawia wszystkie pola poprawnie', () {
      final carListing = CarListing(
        id: 1,
        brand: 'Toyota',
        engineCapacity: 2.0,
        fuelType: 'Benzyna',
        seats: 5,
        carType: 'Sedan',
        features: ['Klimatyzacja', 'GPS'],
        latitude: 52.2297,
        longitude: 21.0122,
        userId: 1,
        isAvailable: true,
        rentalPricePerDay: 100.0,
        isApproved: true,
        averageRating: 4.5,
      );

      expect(carListing.id, 1);
      expect(carListing.brand, 'Toyota');
      expect(carListing.engineCapacity, 2.0);
      expect(carListing.fuelType, 'Benzyna');
      expect(carListing.seats, 5);
      expect(carListing.carType, 'Sedan');
      expect(carListing.features, ['Klimatyzacja', 'GPS']);
      expect(carListing.latitude, 52.2297);
      expect(carListing.longitude, 21.0122);
      expect(carListing.userId, 1);
      expect(carListing.isAvailable, true);
      expect(carListing.rentalPricePerDay, 100.0);
      expect(carListing.isApproved, true);
      expect(carListing.averageRating, 4.5);
    });

    test('toJson zwraca poprawną mapę', () {
      final carListing = CarListing(
        id: 1,
        brand: 'Toyota',
        engineCapacity: 2.0,
        fuelType: 'Benzyna',
        seats: 5,
        carType: 'Sedan',
        features: ['Klimatyzacja', 'GPS'],
        latitude: 52.2297,
        longitude: 21.0122,
        userId: 1,
        isAvailable: true,
        rentalPricePerDay: 100.0,
        isApproved: true,
        averageRating: 4.5,
      );

      final json = carListing.toJson();

      expect(json['id'], 1);
      expect(json['brand'], 'Toyota');
      expect(json['engineCapacity'], 2.0);
      expect(json['fuelType'], 'Benzyna');
      expect(json['seats'], 5);
      expect(json['carType'], 'Sedan');
      expect(json['features'], ['Klimatyzacja', 'GPS']);
      expect(json['latitude'], 52.2297);
      expect(json['longitude'], 21.0122);
      expect(json['userId'], 1);
      expect(json['isAvailable'], true);
      expect(json['rentalPricePerDay'], 100.0);
      expect(json['isApproved'], true);
      expect(json['averageRating'], 4.5);
    });

    test('fromJson poprawnie deserializuje dane', () {
      final json = {
        'id': 1,
        'brand': 'Toyota',
        'engineCapacity': 2.0,
        'fuelType': 'Benzyna',
        'seats': 5,
        'carType': 'Sedan',
        'features': ['Klimatyzacja', 'GPS'],
        'latitude': 52.2297,
        'longitude': 21.0122,
        'userId': 1,
        'isAvailable': true,
        'rentalPricePerDay': 100.0,
        'isApproved': true,
        'averageRating': 4.5,
      };

      final carListing = CarListing.fromJson(json);

      expect(carListing.id, 1);
      expect(carListing.brand, 'Toyota');
      expect(carListing.engineCapacity, 2.0);
      expect(carListing.fuelType, 'Benzyna');
      expect(carListing.seats, 5);
      expect(carListing.carType, 'Sedan');
      expect(carListing.features, ['Klimatyzacja', 'GPS']);
      expect(carListing.latitude, 52.2297);
      expect(carListing.longitude, 21.0122);
      expect(carListing.userId, 1);
      expect(carListing.isAvailable, true);
      expect(carListing.rentalPricePerDay, 100.0);
      expect(carListing.isApproved, true);
      expect(carListing.averageRating, 4.5);
    });

    test('placeholder zwraca obiekt z domyślnymi wartościami', () {
      final placeholder = CarListing.placeholder();

      expect(placeholder.id, 0);
      expect(placeholder.brand, 'Brak danych');
      expect(placeholder.engineCapacity, 0.0);
      expect(placeholder.fuelType, 'Brak danych');
      expect(placeholder.seats, 0);
      expect(placeholder.carType, 'Brak danych');
      expect(placeholder.features, []);
      expect(placeholder.latitude, 0.0);
      expect(placeholder.longitude, 0.0);
      expect(placeholder.userId, 0);
      expect(placeholder.isAvailable, false);
      expect(placeholder.rentalPricePerDay, 0.0);
      expect(placeholder.isApproved, false);
      expect(placeholder.averageRating, 0.0);
    });
  });
}