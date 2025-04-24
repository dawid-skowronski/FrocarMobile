import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  late ThemeMode _themeMode;
  final _storage = const FlutterSecureStorage();

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final isDarkString = await _storage.read(key: 'isDarkMode');
    final isDark = isDarkString == 'true'; // Domyślnie false, jeśli null
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    await _storage.write(key: 'isDarkMode', value: isDarkMode.toString());
  }
}