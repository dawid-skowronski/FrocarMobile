import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/add_review_page.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/services/api_service.dart';

import 'add_review_page_test.mocks.dart';

@GenerateMocks([
  ApiService,
  ThemeProvider,
  FlutterSecureStorage,
  NotificationProvider,
])
void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockNotificationProvider mockNotificationProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockThemeProvider = MockThemeProvider();
    mockSecureStorage = MockFlutterSecureStorage();
    mockNotificationProvider = MockNotificationProvider();

    when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);
    when(mockThemeProvider.isDarkMode).thenReturn(false);
    when(mockThemeProvider.toggleTheme()).thenAnswer((_) async {});

    when(mockSecureStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);

    when(mockNotificationProvider.notificationCount).thenReturn(0);
    when(mockNotificationProvider.resetNotificationCount()).thenReturn(null);
  });

  Future<void> pumpAddReviewPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: mockApiService),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: mockNotificationProvider,
          ),
        ],
        child: MaterialApp(
          home: AddReviewPage(
            carRentalId: 1,
            carListingId: 1,
            apiService: mockApiService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders correctly with initial state', (tester) async {
    await pumpAddReviewPage(tester);

    expect(find.text('Jak oceniasz tę usługę?'), findsOneWidget);
    expect(find.text('Komentarz (opcjonalnie)'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(5));
  });

  testWidgets('shows error SnackBar if rating is 0 on submit', (tester) async {
    await pumpAddReviewPage(tester);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(
      find.text('Proszę wybrać ocenę, zanim dodasz opinię.'),
      findsOneWidget,
    );
  });

  testWidgets('sets rating when star button is tapped', (tester) async {
    await pumpAddReviewPage(tester);

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(4));
  });

  testWidgets('submits review successfully', (tester) async {
    await pumpAddReviewPage(tester);

    await tester.tap(find.byIcon(Icons.star_border).at(3)); // rating = 4
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Super samochód!');
    await tester.pump();

    when(mockApiService.addReview(1, 4, 'Super samochód!'))
        .thenAnswer((_) async => {});

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verify(mockApiService.addReview(1, 4, 'Super samochód!')).called(1);
  });

  testWidgets('shows error SnackBar on exception during submit', (tester) async {
    await pumpAddReviewPage(tester);

    await tester.tap(find.byIcon(Icons.star_border).first); // rating = 1
    await tester.pump();

    when(mockApiService.addReview(1, 1, any))
        .thenThrow(Exception('Błąd serwera'));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Nie udało się dodać opinii. Spróbuj ponownie później.'),
      findsOneWidget,
    );
  });
}
