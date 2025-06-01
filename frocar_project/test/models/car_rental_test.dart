import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_listing.dart';

void main() {
  group('CarRental Tests', () {
    test('Konstruktor ustawia wszystkie pola poprawnie', () {
      final carListing = CarListing.placeholder();
      final rentalStartDate = DateTime(2025, 5, 26);
      final rentalEndDate = DateTime(2025, 5, 28);

      final carRental = CarRental(
        carRentalId: 1,
        carListingId: 1,
        userId: 2,
        rentalStartDate: rentalStartDate,
        rentalEndDate: rentalEndDate,
        rentalPrice: 200.0,
        rentalStatus: 'Confirmed',
        carListing: carListing,
      );

      expect(carRental.carRentalId, 1);
      expect(carRental.carListingId, 1);
      expect(carRental.userId, 2);
      expect(carRental.rentalStartDate, rentalStartDate);
      expect(carRental.rentalEndDate, rentalEndDate);
      expect(carRental.rentalPrice, 200.0);
      expect(carRental.rentalStatus, 'Confirmed');
      expect(carRental.carListing, carListing);
    });

    test('toJson zwraca poprawną mapę', () {
      final carListing = CarListing.placeholder();
      final rentalStartDate = DateTime(2025, 5, 26);
      final rentalEndDate = DateTime(2025, 5, 28);

      final carRental = CarRental(
        carRentalId: 1,
        carListingId: 1,
        userId: 2,
        rentalStartDate: rentalStartDate,
        rentalEndDate: rentalEndDate,
        rentalPrice: 200.0,
        rentalStatus: 'Confirmed',
        carListing: carListing,
      );

      final json = carRental.toJson();

      expect(json['carRentalId'], 1);
      expect(json['carListingId'], 1);
      expect(json['userId'], 2);
      expect(json['rentalStartDate'], rentalStartDate.toIso8601String());
      expect(json['rentalEndDate'], rentalEndDate.toIso8601String());
      expect(json['rentalPrice'], 200.0);
      expect(json['rentalStatus'], 'Confirmed');
      expect(json['carListing'], carListing.toJson());
    });

    test('fromJson poprawnie deserializuje dane', () {
      final carListingJson = CarListing.placeholder().toJson();
      final rentalStartDate = DateTime(2025, 5, 26);
      final rentalEndDate = DateTime(2025, 5, 28);

      final json = {
        'carRentalId': 1,
        'carListingId': 1,
        'userId': 2,
        'rentalStartDate': rentalStartDate.toIso8601String(),
        'rentalEndDate': rentalEndDate.toIso8601String(),
        'rentalPrice': 200.0,
        'rentalStatus': 'Confirmed',
        'carListing': carListingJson,
      };

      final carRental = CarRental.fromJson(json);

      expect(carRental.carRentalId, 1);
      expect(carRental.carListingId, 1);
      expect(carRental.userId, 2);
      expect(carRental.rentalStartDate, rentalStartDate);
      expect(carRental.rentalEndDate, rentalEndDate);
      expect(carRental.rentalPrice, 200.0);
      expect(carRental.rentalStatus, 'Confirmed');
      expect(carRental.carListing.id, carListingJson['id']);
    });
  });
}