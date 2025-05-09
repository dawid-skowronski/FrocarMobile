import 'package:test_project/models/user.dart';
import 'package:test_project/models/car_rental.dart';

class CarRentalReview {
  final int reviewId;
  final int carRentalId;
  final CarRental carRental;
  final int userId;
  final User user;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  CarRentalReview({
    required this.reviewId,
    required this.carRentalId,
    required this.carRental,
    required this.userId,
    required this.user,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory CarRentalReview.fromJson(Map<String, dynamic> json) {
    return CarRentalReview(
      reviewId: json['reviewId'] ?? 0,
      carRentalId: json['carRentalId'] ?? 0,
      carRental: CarRental.fromJson(json['carRental'] ?? {}),
      userId: json['userId'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'carRentalId': carRentalId,
      'carRental': carRental.toJson(),
      'userId': userId,
      'user': user.toJson(),
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}