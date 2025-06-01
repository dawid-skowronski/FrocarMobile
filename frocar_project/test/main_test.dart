import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/main.dart';
import 'package:test_project/login.dart';
import 'package:test_project/register.dart';
import 'package:test_project/notifications_page.dart';
import 'package:test_project/profile_page.dart';
import 'package:test_project/rent_car_page.dart';
import 'package:test_project/offer_car_page.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/widgets/loading_screen.dart';
import 'main_test.mocks.dart';

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

    when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async {});

    when(mockNotificationProvider.notificationCount).thenReturn(0);
    when(mockNotificationProvider.resetNotificationCount()).thenAnswer((_) async {});
    when(mockNotificationProvider.setNotificationCount(any)).thenAnswer((_) async {});

    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => null);
    when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async => null);

    when(mockApiService.fetchAccountNotifications()).thenAnswer((_) async => []);
    when(mockApiService.getCarListings()).thenAnswer((_) async => []);
    when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest({bool isLoggedIn = false}) {
    if (isLoggedIn) {
      when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'testuser');
      when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYW1zL25hbWVpZGVudGlmaWVyIjoiMSJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c');
      when(mockApiService.fetchAccountNotifications()).thenAnswer((_) async => []);
    } else {
      when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => null);
      when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async => null);
    }

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
        Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/notifications': (context) => const NotificationsPage(),
          '/profile': (context) => const ProfilePage(),
          '/splash': (context) => const LoadingScreen(nextRoute: '/'),
          '/loading': (context) => LoadingScreen(
            nextRoute: ModalRoute.of(context)?.settings.arguments as String?,
          ),
          '/rentCar': (context) => const RentCarPage(),
          '/offerCar': (context) => OfferCarPage(),
        },
      ),
    );
  }

  group('Testy głównej aplikacji', () {
    testWidgets('Poprawnie renderuje ekran powitalny', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoggedIn: false));
      await tester.pump(Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Witamy w FroCar'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('Nawigacja do ekranu logowania', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoggedIn: false));
      await tester.pump(Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final loginButton = find.widgetWithText(ElevatedButton, 'Zaloguj');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Nawigacja do ekranu rejestracji', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoggedIn: false));
      await tester.pump(Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final registerButton = find.widgetWithText(ElevatedButton, 'Zarejestruj');
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('Wyświetla ekran powitalny z nazwą użytkownika gdy zalogowany', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoggedIn: true));
      await tester.pump(Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList(find.byType(Text)).map((w) => (w as Text).data).toList();
      final iconWidgets = tester.widgetList(find.byType(Icon)).map((w) => w.toString()).toList();
      print('Znalezione teksty: $textWidgets');
      print('Znalezione ikony: $iconWidgets');

      expect(find.text('Cześć testuser!'), findsOneWidget);
      expect(find.byKey(Key('notification_button')), findsOneWidget, reason: 'Ikona powiadomień powinna być widoczna');
    });

    testWidgets('Nawigacja do ekranu powiadomień dla zalogowanego użytkownika', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoggedIn: true));
      await tester.pump(Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final notificationButton = find.byKey(Key('notification_button'));
      expect(notificationButton, findsOneWidget, reason: 'Przycisk powiadomień powinien być widoczny');
      await tester.tap(notificationButton);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('Nawigacja do ekranu profilu dla zalogowanego użytkownika', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isLoggedIn: true));
      await tester.pump(Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
    });
  });
}