import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/login.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'login_screen_test.mocks.dart';


@GenerateMocks([ApiService, ThemeProvider, NotificationProvider, FlutterSecureStorage])
void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotificationProvider;
  late MockFlutterSecureStorage mockFlutterSecureStorage;

  setUp(() {
    mockApiService = MockApiService();
    mockThemeProvider = MockThemeProvider();
    mockNotificationProvider = MockNotificationProvider();
    mockFlutterSecureStorage = MockFlutterSecureStorage();

    when(mockFlutterSecureStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(mockFlutterSecureStorage.write(key: anyNamed('key'), value: anyNamed('value'))).thenAnswer((_) async {});
    when(mockFlutterSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async => null);

    when(mockNotificationProvider.notificationCount).thenReturn(0);
    when(mockNotificationProvider.resetNotificationCount()).thenAnswer((_) async => null);
    when(mockNotificationProvider.setNotificationCount(any)).thenAnswer((_) {});
    when(mockNotificationProvider.incrementNotificationCount()).thenAnswer((_) {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
        Provider<FlutterSecureStorage>.value(value: mockFlutterSecureStorage),
      ],
      child: MaterialApp(
        home: const LoginScreen(
          skipNavigationOnLogin: true,
          testUsername: 'testuser',
        ),
        routes: {
          '/notifications': (context) => const Scaffold(body: Text('Powiadomienia')),
          '/reset-password': (context) => const Scaffold(body: Text('Resetowanie Hasła')),
        },
      ),
    );
  }

  group('Testy ekranu logowania', () {
    testWidgets('Poprawnie renderuje pola nazwy użytkownika i hasła', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Zaloguj się'), findsOneWidget);
      expect(find.byType(CustomAppBar), findsOneWidget);
    });

    testWidgets('Wyświetla komunikat sukcesu przy poprawnym logowaniu', (WidgetTester tester) async {
      when(mockApiService.login('testuser', 'password123'))
          .thenAnswer((_) async => {'token': 'fake_token'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Zalogowano pomyślnie.'), findsOneWidget);
      verify(mockApiService.login('testuser', 'password123')).called(1);
    });

    testWidgets('Wyświetla komunikat błędu przy nieudanym logowaniu', (WidgetTester tester) async {
      when(mockApiService.login(any, any)).thenThrow(
        Exception('401'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'zlyuser');
      await tester.enterText(find.byType(TextField).at(1), 'zlehaslo');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Nieprawidłowa nazwa użytkownika lub hasło.'), findsOneWidget);
      verify(mockApiService.login('zlyuser', 'zlehaslo')).called(1);
    });

    testWidgets('Przełącza widoczność hasła', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField).at(1);
      final visibilityIcon = find.byIcon(Icons.visibility);

      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      await tester.tap(visibilityIcon);
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });

    testWidgets('Nawiguje do ekranu powiadomień po naciśnięciu przycisku powiadomień', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final notificationButton = find.byIcon(Icons.notifications);

      await tester.tap(notificationButton);
      await tester.pumpAndSettle();

      expect(find.text('Powiadomienia'), findsOneWidget);
      verify(mockNotificationProvider.resetNotificationCount()).called(1);
    });

    testWidgets('Wyświetla komunikat błędu, gdy pola są puste', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.text('Proszę uzupełnić nazwę użytkownika i hasło.'), findsOneWidget);
      verifyNever(mockApiService.login(any, any));
    });

    testWidgets('Wyświetla liczbę powiadomień z NotificationProvider', (WidgetTester tester) async {
      when(mockNotificationProvider.notificationCount).thenReturn(5);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Pokazuje wskaźnik ładowania podczas logowania', (WidgetTester tester) async {
      when(mockApiService.login(any, any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return {'token': 'fake_token'};
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Zalogowano pomyślnie.'), findsOneWidget);
    });

    testWidgets('Wyświetla komunikat błędu, gdy nazwa użytkownika jest pusta', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.text('Proszę uzupełnić nazwę użytkownika i hasło.'), findsOneWidget);
      verifyNever(mockApiService.login(any, any));
    });

    testWidgets('Wyświetla komunikat błędu, gdy hasło jest puste', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.text('Proszę uzupełnić nazwę użytkownika i hasło.'), findsOneWidget);
      verifyNever(mockApiService.login(any, any));
    });

    testWidgets('Przycisk logowania jest aktywny, gdy pola są wypełnione', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Wyświetla komunikat błędu przy zbyt krótkiej nazwie użytkownika (błąd z API)', (WidgetTester tester) async {
      when(mockApiService.login('ab', 'password123')).thenThrow(
        Exception('401'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'ab');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Nieprawidłowa nazwa użytkownika lub hasło.'), findsOneWidget);
      verify(mockApiService.login('ab', 'password123')).called(1);
    });

    testWidgets('Wyświetla komunikat błędu przy zbyt krótkim haśle (błąd z API)', (WidgetTester tester) async {
      when(mockApiService.login('testuser', 'pass')).thenThrow(
        Exception('401'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Nieprawidłowa nazwa użytkownika lub hasło.'), findsOneWidget);
      verify(mockApiService.login('testuser', 'pass')).called(1);
    });

    testWidgets('Nawiguje do ekranu resetowania hasła', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Zapomniałeś hasła?'), findsOneWidget);
      await tester.tap(find.text('Zapomniałeś hasła?'));
      await tester.pumpAndSettle();

      expect(find.text('Resetowanie Hasła'), findsOneWidget);
    });
  });
}