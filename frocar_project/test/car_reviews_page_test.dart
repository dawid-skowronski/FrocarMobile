import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/models/car_rental_review.dart';
import 'package:test_project/models/car_rental.dart';
import 'package:test_project/models/car_listing.dart';
import 'package:test_project/models/user.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/car_reviews_page.dart';
import 'package:test_project/services/api_service.dart';

import 'car_reviews_page_test.mocks.dart';

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

  Widget createWidgetUnderTest(int listingId) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
      ],
      child: MaterialApp(
        home: CarReviewsPage(
          listingId: listingId,
          apiService: mockApiService,
        ),
        routes: {
          '/notifications': (_) => const Scaffold(body: Text('Notifications')),
        },
      ),
    );
  }

  testWidgets('Pokazuje spinner podczas ładowania', (WidgetTester tester) async {
    final completer = Completer<List<CarRentalReview>>();
    when(mockApiService.getReviewsForListing(any))
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(createWidgetUnderTest(1));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Pokazuje komunikat błędu przy wyjątku', (WidgetTester tester) async {
    when(mockApiService.getReviewsForListing(any))
        .thenAnswer((_) async => Future.error(Exception('Testowy błąd')));

    await tester.pumpWidget(createWidgetUnderTest(1));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Nie udało się załadować recenzji. Sprawdź połączenie z internetem lub spróbuj ponownie później.',
      ),
      findsOneWidget,
    );
  });


  testWidgets('Pokazuje wiadomość, gdy nie ma recenzji', (WidgetTester tester) async {
    when(mockApiService.getReviewsForListing(any))
        .thenAnswer((_) async => <CarRentalReview>[]);

    await tester.pumpWidget(createWidgetUnderTest(1));
    await tester.pumpAndSettle();

    expect(
      find.text('Ten pojazd nie posiada jeszcze żadnych recenzji.'),
      findsOneWidget,
    );
  });

  testWidgets('Pokazuje listę recenzji, gdy dane są dostępne', (WidgetTester tester) async {
    final dummyUser1 = User(
      id: 1,
      username: 'janek123',
      email: 'j@example.com',
      role: 'User',
    );
    final dummyUser2 = User(
      id: 2,
      username: 'aga_88',
      email: 'a@example.com',
      role: 'User',
    );

    final dummyCarListing = CarListing.placeholder();
    final dummyCarRental = CarRental(
      carRentalId: 1,
      carListingId: 1,
      userId: 1,
      rentalStartDate: DateTime(2024, 5, 1),
      rentalEndDate: DateTime(2024, 5, 5),
      rentalPrice: 100.0,
      rentalStatus: 'Zakończone',
      carListing: dummyCarListing,
    );

    final mockReviews = <CarRentalReview>[
      CarRentalReview(
        reviewId: 1,
        carRentalId: 1,
        carRental: dummyCarRental,
        userId: 1,
        user: dummyUser1,
        rating: 5,
        comment: 'Świetny samochód!',
        createdAt: DateTime(2024, 5, 1),
      ),
      CarRentalReview(
        reviewId: 2,
        carRentalId: 1,
        carRental: dummyCarRental,
        userId: 2,
        user: dummyUser2,
        rating: 3,
        comment: null,
        createdAt: DateTime(2024, 5, 2),
      ),
    ];

    when(mockApiService.getReviewsForListing(any))
        .thenAnswer((_) async => mockReviews);

    await tester.pumpWidget(createWidgetUnderTest(1));
    await tester.pumpAndSettle();

    expect(find.text('Świetny samochód!'), findsOneWidget);
    expect(find.text('Brak komentarza'), findsOneWidget);
    expect(find.textContaining('Autor: janek123'), findsOneWidget);
    expect(find.textContaining('Autor: aga_88'), findsOneWidget);
    expect(find.textContaining('Data: 2024-05-01'), findsOneWidget);
    expect(find.textContaining('Data: 2024-05-02'), findsOneWidget);
  });
}
