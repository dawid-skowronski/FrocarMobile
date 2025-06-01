import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:test_project/providers/theme_provider.dart';

import 'theme_provider_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<FlutterSecureStorage>(as: #MockThemeFlutterSecureStorage),
])
void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider provider;
    late MockThemeFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockThemeFlutterSecureStorage();
      provider = ThemeProvider(storage: mockStorage);
    });

    test('Początkowy motyw to jasny, jeśli nie ma zapisanego motywu', () async {
      when(mockStorage.read(key: 'isDarkMode')).thenAnswer((_) async => null);

      await provider.loadTheme();

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, false);
      verify(mockStorage.read(key: 'isDarkMode')).called(1);
    });

    test('Początkowy motyw to ciemny, jeśli zapisano isDarkMode jako true', () async {
      when(mockStorage.read(key: 'isDarkMode')).thenAnswer((_) async => 'true');

      await provider.loadTheme();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, true);
      verify(mockStorage.read(key: 'isDarkMode')).called(1);
    });

    test('toggleTheme przełącza z jasnego na ciemny i zapisuje zmianę', () async {
      when(mockStorage.read(key: 'isDarkMode')).thenAnswer((_) async => null);
      when(mockStorage.write(key: 'isDarkMode', value: 'true')).thenAnswer((_) async => {});

      await provider.loadTheme();
      expect(provider.themeMode, ThemeMode.light);

      var notifyCalled = false;
      provider.addListener(() {
        notifyCalled = true;
      });

      await provider.toggleTheme();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, true);
      expect(notifyCalled, true);
      verify(mockStorage.write(key: 'isDarkMode', value: 'true')).called(1);
    });

    test('toggleTheme przełącza z ciemnego na jasny i zapisuje zmianę', () async {
      when(mockStorage.read(key: 'isDarkMode')).thenAnswer((_) async => 'true');
      when(mockStorage.write(key: 'isDarkMode', value: 'false')).thenAnswer((_) async => {});

      await provider.loadTheme();
      expect(provider.themeMode, ThemeMode.dark);

      var notifyCalled = false;
      provider.addListener(() {
        notifyCalled = true;
      });

      await provider.toggleTheme();

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, false);
      expect(notifyCalled, true);
      verify(mockStorage.write(key: 'isDarkMode', value: 'false')).called(1);
    });
  });
}