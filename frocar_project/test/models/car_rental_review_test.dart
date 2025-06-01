import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/models/car_rental_review.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/user.dart';
import 'package:test_project/models/car_listing.dart';

void main() {
  group('CarRentalReview Tests', () {
    test('Konstruktor ustawia wszystkie pola poprawnie', () {
      final carRental = CarRental(
        carRentalId: 1,
        carListingId: 1,
        userId: 2,
        rentalStartDate: DateTime(2025, 5, 26),
        rentalEndDate: DateTime(2025, 5, 28),
        rentalPrice: 200.0,
        rentalStatus: 'Confirmed',
        carListing: CarListing.placeholder(),
      );
      final user = User(id: 2, username: 'testuser', email: 'test@example.com', role: 'User');
      final createdAt = DateTime(2025, 5, 29);

      final review = CarRentalReview(
        reviewId: 1,
        carRentalId: 1,
        carRental: carRental,
        userId: 2,
        user: user,
        rating: 5,
        comment: 'Świetny samochód!',
        createdAt: createdAt,
      );

      expect(review.reviewId, 1);
      expect(review.carRentalId, 1);
      expect(review.carRental, carRental);
      expect(review.userId, 2);
      expect(review.user, user);
      expect(review.rating, 5);
      expect(review.comment, 'Świetny samochód!');
      expect(review.createdAt, createdAt);
    });

    test('toJson zwraca poprawną mapę', () {
      final carRental = CarRental(
        carRentalId: 1,
        carListingId: 1,
        userId: 2,
        rentalStartDate: DateTime(2025, 5, 26),
        rentalEndDate: DateTime(2025, 5, 28),
        rentalPrice: 200.0,
        rentalStatus: 'Confirmed',
        carListing: CarListing.placeholder(),
      );
      final user = User(id: 2, username: 'testuser', email: 'test@example.com', role: 'User');
      final createdAt = DateTime(2025, 5, 29);

      final review = CarRentalReview(
        reviewId: 1,
        carRentalId: 1,
        carRental: carRental,
        userId: 2,
        user: user,
        rating: 5,
        comment: 'Świetny samochód!',
        createdAt: createdAt,
      );

      final json = review.toJson();

      expect(json['reviewId'], 1);
      expect(json['carRentalId'], 1);
      expect(json['carRental'], carRental.toJson());
      expect(json['userId'], 2);
      expect(json['user'], user.toJson());
      expect(json['rating'], 5);
      expect(json['comment'], 'Świetny samochód!');
      expect(json['createdAt'], createdAt.toIso8601String());
    });

    test('fromJson poprawnie deserializuje dane', () {
      final carRentalJson = CarRental(
        carRentalId: 1,
        carListingId: 1,
        userId: 2,
        rentalStartDate: DateTime(2025, 5, 26),
        rentalEndDate: DateTime(2025, 5, 28),
        rentalPrice: 200.0,
        rentalStatus: 'Confirmed',
        carListing: CarListing.placeholder(),
      ).toJson();
      final userJson = User(id: 2, username: 'testuser', email: 'test@example.com', role: 'User').toJson();
      final createdAt = DateTime(2025, 5, 29);

      final json = {
        'reviewId': 1,
        'carRentalId': 1,
        'carRental': carRentalJson,
        'userId': 2,
        'user': userJson,
        'rating': 5,
        'comment': 'Świetny samochód!',
        'createdAt': createdAt.toIso8601String(),
      };

      final review = CarRentalReview.fromJson(json);

      expect(review.reviewId, 1);
      expect(review.carRentalId, 1);
      expect(review.carRental.carRentalId, carRentalJson['carRentalId']);
      expect(review.userId, 2);
      expect(review.user.id, userJson['id']);
      expect(review.rating, 5);
      expect(review.comment, 'Świetny samochód!');
      expect(review.createdAt, createdAt);
    });
  });
}