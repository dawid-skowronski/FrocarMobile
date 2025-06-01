import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/register.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'register_test.mocks.dart';

@GenerateMocks([ApiService, ThemeProvider, NotificationProvider, FlutterSecureStorage])
void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotificationProvider;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockApiService = MockApiService();
    mockThemeProvider = MockThemeProvider();
    mockNotificationProvider = MockNotificationProvider();
    mockSecureStorage = MockFlutterSecureStorage();

    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async => null);

    when(mockNotificationProvider.notificationCount).thenReturn(0);
    when(mockNotificationProvider.resetNotificationCount()).thenAnswer((_) async => null);

    when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async => 'mock_token');
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'test_user');
    when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
      ],
      child: MaterialApp(
        routes: {
          '/login': (context) => const Scaffold(body: Text('Ekran logowania')),
          '/notifications': (context) => const Scaffold(body: Text('Powiadomienia')),
        },
        home: const RegisterScreen(),
      ),
    );
  }

  group('Testy ekranu rejestracji', () {
    testWidgets('Poprawnie renderuje pola formularza i przycisk rejestracji', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Rejestracja'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('Nazwa użytkownika'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Hasło'), findsOneWidget);
      expect(find.text('Potwierdź hasło'), findsOneWidget);
      expect(find.text('Zarejestruj się'), findsOneWidget);
    });

    testWidgets('Wyświetla komunikat błędu, gdy hasła się nie zgadzają', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password456');
      await tester.tap(find.text('Zarejestruj się'));
      await tester.pumpAndSettle();

      expect(find.text('Hasła się nie zgadzają'), findsOneWidget);
      verifyNever(mockApiService.register(any, any, any, any));
    });

    testWidgets('Wyświetla wskaźnik ładowania podczas rejestracji', (tester) async {
      when(mockApiService.register(any, any, any, any)).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return {'message': 'Rejestracja zakończona sukcesem'};
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.tap(find.text('Zarejestruj się'));
      await tester.pump(); // Start ładowania

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Wyświetla komunikat sukcesu i nawiguję do ekranu logowania przy udanej rejestracji', (tester) async {
      when(mockApiService.register(any, any, any, any)).thenAnswer((_) async => {'message': 'Rejestracja zakończona sukcesem'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.tap(find.text('Zarejestruj się'));
      await tester.pumpAndSettle();

      expect(find.text('Ekran logowania'), findsOneWidget);
      verify(mockApiService.register('testuser', 'test@example.com', 'password123', 'password123')).called(1);
    });

    testWidgets('Wyświetla komunikat błędu przy nieudanej rejestracji', (tester) async {
      when(mockApiService.register(any, any, any, any)).thenThrow(Exception('Username already exists'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.tap(find.text('Zarejestruj się'));

      await tester.pumpAndSettle();

      expect(find.text('Ta nazwa użytkownika jest już zajęta.'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('Ta nazwa użytkownika jest już zajęta.'));
      expect(textWidget.style?.color, Colors.red);

      verify(mockApiService.register('testuser', 'test@example.com', 'password123', 'password123')).called(1);
    });

    testWidgets('Przełącza widoczność hasła', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      final editableTextFinder = find.descendant(of: passwordField, matching: find.byType(EditableText));

      var editableTextWidget = tester.widget<EditableText>(editableTextFinder);
      expect(editableTextWidget.obscureText, isTrue);

      final visibilityIcon = find.descendant(of: passwordField, matching: find.byIcon(Icons.visibility)).first;
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      editableTextWidget = tester.widget<EditableText>(editableTextFinder);
      expect(editableTextWidget.obscureText, isFalse);
    });

    testWidgets('Przełącza widoczność potwierdzenia hasła', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final confirmPasswordField = find.byType(TextFormField).at(3);
      final editableTextFinder = find.descendant(of: confirmPasswordField, matching: find.byType(EditableText));

      var editableTextWidget = tester.widget<EditableText>(editableTextFinder);
      expect(editableTextWidget.obscureText, isTrue);

      final visibilityIcon = find.descendant(of: confirmPasswordField, matching: find.byIcon(Icons.visibility)).first;
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      editableTextWidget = tester.widget<EditableText>(editableTextFinder);
      expect(editableTextWidget.obscureText, isFalse);
    });

    testWidgets('Wyświetla komunikat błędu w kolorze czerwonym przy błędzie', (tester) async {
      when(mockApiService.register(any, any, any, any)).thenThrow(Exception('Użytkownik już istnieje'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.tap(find.text('Zarejestruj się'));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Użytkownik już istnieje'));
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('Wyświetla komunikat sukcesu w kolorze zielonym', (tester) async {
      when(mockApiService.register(any, any, any, any)).thenAnswer((_) async => {'message': 'Rejestracja zakończona sukcesem'});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.tap(find.text('Zarejestruj się'));
      await tester.pump();

      final successTextFinder = find.text('Zarejestrowano pomyślnie');
      expect(successTextFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(successTextFinder);
      expect(textWidget.style?.color, Colors.green);

      await tester.pumpAndSettle();
    });
  });
}
