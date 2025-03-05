import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_point.dart';

class ApiService {
  final String baseUrl = 'http://localhost:5001'; 

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<MapPoint>> getPoints() async {
    final url = '$baseUrl/api/MapPoints';
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
      return data.map((json) => MapPoint.fromJson(json)).toList();
    } else {
      throw Exception('Błąd podczas pobierania punktów: ${response.statusCode} - ${response.body}');
    }
  }
}