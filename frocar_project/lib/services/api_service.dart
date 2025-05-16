import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_rental_review.dart';
import 'package:test_project/models/notification.dart';

class ApiService {
  final String baseUrl = 'http://localhost:5001';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/api/account/register');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          'Username': username,
          'Email': email,
          'Password': password,
          'ConfirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Błąd rejestracji: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas rejestracji: $e');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/account/login');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          'Username': username,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final token = responseBody['token'];
        if (token != null) {
          await _storage.write(key: 'token', value: token);
          await _storage.write(key: 'username', value: username);
        }
        return responseBody;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Błąd logowania: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas logowania: $e');
    }
  }

  Future<void> changeUsername(String newUsername) async {
    final url = Uri.parse('$baseUrl/api/Account/change-username');
    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode({'newUsername': newUsername}),
      );

      if (response.statusCode == 200) {
        await logout();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd zmiany nazwy użytkownika: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas zmiany nazwy użytkownika: $e');
    }
  }

  Future<void> logout() async {
    final url = Uri.parse('$baseUrl/api/Account/logout');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        await _storage.delete(key: 'token');
        await _storage.delete(key: 'username');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Błąd wylogowywania: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas wylogowywania: $e');
    }
  }

  Future<void> createCarListing(CarListing carListing) async {
    final url = Uri.parse('$baseUrl/api/CarListings/create');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(carListing.toJson()),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd dodawania ogłoszenia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas dodawania ogłoszenia: $e');
    }
  }

  Future<void> updateCarListing(CarListing carListing) async {
    final url = Uri.parse('$baseUrl/api/CarListings/${carListing.id}');
    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(carListing.toJson()),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd aktualizacji ogłoszenia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas aktualizacji ogłoszenia: $e');
    }
  }

  Future<List<CarListing>> getUserCarListings() async {
    final url = Uri.parse('$baseUrl/api/CarListings/user');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CarListing.fromJson(json)).toList();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd pobierania ogłoszeń: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania ogłoszeń: $e');
    }
  }

  Future<List<CarListing>> getCarListings() async {
    final url = Uri.parse('$baseUrl/api/CarListings/List');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CarListing.fromJson(json)).toList();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd pobierania ogłoszeń: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania ogłoszeń: $e');
    }
  }

  Future<void> createCarRental(int carListingId, DateTime startDate, DateTime endDate) async {
    final url = Uri.parse('$baseUrl/api/CarRental/create');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode({
          'carListingId': carListingId,
          'rentalStartDate': startDate.toIso8601String(),
          'rentalEndDate': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd tworzenia wypożyczenia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas tworzenia wypożyczenia: $e');
    }
  }

  Future<List<CarRental>> _getActiveUserCarRentals() async {
    final url = Uri.parse('$baseUrl/api/CarRental/user');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CarRental.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ??
            'Błąd pobierania aktywnych wypożyczeń: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania aktywnych wypożyczeń: $e');
    }
  }

  Future<List<CarRental>> _getEndedUserCarRentals() async {
    final url = Uri.parse('$baseUrl/api/CarRental/user/history');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CarRental.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ??
            'Błąd pobierania zakończonych wypożyczeń: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania zakończonych wypożyczeń: $e');
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
    final url = Uri.parse('$baseUrl/api/CarRental/reviews/$listingId');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final reviews = data.map((json) => CarRentalReview.fromJson(json)).toList();
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd pobierania recenzji: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania recenzji: $e');
    }
  }

  Future<void> addReview(int carRentalId, int rating, String? comment) async {
    final url = Uri.parse('$baseUrl/api/CarRental/review');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode({
          'carRentalId': carRentalId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd dodawania recenzji: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas dodawania recenzji: $e');
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final url = Uri.parse('$baseUrl/api/Notification');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['message'] == 'Brak nowych powiadomień.') {
          return [];
        }
        final List<dynamic> notifications = data;
        return notifications.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd pobierania powiadomień: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania powiadomień: $e');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final url = Uri.parse('$baseUrl/api/Notification/$notificationId');
    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ??
            'Błąd oznaczania powiadomienia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas oznaczania powiadomienia jako przeczytanego: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAccountNotifications() async {
    final url = Uri.parse('$baseUrl/api/Account/Notification');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Przekroczono czas oczekiwania na odpowiedź serwera.');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['message'] != null) {
          return [];
        } else {
          throw Exception('Nieoczekiwany format odpowiedzi: $data');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            errorBody['message'] ?? 'Błąd pobierania powiadomień: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania powiadomień: $e');
    }
  }

  Future<void> markAccountNotificationAsRead(int notificationId) async {
    final url = Uri.parse('$baseUrl/api/Account/Notification/$notificationId');
    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Przekroczono czas oczekiwania na odpowiedź serwera.');
      });

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ??
            'Błąd oznaczania powiadomienia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas oznaczania powiadomienia jako przeczytanego: $e');
    }
  }
}