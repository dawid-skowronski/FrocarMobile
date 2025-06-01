import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/rent_form_page.dart';
import 'package:test_project/rent_car_page.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'rent_form_page_test.mocks.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

@GenerateMocks([ApiService, FlutterSecureStorage])
void main() {
  late MockApiService apiService;
  late MockFlutterSecureStorage secureStorage;

  final sampleListing = CarListing(
    id: 1,
    userId: 2,
    brand: 'Toyota',
    engineCapacity: 1.8,
    fuelType: 'Benzyna',
    seats: 5,
    carType: 'Sedan',
    features: ['Air Conditioning', 'Bluetooth'],
    latitude: 52.23,
    longitude: 21.01,
    isAvailable: true,
    rentalPricePerDay: 100.0,
    isApproved: true,
    averageRating: 4.5,
  );

  final validJwtToken = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}')) +
      '.' +
      base64Url.encode(utf8.encode(
          '{"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier":"1"}')) +
      '.' +
      base64Url.encode(utf8.encode('signature'));

  setUp(() {
    apiService = MockApiService();
    secureStorage = MockFlutterSecureStorage();

    when(secureStorage.read(key: 'token')).thenAnswer((_) async => validJwtToken);
    when(secureStorage.read(key: 'username')).thenAnswer((_) async => 'test_user');
    when(apiService.getCarListings()).thenAnswer((_) async => [sampleListing]);
    when(apiService.getUserCarRentals()).thenAnswer((_) async => []);
  });

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.physicalSizeTestValue = const Size(800, 1200);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDownAll(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        Provider<FlutterSecureStorage>(create: (_) => secureStorage),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        home: ScaffoldMessenger(
          child: RentFormPage(listing: sampleListing),
        ),
        routes: {
          '/notifications': (context) => const Scaffold(body: Text('Notifications')),
          '/rent_car': (context) => ScaffoldMessenger(
            child: RentCarPage(),
          ),
        },
      ),
    );
  }

  testWidgets('Wyświetlanie elementów UI formularza', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(CustomAppBar), findsOneWidget);
    expect(find.text('Wypożycz Toyota'), findsOneWidget);
    expect(find.text('Data rozpoczęcia'), findsOneWidget);
    expect(find.text('Data zakończenia'), findsOneWidget);
    expect(find.text('Wybierz daty, aby zobaczyć kwotę'), findsOneWidget);
    expect(find.text('Wypożycz'), findsOneWidget);
  });

  testWidgets('Wybór daty rozpoczęcia', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextFormField, 'Data rozpoczęcia'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, DateTime.now().toString().substring(0, 10)), findsOneWidget);
  });

  testWidgets('Wybór daty zakończenia', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextFormField, 'Data rozpoczęcia'));
    await tester.pumpAndSettle();

    final todayDay = DateTime.now().day.toString();
    await tester.tap(find.text(todayDay).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextFormField, 'Data zakończenia'));
    await tester.pumpAndSettle();

    final tomorrowDay = DateTime.now().add(const Duration(days: 1)).day.toString();
    await tester.tap(find.text(tomorrowDay).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final startDateText = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final endDateText = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

    expect(find.widgetWithText(TextFormField, startDateText), findsOneWidget);
    expect(find.widgetWithText(TextFormField, endDateText), findsOneWidget);
  });

  testWidgets('Obliczanie całkowitej kwoty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextFormField, 'Data rozpoczęcia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.widgetWithText(TextFormField, 'Data zakończenia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tomorrow.day.toString()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Całkowita kwota: 100.00 PLN'), findsOneWidget);
  });

  testWidgets('Walidacja formularza bez wybranych dat', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wypożycz'));
    await tester.pumpAndSettle();

    expect(find.text('Wybierz datę rozpoczęcia'), findsOneWidget);
    expect(find.text('Wybierz datę zakończenia'), findsOneWidget);
  });

  testWidgets('Pomyślne wypożyczenie samochodu', (WidgetTester tester) async {
    when(apiService.createCarRental(any, any, any)).thenAnswer((_) async {});

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        Provider<FlutterSecureStorage>(create: (_) => secureStorage),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        home: ScaffoldMessenger(
          child: RentCarPage(),
        ),
        routes: {
          '/rent_form': (context) => ScaffoldMessenger(
            child: RentFormPage(listing: sampleListing),
          ),
          '/notifications': (context) => const Scaffold(body: Text('Notifications')),
        },
      ),
    ));
    await tester.pumpAndSettle();

    Navigator.pushNamed(tester.element(find.byType(RentCarPage)), '/rent_form');
    await tester.pumpAndSettle();

    final today = DateTime.now();
    await tester.tap(find.widgetWithText(TextFormField, 'Data rozpoczęcia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(today.day.toString()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.widgetWithText(TextFormField, 'Data zakończenia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tomorrow.day.toString()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wypożycz'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(RentFormPage), findsNothing);
    expect(find.byType(RentCarPage), findsOneWidget);
  });

  testWidgets('Błąd podczas wypożyczania samochodu', (WidgetTester tester) async {
    when(apiService.createCarRental(any, any, any)).thenThrow(Exception('API Error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final today = DateTime.now();
    await tester.tap(find.widgetWithText(TextFormField, 'Data rozpoczęcia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(today.day.toString()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.widgetWithText(TextFormField, 'Data zakończenia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tomorrow.day.toString()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wypożycz'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Błąd: Exception: API Error'), findsOneWidget);
  });

  testWidgets('Nawigacja do strony powiadomień', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });
}