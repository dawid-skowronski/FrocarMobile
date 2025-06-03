import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_rental_review.dart';
import 'package:test_project/models/notification.dart';

class ApiService {
  final String baseUrl = 'https://projekt-tripify.hostingasp.pl';
  final FlutterSecureStorage _storage;
  final http.Client _client;

  ApiService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

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

  Future<void> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/api/Account/request-password-reset');
    try {
      final response = await _client.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(email),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        print('DEBUG: Odpowiedź błędu z API (status: ${response.statusCode}): $errorBody');

        String errorMessage;

        if (errorBody is Map && errorBody.containsKey('message') && errorBody['message'] is String) {
          errorMessage = errorBody['message'];
        } else if (errorBody is Map && errorBody.containsKey('error') && errorBody['error'] is String) {
          errorMessage = errorBody['error'];
        }
        else {
          errorMessage = 'Błąd serwera (status: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Wyjątek w ApiService.requestPasswordReset: $e');
      throw Exception('Błąd podczas wysyłania żądania resetowania hasła: $e');
    }
  }

  Future<Map<String, dynamic>> register(
      String username, String email, String password, String confirmPassword) async {
    final url = Uri.parse('$baseUrl/api/account/register');
    try {
      final response = await _client.post(
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
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Błąd rejestracji: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas rejestracji: $e');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/account/login');
    try {
      final response = await _client.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          'Username': username,
          'Password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        final token = responseBody['token'];
        if (token != null) {
          await _storage.write(key: 'token', value: token);
          await _storage.write(key: 'username', value: username);
        }
        return responseBody;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ?? 'Błąd logowania: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas logowania: $e');
    }
  }

  Future<bool> isTokenValid() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return false;

    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/account/verify-token'),
        headers: await _getHeaders(requiresAuth: true),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  Future<void> changeUsername(String newUsername) async {
    final url = Uri.parse('$baseUrl/api/Account/change-username');
    final response = await _client.put(
      url,
      headers: await _getHeaders(requiresAuth: true),
      body: json.encode({'newUsername': newUsername}),
    );

    if (response.statusCode != 200) {
      final errorBody = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(
        errorBody['message'] ?? 'Błąd zmiany nazwy użytkownika: ${response.statusCode}',
      );
    } else {
      await _storage.write(key: 'username', value: newUsername);
    }
  }

  Future<void> logout() async {
    final url = Uri.parse('$baseUrl/api/Account/logout');
    try {
      final response = await _client.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        await _storage.delete(key: 'token');
        await _storage.delete(key: 'username');
        await _storage.delete(key: 'password');
      } else {
        final bodyString = utf8.decode(response.bodyBytes);
        if (bodyString.isNotEmpty) {
          final errorBody = json.decode(bodyString);
          throw Exception(errorBody['message'] ?? 'Błąd wylogowywania: ${response.statusCode}');
        } else {
          throw Exception('Błąd wylogowywania: ${response.statusCode}');
        }
      }
    } catch (e) {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'username');
      await _storage.delete(key: 'password');
      throw Exception('Błąd podczas wylogowywania: $e');
    }
  }

  Future<void> createCarListing(CarListing carListing) async {
    final url = Uri.parse('$baseUrl/api/CarListings/create');
    try {
      final response = await _client.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(carListing.toJson()),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.put(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(carListing.toJson()),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => CarListing.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => CarListing.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(
            errorBody['message'] ?? 'Błąd pobierania ogłoszeń: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas pobierania ogłoszeń: $e');
    }
  }

  Future<void> deleteCarListing(int listingId) async {
    final url = Uri.parse('$baseUrl/api/CarListings/$listingId');
    try {
      final response = await _client.delete(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(
            errorBody['message'] ?? 'Błąd usuwania ogłoszenia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas usuwania ogłoszenia: $e');
    }
  }

  Future<void> createCarRental(int carListingId, DateTime startDate, DateTime endDate) async {
    final url = Uri.parse('$baseUrl/api/CarRental/create');
    try {
      final response = await _client.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode({
          'carListingId': carListingId,
          'rentalStartDate': startDate.toIso8601String(),
          'rentalEndDate': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(
            errorBody['message'] ?? 'Błąd tworzenia wypożyczenia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas tworzenia wypożyczenia: $e');
    }
  }

  Future<void> deleteCarRental(int rentalId) async {
    final url = Uri.parse('$baseUrl/api/CarRental/$rentalId');
    try {
      final response = await _client.delete(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(
            errorBody['message'] ?? 'Błąd usuwania wypożyczenia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas usuwania wypożyczenia: $e');
    }
  }

  Future<List<CarRental>> _getActiveUserCarRentals() async {
    final url = Uri.parse('$baseUrl/api/CarRental/user');
    try {
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => CarRental.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => CarRental.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final reviews = data.map((json) => CarRentalReview.fromJson(json)).toList();
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reviews;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.post(
        url,
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode({
          'carRentalId': carRentalId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data.map((json) => NotificationModel.fromJson(json)).toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.patch(
        url,
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.get(
        url,
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Przekroczono czas oczekiwania na odpowiedź serwera.');
      });

      if (response.statusCode == 200) {
        final dynamic data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        return [];
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
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
      final response = await _client.patch(
        url,
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Przekroczono czas oczekiwania na odpowiedź serwera.');
      });

      if (response.statusCode != 200) {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['message'] ??
            'Błąd oznaczania powiadomienia: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd podczas oznaczania powiadomienia jako przeczytanego: $e');
    }
  }
}