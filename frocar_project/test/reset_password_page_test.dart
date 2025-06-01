import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Dodany import FlutterSecureStorage

import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/reset_password_page.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';

// Import wygenerowanych mocków.
import 'reset_password_page_test.mocks.dart';

// Dodajemy FlutterSecureStorage do listy do mockowania
@GenerateMocks([ApiService, ThemeProvider, NotificationProvider, FlutterSecureStorage])
void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotificationProvider;
  late MockFlutterSecureStorage mockFlutterSecureStorage; // Deklaracja mocka

  setUp(() {
    mockApiService = MockApiService();
    mockThemeProvider = MockThemeProvider();
    mockNotificationProvider = MockNotificationProvider();
    mockFlutterSecureStorage = MockFlutterSecureStorage(); // Inicjalizacja mocka

    // Ustawienie domyślnych zachowań dla FlutterSecureStorage
    // Zakładamy, że ApiService i ThemeProvider próbują odczytać token lub tryb ciemny
    when(mockFlutterSecureStorage.read(key: 'token')).thenAnswer((_) async => null);
    when(mockFlutterSecureStorage.read(key: 'username')).thenAnswer((_) async => 'TestUser'); // Dodane dla _CustomAppBarState._getUsername
    when(mockFlutterSecureStorage.read(key: 'isDarkMode')).thenAnswer((_) async => 'false');
    when(mockFlutterSecureStorage.write(key: anyNamed('key'), value: anyNamed('value'))).thenAnswer((_) async {});
    when(mockFlutterSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});


    // Ustawienie domyślnych zachowań dla ThemeProvider
    // Tutaj konstruktor ThemeProvider przyjmuje FlutterSecureStorage, więc musimy go przekazać
    // Ale w testach chcemy, aby ThemeProvider używał MOCKA FlutterSecureStorage,
    // więc musimy go sparametryzować, jeśli to możliwe, lub dostarczyć gotowy mock ThemeProvider.
    // Skoro mockThemeProvider jest tworzony, to jego konstruktor nie będzie wołany,
    // ale mockThemeProvider.isDarkMode i toggleTheme muszą być ustawione.
    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async {});


    // Ustawienie domyślnych zachowań dla NotificationProvider
    when(mockNotificationProvider.notificationCount).thenReturn(0);
    when(mockNotificationProvider.resetNotificationCount()).thenAnswer((_) async {});
    when(mockNotificationProvider.setNotificationCount(any)).thenAnswer((_) {});
    when(mockNotificationProvider.incrementNotificationCount()).thenAnswer((_) {});

    // Upewnij się, że ApiService również używa mocka FlutterSecureStorage, jeśli jest to potrzebne w jego testowanej logice
    // Np. mockApiService = MockApiService(storage: mockFlutterSecureStorage);
    // Jeśli ApiService jest tworzony w MultiProviderze, jego konstruktor z storage nie będzie użyty,
    // ale jeśli CustomAppBar wywołuje API, to ApiService wewnątrz CustomAppBar będzie potrzebował storage.
    // Lepszym podejściem jest użycie MockApiService i stubowanie jego metod.
    // Z Twojego ApiService wynika, że konstruktor przyjmuje storage, więc jeśli testujesz
    // komponenty, które tworzą ApiService, musiałbyś to kontrolować.
    // W obecnej konfiguracji, ApiService jest dostarczany jako value(mockApiService), więc to mockApiService jest w użyciu.
    // Musimy więc zapewnić, że mockApiService działa tak, jakby miał storage.
    // Jeśli ApiService w środku CustomAppBar używa 'Provider.of<ApiService>(context)',
    // a ten ApiService w środku ma FlutterSecureStorage, to nie ma problemu, bo ApiService jako całość jest mockowany.
    // Problem jest, gdy CustomAppBar ma bezpośrednią zależność od FlutterSecureStorage, jak sugeruje błąd.
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        // Dostarczamy mock FlutterSecureStorage bezpośrednio
        // To jest kluczowe, bo CustomAppBar najwyraźniej próbuje go bezpośrednio odczytać
        Provider<FlutterSecureStorage>.value(value: mockFlutterSecureStorage),
        Provider<ApiService>.value(value: mockApiService),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
      ],
      child: MaterialApp(
        routes: {
          '/notifications': (context) => const Scaffold(body: Text('Ekran Powiadomień')),
        },
        home: const ResetPasswordPage(),
      ),
    );
  }

  group('Testy strony resetowania hasła', () {
    testWidgets('Poprawnie renderuje pola formularza i przycisk', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Poczekaj na zakończenie wszystkich asynchronicznych operacji

      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Resetowanie hasła'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Adres e-mail'), findsOneWidget);
      expect(find.text('Wyślij link resetujący'), findsOneWidget);

      // Sprawdź, czy CustomAppBar próbował odczytać username ze storage
      verify(mockFlutterSecureStorage.read(key: 'username')).called(greaterThanOrEqualTo(1));
    });

    // ... pozostałe testy bez zmian ...
    testWidgets('Wyświetla komunikat błędu dla pustego e-maila', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wyślij link resetujący'));
      await tester.pumpAndSettle();

      expect(find.text('Proszę wpisać adres e-mail.'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Proszę wpisać adres e-mail.'));
      expect(textWidget.style?.color, Colors.red);
      verifyNever(mockApiService.requestPasswordReset(any));
    });

    testWidgets('Wyświetla komunikat błędu dla niepoprawnego formatu e-maila', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'niepoprawny-email');
      await tester.tap(find.text('Wyślij link resetujący'));
      await tester.pumpAndSettle();

      expect(find.text('Proszę wpisać poprawny adres e-mail.'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Proszę wpisać poprawny adres e-mail.'));
      expect(textWidget.style?.color, Colors.red);
      verifyNever(mockApiService.requestPasswordReset(any));
    });

    testWidgets('Wyświetla wskaźnik ładowania podczas wysyłania żądania', (tester) async {
      when(mockApiService.requestPasswordReset(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.tap(find.text('Wyślij link resetujący'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Wyślij link resetujący'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Wyświetla komunikat sukcesu po udanym wysłaniu', (tester) async {
      when(mockApiService.requestPasswordReset(any)).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'success@example.com');
      await tester.tap(find.text('Wyślij link resetujący'));
      await tester.pumpAndSettle();

      expect(find.text('Link do resetowania hasła został wysłany na podany adres e-mail.'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Link do resetowania hasła został wysłany na podany adres e-mail.'));
      expect(textWidget.style?.color, Colors.green);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
      verify(mockApiService.requestPasswordReset('success@example.com')).called(1);
    });

    testWidgets('Wyświetla komunikat błędu dla "Nie znaleziono użytkownika"', (tester) async {
      when(mockApiService.requestPasswordReset(any)).thenThrow(Exception('Nie znaleziono użytkownika o podanym adresie e-mail.'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'notfound@example.com');
      await tester.tap(find.text('Wyślij link resetujący'));
      await tester.pumpAndSettle();

      expect(find.text('Nie znaleziono użytkownika z podanym adresem e-mail.'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Nie znaleziono użytkownika z podanym adresem e-mail.'));
      expect(textWidget.style?.color, Colors.red);
      verify(mockApiService.requestPasswordReset('notfound@example.com')).called(1);
    });

    testWidgets('Wyświetla komunikat błędu dla "Połączenie z serwerem nie powiodło się"', (tester) async {
      when(mockApiService.requestPasswordReset(any)).thenThrow(Exception('SocketException: Failed host lookup'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'networkerror@example.com');
      await tester.tap(find.text('Wyślij link resetujący'));
      await tester.pumpAndSettle();

      expect(find.text('Połączenie z serwerem nie powiodło się. Sprawdź swoje połączenie internetowe i spróbuj ponownie.'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Połączenie z serwerem nie powiodło się. Sprawdź swoje połączenie internetowe i spróbuj ponownie.'));
      expect(textWidget.style?.color, Colors.red);
      verify(mockApiService.requestPasswordReset('networkerror@example.com')).called(1);
    });

    testWidgets('Wyświetla ogólny komunikat błędu dla nieznanych błędów', (tester) async {
      when(mockApiService.requestPasswordReset(any)).thenThrow(Exception('Some unexpected server error'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'genericerror@example.com');
      await tester.tap(find.text('Wyślij link resetujący'));
      await tester.pumpAndSettle();

      expect(find.text('Wystąpił błąd podczas wysyłania żądania. Spróbuj ponownie później. Szczegóły: Some unexpected server error'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Wystąpił błąd podczas wysyłania żądania. Spróbuj ponownie później. Szczegóły: Some unexpected server error'));
      expect(textWidget.style?.color, Colors.red);
      verify(mockApiService.requestPasswordReset('genericerror@example.com')).called(1);
    });

    testWidgets('Nawigacja do ekranu powiadomień po kliknięciu ikony', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      expect(find.text('Ekran Powiadomień'), findsOneWidget);
    });
  });
}