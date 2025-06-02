import 'package:test_project/models/car_listing.dart';

class CarRental {
  final int carRentalId;
  final int carListingId;
  final int userId;
  final DateTime rentalStartDate;
  final DateTime rentalEndDate;
  final double rentalPrice;
  final String rentalStatus;
  final CarListing carListing;

  CarRental({
    required this.carRentalId,
    required this.carListingId,
    required this.userId,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.rentalPrice,
    required this.rentalStatus,
    required this.carListing,
  });

  factory CarRental.fromJson(Map<String, dynamic> json) {
    return CarRental(
      carRentalId: json['carRentalId'],
      carListingId: json['carListingId'],
      userId: json['userId'],
      rentalStartDate: DateTime.parse(json['rentalStartDate']),
      rentalEndDate: DateTime.parse(json['rentalEndDate']),
      rentalPrice: json['rentalPrice'].toDouble(),
      rentalStatus: json['rentalStatus'],
      carListing: json['carListing'] != null
          ? CarListing.fromJson(json['carListing'])
          : CarListingBuilder()
          .setId(0)
          .setBrand('Brak danych')
          .setEngineCapacity(0.0)
          .setFuelType('Brak danych')
          .setSeats(0)
          .setCarType('Brak danych')
          .setFeatures([])
          .setLatitude(0.0)
          .setLongitude(0.0)
          .setUserId(0)
          .setIsAvailable(false)
          .setRentalPricePerDay(0.0)
          .setIsApproved(false)
          .setAverageRating(0.0)
          .build(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carRentalId': carRentalId,
      'carListingId': carListingId,
      'userId': userId,
      'rentalStartDate': rentalStartDate.toIso8601String(),
      'rentalEndDate': rentalEndDate.toIso8601String(),
      'rentalPrice': rentalPrice,
      'rentalStatus': rentalStatus,
      'carListing': carListing.toJson(),
    };
  }
}