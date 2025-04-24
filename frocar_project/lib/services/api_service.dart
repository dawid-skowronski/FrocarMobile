import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';

class ApiService {
  final String baseUrl = 'http://localhost:5001';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  // Zmiana nazwy użytkownika
  Future<void> changeUsername(String newUsername) async {
    final url = '$baseUrl/api/Account/change-username';
    final token = await _getToken();

    if (token == null) {
      throw Exception('Brak tokenu JWT. Użytkownik nie jest zalogowany.');
    }

    print('Wysyłanie żądania PUT do: $url');
    print('Dane do wysłania: ${jsonEncode({'newUsername': newUsername})}');
    print('Token: $token');

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newUsername': newUsername}),
    );

    print('Odpowiedź serwera - status: ${response.statusCode}');
    print('Odpowiedź serwera - treść: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Błąd podczas zmiany nazwy użytkownika: Status ${response.statusCode}, Treść: ${response.body}');
    }

    // Wylogowanie użytkownika po zmianie nazwy
    await logout();
  }

  // Wylogowanie użytkownika
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
      // Usunięcie tokenu i nazwy użytkownika z pamięci
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'username');
    } else {
      throw Exception('Błąd podczas wylogowywania: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }

  // Reszta metod (jeśli już masz ApiService, dodaj powyższe metody do istniejącego kodu)
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

    print('Wysyłanie żądania PUT do: $url');
    print('Dane do wysłania: ${jsonEncode(carListing.toJson())}');
    print('Token: $token');

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(carListing.toJson()),
    );

    print('Odpowiedź serwera - status: ${response.statusCode}');
    print('Odpowiedź serwera - treść: ${response.body}');

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

  Future<List<CarRental>> getUserCarRentals() async {
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
    } else {
      throw Exception('Błąd podczas pobierania wypożyczeń: Status ${response.statusCode}, Treść: ${response.body}');
    }
  }
}