import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_rental_review.dart';

class ApiService {
  final String baseUrl = 'http://localhost:5001';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> changeUsername(String newUsername) async {
    final url = '$baseUrl/api/Account/change-username';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newUsername': newUsername}),
    );

    if (response.statusCode != 200) {
      throw Exception('Błąd podczas zmiany nazwy użytkownika: Status ${response.statusCode}, Treść: ${response.body}');
    }

    await logout();
  }

  Future<void> logout() async {
    final url = '$baseUrl/api/Account/logout';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'username');
    } else {
      throw Exception('Błąd podczas wylogowywania: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<void> createCarListing(CarListing carListing) async {
    final url = '$baseUrl/api/CarListings/create';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(carListing.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Błąd podczas dodawania ogłoszenia: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<void> updateCarListing(CarListing carListing) async {
    final url = '$baseUrl/api/CarListings/${carListing.id}';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(carListing.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Błąd podczas aktualizacji ogłoszenia: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<List<CarListing>> getUserCarListings() async {
    final url = '$baseUrl/api/CarListings/user';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarListing.fromJson(json)).toList();
    } else {
      throw Exception('Błąd podczas pobierania ogłoszeń: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<List<CarListing>> getCarListings() async {
    final url = '$baseUrl/api/CarListings/List';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarListing.fromJson(json)).toList();
    } else {
      throw Exception('Błąd podczas pobierania ogłoszeń: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<void> createCarRental(int carListingId, DateTime startDate, DateTime endDate) async {
    final url = '$baseUrl/api/CarRental/create';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'carListingId': carListingId,
        'rentalStartDate': startDate.toIso8601String(),
        'rentalEndDate': endDate.toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Błąd podczas tworzenia wypożyczenia: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<List<CarRental>> _getActiveUserCarRentals() async {
    final url = '$baseUrl/api/CarRental/user';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarRental.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Błąd podczas pobierania aktywnych wypożyczeń: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<List<CarRental>> _getEndedUserCarRentals() async {
    final url = '$baseUrl/api/CarRental/user/history';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarRental.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Błąd podczas pobierania zakończonych wypożyczeń: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  Future<List<CarRental>> getUserCarRentals() async {
    try {
      final results = await Future.wait([
        _getActiveUserCarRentals(),
        _getEndedUserCarRentals(),
      ]);

      final activeRentals = results[0];
      final endedRentals = results[1];
      final allRentals = [...activeRentals, ...endedRentals];

      allRentals.sort((a, b) => b.rentalStartDate.compareTo(a.rentalStartDate));

      return allRentals;
    } catch (e) {
      throw Exception('Błąd podczas pobierania wypożyczeń: $e');
    }
  }

  Future<List<CarRentalReview>> getReviewsForListing(int listingId) async {
    final url = '$baseUrl/api/CarRental/reviews/$listingId';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Parsed data: $data');
        final reviews = data.map((json) => CarRentalReview.fromJson(json)).toList();
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Błąd podczas pobierania recenzji: Status ${response.statusCode}, Treść: ${response.body}');
      }
    } catch (e) {
      print('Error in getReviewsForListing: $e');
      rethrow;
    }
  }

  Future<void> addReview(int carRentalId, int rating, String? comment) async {
    final url = '$baseUrl/api/CarRental/review';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'carRentalId': carRentalId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Błąd podczas dodawania recenzji: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }
}