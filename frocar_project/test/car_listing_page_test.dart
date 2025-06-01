import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/car_listing_page.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'car_listing_page_test.mocks.dart';

@GenerateMocks([
  ApiService,
  ThemeProvider,
  NotificationProvider,
  FlutterSecureStorage,
  http.Client,
  SharedPreferences,
  Connectivity,
])
void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotifier;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockClient mockHttpClient;
  late MockSharedPreferences mockSharedPreferences;
  late MockConnectivity mockConnectivity;

  final sampleListing = CarListing(
    id: 1,
    brand: 'Toyota',
    engineCapacity: 2.0,
    fuelType: 'Benzyna',
    seats: 5,
    carType: 'Sedan',
    rentalPricePerDay: 200.0,
    features: ['Klimatyzacja', 'Nawigacja'],
    latitude: 52.2297,
    longitude: 21.0122,
    userId: 123,
    isAvailable: true,
    isApproved: true,
    averageRating: 4.5,
  );

  setUp(() {
    mockApiService = MockApiService();
    mockThemeProvider = MockThemeProvider();
    mockNotifier = MockNotificationProvider();
    mockSecureStorage = MockFlutterSecureStorage();
    mockHttpClient = MockClient();
    mockSharedPreferences = MockSharedPreferences();
    mockConnectivity = MockConnectivity();

    when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async {});

    when(mockNotifier.notificationCount).thenReturn(0);
    when(mockNotifier.resetNotificationCount()).thenReturn(null);

    when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async => 'mock_token');
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'test_user');
    when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

    when(mockSharedPreferences.getStringList('pending_listings'))
        .thenReturn([]);
    when(mockSharedPreferences.setStringList('pending_listings', any))
        .thenAnswer((_) async => true);

    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => ConnectivityResult.wifi);
  });

  Future<void> pumpCarListingPage(
      WidgetTester tester, {
        CarListing? listing,
        bool mockGeocoding = true,
        bool isOnline = true,
      }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (mockGeocoding) {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        return http.Response(
          json.encode({
            'address': {
              'road': 'Testowa',
              'house_number': '1',
              'state': 'Mazowieckie',
              'city': 'Warszawa',
              'postcode': '00-100',
            },
          }),
          200,
        );
      });
    } else {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response('Error', 400));
    }

    when(mockConnectivity.checkConnectivity()).thenAnswer((_) async =>
    isOnline ? ConnectivityResult.wifi : ConnectivityResult.none);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: mockNotifier),
          Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
          Provider<http.Client>.value(value: mockHttpClient),
          Provider<SharedPreferences>.value(value: mockSharedPreferences),
          Provider<Connectivity>.value(value: mockConnectivity),
        ],
        child: MaterialApp(
          home: CarListingPage(listing: listing),
          routes: {
            '/notifications': (context) => const Scaffold(
              body: Center(child: Text('Notifications')),
            ),
            '/map_picker': (context) => const MockMapPicker(),
          },
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('Wyświetla formularz dodawania nowego ogłoszenia', (tester) async {
    await pumpCarListingPage(tester);

    expect(find.widgetWithText(ElevatedButton, 'Dodaj ogłoszenie'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Wybierz rodzaj paliwa'), findsOneWidget);
    expect(find.text('Wybierz typ samochodu'), findsOneWidget);
    expect(find.text('Wybierz lokalizację na mapie'), findsOneWidget);
  });

  testWidgets('Wypełnia pola formularza przy edycji istniejącego ogłoszenia', (tester) async {
    await pumpCarListingPage(tester, listing: sampleListing);

    expect(find.widgetWithText(TextFormField, 'Marka'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Pojemność silnika (l)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Liczba miejsc'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Cena wynajmu za dzień (PLN)'), findsOneWidget);

    final brandField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Marka'));
    expect(brandField.controller!.text, 'Toyota');

    final engineField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Pojemność silnika (l)'));
    expect(engineField.controller!.text, '2.0');

    final seatsField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Liczba miejsc'));
    expect(seatsField.controller!.text, '5');

    final priceField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Cena wynajmu za dzień (PLN)'));
    expect(priceField.controller!.text, '200.0');

    expect(find.text('Klimatyzacja'), findsOneWidget);
    expect(find.text('Nawigacja'), findsOneWidget);
  });

  testWidgets('Waliduje pola formularza', (tester) async {
    await pumpCarListingPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Marka'), '');
    await tester.enterText(find.widgetWithText(TextFormField, 'Pojemność silnika (l)'), '0');
    await tester.enterText(find.widgetWithText(TextFormField, 'Liczba miejsc'), '-1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena wynajmu za dzień (PLN)'), '0');

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Dodaj ogłoszenie');
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Proszę wypełnić wszystkie pola i wybrać lokalizację.'), findsOneWidget);
    expect(find.text('Pojemność musi być większa od 0.'), findsOneWidget);
    expect(find.text('Liczba miejsc musi być większa od 0.'), findsOneWidget);
    expect(find.text('Cena musi być większa od 0.'), findsOneWidget);
  });

  testWidgets('Dodaje i usuwa dodatek', (tester) async {
    await pumpCarListingPage(tester);

    final featureField = find.widgetWithText(TextField, 'Np. Klimatyzacja');
    await tester.enterText(featureField, 'Bluetooth');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Bluetooth'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Bluetooth'), findsNothing);
  });

  testWidgets('Wybiera lokalizację i wyświetla adres', (tester) async {
    await pumpCarListingPage(tester);

    await tester.tap(find.text('Wybierz lokalizację na mapie'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Wybierz lokalizację'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('Testowa'), findsOneWidget);
  });

  testWidgets('Tworzy nowe ogłoszenie online', (tester) async {
    when(mockApiService.createCarListing(any)).thenAnswer((_) async {});

    await pumpCarListingPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Marka'), 'Honda');
    await tester.enterText(find.widgetWithText(TextFormField, 'Pojemność silnika (l)'), '1.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Liczba miejsc'), '4');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena wynajmu za dzień (PLN)'), '150');

    await tester.tap(find.text('Wybierz rodzaj paliwa'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Hybryda').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Wybierz typ samochodu'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Hatchback').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.enterText(find.widgetWithText(TextField, 'Np. Klimatyzacja'), 'Bluetooth');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Wybierz lokalizację na mapie'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Wybierz lokalizację'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Dodaj ogłoszenie');
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Ogłoszenie dodane pomyślnie!'), findsOneWidget);
  });

  testWidgets('Zapisuje lokalnie gdy brak połączenia', (tester) async {
    when(mockApiService.createCarListing(any)).thenThrow(Exception('Błąd połączenia'));

    await pumpCarListingPage(tester, isOnline: false);

    await tester.enterText(find.widgetWithText(TextFormField, 'Marka'), 'Honda');
    await tester.enterText(find.widgetWithText(TextFormField, 'Pojemność silnika (l)'), '1.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Liczba miejsc'), '4');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena wynajmu za dzień (PLN)'), '150');

    await tester.tap(find.text('Wybierz rodzaj paliwa'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Hybryda').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Wybierz typ samochodu'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Hatchback').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Wybierz lokalizację na mapie'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Wybierz lokalizację'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Dodaj ogłoszenie');
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Ogłoszenie zapisane lokalnie. Zostanie dodane, gdy wrócisz online.'), findsOneWidget);
  });

  testWidgets('Aktualizuje istniejące ogłoszenie', (tester) async {
    when(mockApiService.updateCarListing(any)).thenAnswer((_) async {});

    await pumpCarListingPage(tester, listing: sampleListing);

    await tester.enterText(find.widgetWithText(TextFormField, 'Marka'), 'Honda');
    await tester.pump(const Duration(seconds: 1));

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Zapisz zmiany');
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Ogłoszenie zaktualizowane pomyślnie!'), findsOneWidget);
  });

  testWidgets('Obsługuje błąd geocodingu', (tester) async {
    await pumpCarListingPage(tester, mockGeocoding: false);

    await tester.tap(find.text('Wybierz lokalizację na mapie'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Wybierz lokalizację'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Nie udało się pobrać adresu.'), findsOneWidget);
  });

  testWidgets('Obsługuje błąd przy tworzeniu ogłoszenia', (tester) async {
    when(mockApiService.createCarListing(any)).thenThrow(Exception('Błąd serwera'));

    await pumpCarListingPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Marka'), 'Honda');
    await tester.enterText(find.widgetWithText(TextFormField, 'Pojemność silnika (l)'), '1.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Liczba miejsc'), '4');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cena wynajmu za dzień (PLN)'), '150');

    await tester.tap(find.text('Wybierz rodzaj paliwa'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Hybryda').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Wybierz typ samochodu'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Hatchback').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Wybierz lokalizację na mapie'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Wybierz lokalizację'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Dodaj ogłoszenie');
    expect(buttonFinder, findsOneWidget);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Nie udało się zapisać ogłoszenia. Spróbuj ponownie.'), findsOneWidget);
  });

  testWidgets('Wyświetla komunikat o braku internetu przy geocodingu', (tester) async {
    await pumpCarListingPage(tester, isOnline: false);

    await tester.tap(find.text('Wybierz lokalizację na mapie'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Wybierz lokalizację'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Adres niedostępny – brak połączenia z internetem.'), findsOneWidget);
  });
}

class MockMapPicker extends StatelessWidget {
  const MockMapPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Picker')),
      body: Center(
        child: ElevatedButton(
          key: const Key('location-picker-button'),
          onPressed: () {
            Navigator.pop(context, {'latitude': 52.2297, 'longitude': 21.0122});
          },
          child: const Text('Wybierz lokalizację'),
        ),
      ),
    );
  }
}