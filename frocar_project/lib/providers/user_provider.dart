import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserProvider with ChangeNotifier {
  int? _userId;

  int? get userId => _userId;

  UserProvider() {
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final decodedToken = JwtDecoder.decode(token);
        _userId = int.parse(decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? '0');
        notifyListeners();
      } catch (e) {
        print('Błąd dekodowania tokenu: $e');
      }
    }
  }

  void setUserId(int? id) {
    _userId = id;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _userId = null;
    notifyListeners();
  }
}