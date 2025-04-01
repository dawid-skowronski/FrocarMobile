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
      carListing: CarListing.fromJson(json['carListing']),
    );
  }
}