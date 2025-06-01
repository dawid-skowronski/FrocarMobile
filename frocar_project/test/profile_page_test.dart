import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_project/services/api_service.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/profile_page.dart';
import 'package:test_project/login.dart';
import 'profile_page_test.mocks.dart';

@GenerateMocks([ApiService, ThemeProvider, FlutterSecureStorage, NotificationProvider])
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

    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'testuser');

    when(mockNotificationProvider.notificationCount).thenReturn(0);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
      ],
      child: MaterialApp(
        home: const ProfilePage(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/notifications': (context) => const Scaffold(
            body: Center(child: Text('Notifications')),
          ),
        },
        builder: (context, child) => ScaffoldMessenger(
          child: child!,
        ),
      ),
    );
  }

  group('ProfilePage Tests', () {
    testWidgets('Renders ProfilePage with current username', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Aktualna nazwa użytkownika: testuser'), findsOneWidget);
      expect(find.text('Nowa nazwa użytkownika'), findsOneWidget);
      expect(find.text('Zapisz zmiany'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('TextFormField is pre-filled with current username', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller!.text, 'testuser');
    });

    testWidgets('Shows validation error when username is empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Zapisz zmiany'));
      await tester.pumpAndSettle();

      expect(find.text('Nazwa użytkownika jest wymagana'), findsOneWidget);
    });

    testWidgets('Updates username successfully and navigates to LoginScreen', (tester) async {
      when(mockApiService.changeUsername('newuser')).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'newuser');
      await tester.tap(find.text('Zapisz zmiany'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nazwa użytkownika została zmieniona. Zaloguj się ponownie.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Shows error SnackBar when username update fails', (tester) async {
      when(mockApiService.changeUsername('newuser')).thenThrow(Exception('Nie udało się zmienić nazwy użytkownika'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'newuser');
      await tester.tap(find.text('Zapisz zmiany'));
      await tester.pump(); // trigger UI update
      await tester.pumpAndSettle();

      expect(find.text('Wystąpił błąd podczas zmiany nazwy użytkownika.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });


    testWidgets('Shows CircularProgressIndicator while updating username', (tester) async {
      when(mockApiService.changeUsername('newuser')).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'newuser');
      await tester.tap(find.text('Zapisz zmiany'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Nazwa użytkownika została zmieniona. Zaloguj się ponownie.'), findsOneWidget);
    });
  });
}