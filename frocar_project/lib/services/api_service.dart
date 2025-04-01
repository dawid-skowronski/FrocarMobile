import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart'; // Dodajemy import dla CarRental

class ApiService {
  final String baseUrl = 'http://localhost:5001';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Pobieranie tokenu z SharedPreferences
  }

  // Dodawanie nowego ogłoszenia
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
      throw Exception('Błąd podczas dodawania ogłoszenia: ${response.body}');
    }
  }

  // Pobieranie ogłoszeń zalogowanego użytkownika
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
      throw Exception('Błąd podczas pobierania ogłoszeń: ${response.statusCode} - ${response.body}');
    }
  }

  // Pobieranie wszystkich dostępnych ogłoszeń
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
      throw Exception('Błąd podczas pobierania ogłoszeń: ${response.statusCode} - ${response.body}');
    }
  }

  // Tworzenie wypożyczenia
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
      throw Exception('Błąd podczas tworzenia wypożyczenia: ${response.body}');
    }
  }

  // Pobieranie wypożyczeń użytkownika
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
      throw Exception('Błąd podczas pobierania wypożyczeń: ${response.body}');
    }
  }
}