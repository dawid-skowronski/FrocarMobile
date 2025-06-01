import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

abstract class JwtDecoderInterface {
  Map<String, dynamic> decode(String token);
}

class JwtDecoderWrapper implements JwtDecoderInterface {
  @override
  Map<String, dynamic> decode(String token) => JwtDecoder.decode(token);
}

class UserProvider with ChangeNotifier {
  int? _userId;
  final FlutterSecureStorage _storage;
  final JwtDecoderInterface _jwtDecoder;

  int? get userId => _userId;

  UserProvider({
    FlutterSecureStorage? storage,
    JwtDecoderInterface? jwtDecoder,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _jwtDecoder = jwtDecoder ?? JwtDecoderWrapper() {
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      try {
        final decodedToken = _jwtDecoder.decode(token);
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
    await _storage.delete(key: 'token');
    _userId = null;
    notifyListeners();
  }
}