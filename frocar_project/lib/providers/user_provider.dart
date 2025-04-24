import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class UserProvider with ChangeNotifier {
  int? _userId;
  final _storage = const FlutterSecureStorage();

  int? get userId => _userId;

  UserProvider() {
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    // Odczyt tokenu z FlutterSecureStorage
    final token = await _storage.read(key: 'token');
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
    // Usunięcie tokenu z FlutterSecureStorage
    await _storage.delete(key: 'token');
    _userId = null;
    notifyListeners();
  }
}