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

  Widget createWidgetUnderTest({required Widget child}) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        Provider<FlutterSecureStorage>(create: (_) => secureStorage),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        home: ScaffoldMessenger(child: child),
        routes: {
          '/notifications': (context) => const Scaffold(body: Text('Notifications')),
          '/rent_car': (context) => ScaffoldMessenger(child: RentCarPage()),
        },
      ),
    );
  }

  Future<void> selectDate(
      WidgetTester tester, String label, DateTime date,
      ) async {
    await tester.tap(find.widgetWithText(TextFormField, label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${date.day}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('Wypelnianie i wysylanie formularza dziala poprawnie', (tester) async {
    when(apiService.createCarRental(any, any, any)).thenAnswer((_) async => null);

    await tester.pumpWidget(createWidgetUnderTest(child: RentFormPage(listing: sampleListing)));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    await selectDate(tester, 'Data rozpoczęcia', today);
    await selectDate(tester, 'Data zakończenia', tomorrow);

    await tester.tap(find.text('Wypożycz'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    verify(apiService.createCarRental(sampleListing.id, any, any)).called(1);
  });

  testWidgets('Pokazuje błąd gdy createCarRental rzuci wyjątek', (tester) async {
    when(apiService.createCarRental(any, any, any)).thenThrow(Exception('API Error'));

    await tester.pumpWidget(createWidgetUnderTest(child: RentFormPage(listing: sampleListing)));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    await selectDate(tester, 'Data rozpoczęcia', today);
    await selectDate(tester, 'Data zakończenia', tomorrow);

    await tester.tap(find.text('Wypożycz'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('Błąd'), findsOneWidget);
  });

  testWidgets('Nawigacja do powiadomień działa', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(child: RentFormPage(listing: sampleListing)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });
}
