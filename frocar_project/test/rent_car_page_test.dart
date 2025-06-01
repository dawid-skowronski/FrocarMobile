import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/rent_car_page.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'rent_car_page_test.mocks.dart';
import 'dart:convert';
import 'dart:ui';

@GenerateMocks([ApiService, FlutterSecureStorage])
void main() {
  late MockApiService mockApiService;
  late MockFlutterSecureStorage mockStorage;

  final sampleListings = [
    CarListing(
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
    ),
    CarListing(
      id: 2,
      userId: 3,
      brand: 'Honda',
      engineCapacity: 1.5,
      fuelType: 'Hybryda',
      seats: 5,
      carType: 'Hatchback',
      features: ['Navigation', 'Camera'],
      latitude: 52.24,
      longitude: 21.02,
      isAvailable: true,
      rentalPricePerDay: 120.0,
      isApproved: true,
      averageRating: 4.7,
    ),
  ];

  final sampleRentals = [
    CarRental(
      carRentalId: 1,
      carListingId: 1,
      userId: 1,
      carListing: sampleListings[0],
      rentalStartDate: DateTime.now(),
      rentalEndDate: DateTime.now().add(const Duration(days: 7)),
      rentalPrice: 700.0,
      rentalStatus: 'Aktywne',
    ),
  ];

  final validJwtToken = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}')) +
      '.' +
      base64Url.encode(utf8.encode(
          '{"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier":"1"}')) +
      '.' +
      base64Url.encode(utf8.encode('signature'));

  setUp(() {
    mockApiService = MockApiService();
    mockStorage = MockFlutterSecureStorage();

    when(mockStorage.read(key: 'token')).thenAnswer((_) async => validJwtToken);
    when(mockStorage.read(key: 'username')).thenAnswer((_) async => 'test_user');

    when(mockApiService.getReviewsForListing(any)).thenAnswer((_) async => []);
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
        Provider<ApiService>(create: (_) => mockApiService),
        Provider<FlutterSecureStorage>(create: (_) => mockStorage),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<NotificationProvider>(
            create: (_) => NotificationProvider()),
      ],
      child: const MaterialApp(
        home: RentCarPage(),
      ),
    );
  }

  testWidgets('Ładowanie danych przy inicjalizacji', (WidgetTester tester) async {
    when(mockApiService.getCarListings()).thenAnswer((_) async => sampleListings);
    when(mockApiService.getUserCarRentals()).thenAnswer((_) async => sampleRentals);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    verify(mockStorage.read(key: 'token')).called(1);
    verify(mockApiService.getCarListings()).called(1);
    verify(mockApiService.getUserCarRentals()).called(1);
    expect(find.byType(GoogleMap), findsOneWidget);
    final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(googleMap.markers.length, 2);
  });

  testWidgets('Wyświetlanie markerów na mapie', (WidgetTester tester) async {
    when(mockApiService.getCarListings()).thenAnswer((_) async => sampleListings);
    when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(googleMap.markers.length, 2);
    expect(
        googleMap.markers.any((marker) => marker.markerId == const MarkerId('1')),
        isTrue);
    expect(
        googleMap.markers.any((marker) => marker.markerId == const MarkerId('2')),
        isTrue);
  });

  testWidgets('Wyświetlanie dialogu błędu przy braku aut',
          (WidgetTester tester) async {
        when(mockApiService.getCarListings()).thenAnswer((_) async => []);
        when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Brak dostępnych aut spełniających kryteria'), findsOneWidget);
      });

  testWidgets('Otwieranie bottom sheet z filtrami', (WidgetTester tester) async {
    when(mockApiService.getCarListings()).thenAnswer((_) async => sampleListings);
    when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Filtry wyszukiwania'), findsOneWidget);
    final bottomSheet = find.byType(BottomSheet);
    expect(
      find.descendant(
        of: bottomSheet,
        matching: find.byType(TextField),
      ),
      findsNWidgets(7),
    );
    expect(find.text('Typ paliwa'), findsOneWidget);
    expect(find.text('Typ samochodu'), findsOneWidget);
  });

  testWidgets('Otwieranie bottom sheet z wypożyczeniami',
          (WidgetTester tester) async {
        when(mockApiService.getCarListings()).thenAnswer((_) async => sampleListings);
        when(mockApiService.getUserCarRentals()).thenAnswer((_) async => sampleRentals);
        when(mockApiService.getReviewsForListing(1)).thenAnswer((_) async => []);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton).at(1));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();

        expect(find.text('Pokaż zakończone wypożyczenia'), findsOneWidget);
        expect(find.text('Toyota'), findsOneWidget);
        expect(find.text('Aktywne'), findsOneWidget);
      });

  testWidgets('Filtrowanie po marce', (WidgetTester tester) async {
    when(mockApiService.getCarListings()).thenAnswer((_) async => sampleListings);
    when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Toyota');

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zastosuj'), warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(googleMap.markers.length, 1);
    expect(googleMap.markers.first.markerId, const MarkerId('1'));
  });

  testWidgets('Wyświetlanie zakończonych wypożyczeń', (WidgetTester tester) async {
    final endedRental = CarRental(
      carRentalId: 2,
      carListingId: 2,
      userId: 1,
      carListing: sampleListings[1],
      rentalStartDate: DateTime.now().subtract(const Duration(days: 10)),
      rentalEndDate: DateTime.now().subtract(const Duration(days: 3)),
      rentalPrice: 840.0,
      rentalStatus: 'Zakończone',
    );

    when(mockApiService.getCarListings()).thenAnswer((_) async => sampleListings);
    when(mockApiService.getUserCarRentals())
        .thenAnswer((_) async => [endedRental]);
    when(mockApiService.getReviewsForListing(2)).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton).at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.text('Honda'), findsOneWidget);
    expect(find.text('Zakończone'), findsOneWidget);
  });

  testWidgets('Wyświetlanie przycisku "Dodaj opinię"', (WidgetTester tester) async {
    final endedRental = CarRental(
      carRentalId: 3,
      carListingId: 1,
      userId: 1,
      carListing: sampleListings[0],
      rentalStartDate: DateTime.now().subtract(const Duration(days: 10)),
      rentalEndDate: DateTime.now().subtract(const Duration(days: 3)),
      rentalPrice: 700.0,
      rentalStatus: 'Zakończone',
    );

    when(mockApiService.getCarListings()).thenAnswer((_) async => sampleListings);
    when(mockApiService.getUserCarRentals())
        .thenAnswer((_) async => [endedRental]);
    when(mockApiService.getReviewsForListing(1)).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton).at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.text('Dodaj opinię'), findsOneWidget);
  });
}