import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:test_project/login.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'login_screen_test.mocks.dart';

@GenerateMocks([ApiService, ThemeProvider, NotificationProvider])
void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotificationProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockThemeProvider = MockThemeProvider();
    mockNotificationProvider = MockNotificationProvider();

    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async => null);

    when(mockNotificationProvider.notificationCount).thenReturn(0);
    when(mockNotificationProvider.resetNotificationCount()).thenAnswer((_) async => null);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
      ],
      child: MaterialApp(
        home: const LoginScreen(
          skipNavigationOnLogin: true,
          testUsername: 'testuser',
        ),
        routes: {
          '/notifications': (context) => const Scaffold(body: Text('Powiadomienia')),
        },
      ),
    );
  }

  group('Testy ekranu logowania', () {
    testWidgets('Poprawnie renderuje pola nazwy użytkownika i hasła', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Zaloguj się'), findsOneWidget);
      expect(find.byType(CustomAppBar), findsOneWidget);
    });

    testWidgets('Wyświetla komunikat sukcesu przy poprawnym logowaniu', (WidgetTester tester) async {
      when(mockApiService.login(any, any))
          .thenAnswer((_) async => {'token': 'fake_token'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Zalogowano pomyślnie.'), findsOneWidget);
    });

    testWidgets('Wyświetla komunikat błędu przy nieudanym logowaniu', (WidgetTester tester) async {
      when(mockApiService.login(any, any)).thenAnswer(
            (_) => Future.error(Exception('Błędne dane logowania')),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'zlyuser');
      await tester.enterText(find.byType(TextField).at(1), 'zlehaslo');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Wystąpił błąd podczas logowania. Spróbuj ponownie później.'), findsOneWidget);
    });

    testWidgets('Przełącza widoczność hasła', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final passwordField = find.byType(TextField).at(1);
      final visibilityIcon = find.byIcon(Icons.visibility);

      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      await tester.tap(visibilityIcon);
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });

    testWidgets('Nawiguje do ekranu powiadomień po naciśnięciu przycisku powiadomień', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final notificationButton = find.byIcon(Icons.notifications);

      await tester.tap(notificationButton);
      await tester.pumpAndSettle();

      expect(find.text('Powiadomienia'), findsOneWidget);
      verify(mockNotificationProvider.resetNotificationCount()).called(1);
    });

    testWidgets('Wyświetla komunikat błędu, gdy pola są puste', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.text('Proszę uzupełnić nazwę użytkownika i hasło.'), findsOneWidget);
      verifyNever(mockApiService.login(any, any));
    });

    testWidgets('Wyświetla liczbę powiadomień z NotificationProvider', (WidgetTester tester) async {
      when(mockNotificationProvider.notificationCount).thenReturn(5);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Pokazuje wskaźnik ładowania podczas logowania', (WidgetTester tester) async {
      when(mockApiService.login(any, any)).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return {'token': 'fake_token'};
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Wyświetla komunikat błędu, gdy nazwa użytkownika jest pusta', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.text('Proszę uzupełnić nazwę użytkownika i hasło.'), findsOneWidget);
      verifyNever(mockApiService.login(any, any));
    });

    testWidgets('Wyświetla komunikat błędu, gdy hasło jest puste', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pump();

      expect(find.text('Proszę uzupełnić nazwę użytkownika i hasło.'), findsOneWidget);
      verifyNever(mockApiService.login(any, any));
    });

    testWidgets('Przycisk logowania jest aktywny, gdy pola są wypełnione', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed != null, isTrue);
    });

    testWidgets('Wyświetla komunikat błędu przy zbyt krótkiej nazwie użytkownika', (WidgetTester tester) async {
      when(mockApiService.login('ab', any)).thenAnswer(
            (_) => Future.error(Exception('Błędne dane logowania')),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'ab');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Wystąpił błąd podczas logowania. Spróbuj ponownie później.'), findsOneWidget);
      verify(mockApiService.login('ab', 'password123')).called(1);
    });

    testWidgets('Wyświetla komunikat błędu przy zbyt krótkim haśle', (WidgetTester tester) async {
      when(mockApiService.login(any, 'pass')).thenAnswer(
            (_) => Future.error(Exception('Błędne dane logowania')),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'testuser');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(find.text('Wystąpił błąd podczas logowania. Spróbuj ponownie później.'), findsOneWidget);
      verify(mockApiService.login('testuser', 'pass')).called(1);
    });
  });
}
