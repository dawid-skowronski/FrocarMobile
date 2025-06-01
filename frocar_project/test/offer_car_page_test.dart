import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:test_project/models/car_listing.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/offer_car_page.dart';

import 'offer_car_page_test.mocks.dart';

class FakeNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    pushed.add(route);
  }
}

@GenerateMocks([ApiService, FlutterSecureStorage])
void main() {
  late MockApiService mockApiService;
  late MockFlutterSecureStorage mockSecureStorage;
  late ThemeProvider themeProvider;
  late NotificationProvider notificationProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockSecureStorage = MockFlutterSecureStorage();
    themeProvider = ThemeProvider();
    notificationProvider = NotificationProvider();

    when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async => 'mock_token');
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'test_user');
    when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  Widget _wrap(Widget child, {NavigatorObserver? observer}) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
      ],
      child: MaterialApp(
        home: child,
        navigatorObservers: observer != null ? [observer] : [],
        routes: {
          '/notifications': (_) => const Scaffold(body: Text('Notifications')),
        },
      ),
    );
  }

  testWidgets('Spinner przy ładowaniu', (tester) async {
    final completer = Completer<List<CarListing>>();
    when(mockApiService.getUserCarListings())
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrap(OfferCarPage(apiService: mockApiService)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Błąd przy pobieraniu wyświetla SnackBar', (tester) async {
    when(mockApiService.getUserCarListings())
        .thenThrow(Exception('Load Error'));

    await tester.pumpWidget(_wrap(OfferCarPage(apiService: mockApiService)));
    await tester.pumpAndSettle(); // poczekaj na pełne wyrenderowanie i animacje

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Wystąpił problem podczas pobierania ogłoszeń.'), findsOneWidget);

    expect(find.text('Brak ogłoszeń'), findsOneWidget);
  });


  testWidgets('Brak ogłoszeń po udanym pobraniu pustej listy', (tester) async {
    when(mockApiService.getUserCarListings())
        .thenAnswer((_) async => <CarListing>[]);

    await tester.pumpWidget(_wrap(OfferCarPage(apiService: mockApiService)));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Brak ogłoszeń'), findsOneWidget);
  });

  testWidgets('Pokazuje listę ogłoszeń z odpowiednim statusem', (tester) async {
    final listings = [
      CarListing(
        id: 1,
        brand: 'A',
        engineCapacity: 1.2,
        fuelType: 'Benzyna',
        seats: 4,
        carType: 'Sedan',
        rentalPricePerDay: 100,
        features: [],
        latitude: 0,
        longitude: 0,
        userId: 1,
        isAvailable: true,
        isApproved: true,
        averageRating: 4.0,
      ),
      CarListing(
        id: 2,
        brand: 'B',
        engineCapacity: 1.0,
        fuelType: 'Diesel',
        seats: 2,
        carType: 'Hatchback',
        rentalPricePerDay: 120,
        features: [],
        latitude: 0,
        longitude: 0,
        userId: 1,
        isAvailable: false,
        isApproved: false,
        averageRating: 3.5,
      ),
    ];
    when(mockApiService.getUserCarListings())
        .thenAnswer((_) async => listings);

    await tester.pumpWidget(_wrap(OfferCarPage(apiService: mockApiService)));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byType(ListTile), findsNWidgets(2));

    expect(find.text('A'), findsOneWidget);
    expect(find.text('Aktualne'), findsOneWidget);

    expect(find.text('B'), findsOneWidget);
    expect(find.text('Oczekujące'), findsOneWidget);
    expect(find.text('Wypożyczone'), findsOneWidget);
  });

  testWidgets('Nawigacja do szczegółów ogłoszenia', (tester) async {
    final listings = [
      CarListing(
        id: 3,
        brand: 'C',
        engineCapacity: 2.0,
        fuelType: 'Elektryk',
        seats: 5,
        carType: 'SUV',
        rentalPricePerDay: 200,
        features: [],
        latitude: 0,
        longitude: 0,
        userId: 1,
        isAvailable: true,
        isApproved: true,
        averageRating: 5.0,
      ),
    ];
    when(mockApiService.getUserCarListings())
        .thenAnswer((_) async => listings);

    when(mockApiService.getReviewsForListing(3))
        .thenAnswer((_) async => []);

    final observer = FakeNavigatorObserver();
    await tester.pumpWidget(_wrap(OfferCarPage(apiService: mockApiService), observer: observer));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(observer.pushed.length, greaterThanOrEqualTo(1));
  });
}