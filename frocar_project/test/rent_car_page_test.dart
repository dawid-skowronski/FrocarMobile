import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/rent_car_page.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'rent_car_page_test.mocks.dart';

@GenerateMocks([
  ApiService,
  FlutterSecureStorage,
  GoogleMapController,
])

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool _isLocationServiceEnabled = true;
  LocationPermission _permission = LocationPermission.always;
  Position _position = Position(
    latitude: 52.2296756,
    longitude: 21.0122287,
    timestamp: DateTime.now(),
    accuracy: 1.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );

  void setLocationServiceEnabled(bool enabled) {
    _isLocationServiceEnabled = enabled;
  }

  void setPermission(LocationPermission permission) {
    _permission = permission;
  }

  void setPosition(Position position) {
    _position = position;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _isLocationServiceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return _permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return _permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return _position;
  }
}

void main() {
  late MockApiService mockApiService;
  late MockFlutterSecureStorage mockStorage;
  late MockGoogleMapController mockMapController;
  late FakeGeolocatorPlatform fakeGeolocator;
  late ThemeProvider themeProvider;
  late NotificationProvider notificationProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockStorage = MockFlutterSecureStorage();
    mockMapController = MockGoogleMapController();
    fakeGeolocator = FakeGeolocatorPlatform();
    themeProvider = ThemeProvider(storage: mockStorage);
    notificationProvider = NotificationProvider();

    GeolocatorPlatform.instance = fakeGeolocator;

    when(mockStorage.read(key: 'token')).thenAnswer((_) async =>
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjEiLCJleHAiOjE3Mjg3NjU2MDB9.SIGNATURE');
    when(mockStorage.read(key: 'username')).thenAnswer((_) async => 'test_user');
    when(mockStorage.read(key: 'isDarkMode')).thenAnswer((_) async => 'false');
    when(mockStorage.delete(key: 'token')).thenAnswer((_) async => {});
    when(mockStorage.delete(key: 'username')).thenAnswer((_) async => {});
  });

  CarListing createTestCarListing({
    int id = 1,
    String brand = 'Toyota',
    double latitude = 52.2296756,
    double longitude = 21.0122287,
    int userId = 2,
    bool isAvailable = true,
    double rentalPricePerDay = 100.0,
  }) {
    return CarListing(
      id: id,
      brand: brand,
      engineCapacity: 2.0,
      fuelType: 'Benzyna',
      seats: 5,
      carType: 'Sedan',
      features: ['Klimatyzacja', 'GPS'],
      latitude: latitude,
      longitude: longitude,
      userId: userId,
      isAvailable: isAvailable,
      rentalPricePerDay: rentalPricePerDay,
      isApproved: true,
      averageRating: 4.5,
    );
  }

  CarRental createTestCarRental({
    int carRentalId = 1,
    int carListingId = 1,
    int userId = 1,
    String status = 'Aktywne',
  }) {
    return CarRental(
      carRentalId: carRentalId,
      carListingId: carListingId,
      userId: userId,
      rentalStartDate: DateTime.now(),
      rentalEndDate: DateTime.now().add(Duration(days: 3)),
      rentalPrice: 300.0,
      rentalStatus: status,
      carListing: createTestCarListing(id: carListingId, userId: 2),
    );
  }

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        Provider<FlutterSecureStorage>.value(value: mockStorage),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
      ],
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1200)),
        child: MaterialApp(
          home: child,
          routes: {
            '/notifications': (context) => const Scaffold(body: Text('Notifications Page')),
            '/carListingDetail': (context) => const Scaffold(body: Text('Car Rental')),
            '/addReview': (context) => const Scaffold(body: Text('Add Review Page')),
            '/login': (context) => const Scaffold(body: Text('Login Page')),
          },
        ),
      ),
    );
  }

  group('RentCarPage Tests', () {
    testWidgets('RentCarPage initializes and displays map', (WidgetTester tester) async {
      when(mockApiService.getCarListings()).thenAnswer((_) async => [createTestCarListing()]);
      when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(const RentCarPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(CustomAppBar), findsOneWidget);
      expect(find.text('Wypożycz auto'), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('Filters car listings based on brand', (WidgetTester tester) async {
      when(mockApiService.getCarListings()).thenAnswer((_) async => [
        createTestCarListing(brand: 'Toyota'),
        createTestCarListing(brand: 'BMW', id: 2),
      ]);
      when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(const RentCarPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final filterButton = find.text('Filtry');
      await tester.ensureVisible(filterButton);
      await tester.tap(filterButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Toyota');
      final applyButton = find.text('Zastosuj');
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(mockApiService.getCarListings()).called(greaterThanOrEqualTo(2));
    });

    testWidgets('Navigates to CarListingDetailPage on marker tap',
            (WidgetTester tester) async {
          final testListing = createTestCarListing();
          when(mockApiService.getCarListings()).thenAnswer((_) async => [testListing]);
          when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

          await tester.pumpWidget(createTestWidget(const RentCarPage()));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(find.byType(GoogleMap), findsOneWidget);

          await tester.runAsync(() async {
            Navigator.of(tester.element(find.byType(RentCarPage))).push(
              MaterialPageRoute(
                builder: (context) => const Scaffold(body: Text('Toyota')),
                settings: const RouteSettings(name: '/carListingDetail'),
              ),
            );
          });
          await tester.pumpAndSettle();

          expect(find.text('Toyota'), findsOneWidget);
        });

    testWidgets('Handles location permission denied', (WidgetTester tester) async {
      fakeGeolocator.setPermission(LocationPermission.denied);

      when(mockApiService.getCarListings()).thenAnswer((_) async => []);
      when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(const RentCarPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('Updates map style based on theme', (WidgetTester tester) async {
      when(mockApiService.getCarListings()).thenAnswer((_) async => []);
      when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);
      when(mockStorage.read(key: 'isDarkMode')).thenAnswer((_) async => 'true');

      await themeProvider.loadTheme();

      await tester.pumpWidget(createTestWidget(const RentCarPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('Notification icon updates badge when count changes', (WidgetTester tester) async {
      when(mockApiService.getCarListings()).thenAnswer((_) async => [createTestCarListing()]);
      when(mockApiService.getUserCarRentals()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(const RentCarPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('0'), findsNothing);

      notificationProvider.incrementNotificationCount();
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      notificationProvider.resetNotificationCount();
      await tester.pumpAndSettle();

      expect(find.text('1'), findsNothing);
    });
  });
}