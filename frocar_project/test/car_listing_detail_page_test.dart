import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/car_listing_detail_page.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/user.dart';
import 'package:test_project/models/car_rental_review.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/services/api_service.dart';
import 'car_listing_detail_page_test.mocks.dart';

@GenerateMocks([
  ApiService,
  ThemeProvider,
  FlutterSecureStorage,
  NotificationProvider,
])
class MockCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationPressed;

  const MockCustomAppBar({
    super.key,
    required this.title,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: onNotificationPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class TestCarListingDetailPage extends CarListingDetailPage {
  TestCarListingDetailPage({super.key, required super.listing});

  @override
  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    return 'Mockowany adres, Warszawa';
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = super.build(context) as Scaffold;
    return Scaffold(
      appBar: MockCustomAppBar(
        title: "Szczegóły pojazdu",
        onNotificationPressed: () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
      body: scaffold.body,
    );
  }
}

void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockNotificationProvider mockNotificationProvider;

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
    userId: 999,
    isAvailable: true,
    isApproved: true,
    averageRating: 4.5,
  );

  setUp(() {
    mockApiService = MockApiService();
    mockThemeProvider = MockThemeProvider();
    mockSecureStorage = MockFlutterSecureStorage();
    mockNotificationProvider = MockNotificationProvider();

    when(mockApiService.getReviewsForListing(any)).thenAnswer((_) async => []);

    when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async {});
    when(mockNotificationProvider.notificationCount).thenReturn(0);
    when(mockNotificationProvider.resetNotificationCount()).thenReturn(null);
  });

  Future<void> pumpCarListingDetailPage(WidgetTester tester, CarListing listing) async {
    final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6IjEyMyJ9.4q3z3q3z3q3z3q3z3q3z3q3z3q3z3q3z3q3z3q3z3q3';
    when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async {
      return token;
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
          ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
        ],
        child: MaterialApp(
          home: TestCarListingDetailPage(listing: listing),
          routes: {
            '/notifications': (context) => const Scaffold(body: Center(child: Text('Notifications'))),
            '/rent_form': (context) => const Scaffold(body: Center(child: Text('Rent Form'))),
            '/car_listing': (context) => const Scaffold(body: Center(child: Text('Car Listing'))),
            '/car_reviews': (context) => const Scaffold(body: Center(child: Text('Car Reviews'))),
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('Wyświetla podstawowe dane pojazdu', (tester) async {
    await pumpCarListingDetailPage(tester, sampleListing);
    expect(find.text('Marka: Toyota'), findsOneWidget);
    expect(find.text('Pojemność silnika: 2.0 l'), findsOneWidget);
    expect(find.text('Rodzaj paliwa: Benzyna'), findsOneWidget);
    expect(find.text('Typ samochodu: Sedan'), findsOneWidget);
    expect(find.text('Cena wynajmu za dzień: 200.00 PLN'), findsOneWidget);
  });

  testWidgets('Wyświetla adres z mockowanych danych', (tester) async {
    await pumpCarListingDetailPage(tester, sampleListing);
    expect(find.text('Adres: Mockowany adres, Warszawa'), findsOneWidget);
  });

  testWidgets('Wyświetla przycisk Wypożycz dla innego użytkownika', (tester) async {
    await pumpCarListingDetailPage(tester, sampleListing);
    expect(find.text('Wypożycz'), findsOneWidget);
    expect(find.text('Edytuj'), findsNothing);
    expect(find.text('Usuń'), findsNothing);
  });

  testWidgets('Wyświetla przyciski Edytuj/Usuń dla właściciela', (tester) async {
    final ownerListing = sampleListing.copyWith(userId: 123);
    await pumpCarListingDetailPage(tester, ownerListing);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Wypożycz'), findsNothing);
    expect(find.text('Edytuj'), findsOneWidget);
    expect(find.text('Usuń'), findsOneWidget);
  });

  testWidgets('Pokazuje dialog potwierdzenia usunięcia', (tester) async {
    final ownerListing = sampleListing.copyWith(userId: 123);
    when(mockApiService.deleteCarListing(ownerListing.id)).thenAnswer((_) async => true);

    await pumpCarListingDetailPage(tester, ownerListing);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();
    await tester.tap(find.text('Usuń'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Potwierdzenie'), findsOneWidget);
    expect(find.text('Czy na pewno chcesz usunąć ten pojazd?'), findsOneWidget);
  });

  testWidgets('Wyświetla recenzje gdy są dostępne', (tester) async {
    final mockCarRental = CarRental(
      carRentalId: 1,
      carListingId: sampleListing.id,
      userId: 456,
      rentalStartDate: DateTime.now().subtract(const Duration(days: 5)),
      rentalEndDate: DateTime.now(),
      rentalPrice: sampleListing.rentalPricePerDay * 5,
      rentalStatus: 'completed',
      carListing: sampleListing,
    );

    final mockReview = CarRentalReview(
      reviewId: 1,
      carRentalId: mockCarRental.carRentalId,
      carRental: mockCarRental,
      userId: 456,
      user: User(
        id: 456,
        username: 'JanKowalski',
        email: 'jan@kowalski.pl',
        role: 'User',
      ),
      rating: 5,
      comment: 'Świetny samochód!',
      createdAt: DateTime.now(),
    );

    when(mockApiService.getReviewsForListing(sampleListing.id)).thenAnswer((_) async {
      return [mockReview];
    });

    await pumpCarListingDetailPage(tester, sampleListing);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Średnia ocena: 5.0 (1 opinii)'), findsOneWidget);
    expect(find.text('Świetny samochód!'), findsOneWidget);
  });

  testWidgets('Obsługuje błąd ładowania recenzji', (tester) async {
    when(mockApiService.getReviewsForListing(sampleListing.id)).thenAnswer((_) async {
      throw Exception('Błąd serwera');
    });

    await pumpCarListingDetailPage(tester, sampleListing);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Nie udało się załadować danych. Spróbuj ponownie później.'), findsOneWidget);
  });
}