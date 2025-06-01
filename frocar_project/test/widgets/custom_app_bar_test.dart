import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/widgets/custom_app_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'custom_app_bar_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late MockThemeProvider mockThemeProvider;
  late MockNotificationProvider mockNotificationProvider;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockThemeProvider = MockThemeProvider();
    mockNotificationProvider = MockNotificationProvider();
    mockSecureStorage = MockFlutterSecureStorage();
  });

  Widget createTestWidget({
    String? username,
    VoidCallback? onNotificationPressed,
    VoidCallback? onLogoutPressed,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: mockNotificationProvider),
        Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: CustomAppBar(
            title: 'Test Title',
            username: username,
            onNotificationPressed: onNotificationPressed,
            onLogoutPressed: onLogoutPressed,
          ),
        ),
      ),
    );
  }

  testWidgets('displays title and notification badge when username is set', (tester) async {
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'user123');

    await tester.pumpWidget(createTestWidget(username: 'user123'));
    await tester.pumpAndSettle();

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.byIcon(Icons.notifications), findsOneWidget);
    expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  });

  testWidgets('does not show notification and logout icons when username is null', (tester) async {
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => null);

    await tester.pumpWidget(createTestWidget(username: null));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications), findsNothing);
    expect(find.byIcon(Icons.exit_to_app), findsNothing);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  });

  testWidgets('toggleTheme changes theme mode on tap', (tester) async {
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'user');

    await tester.pumpWidget(createTestWidget(username: 'user'));

    // Dodatkowe oczekiwanie na zaktualizowanie stanu
    await tester.pumpAndSettle();

    expect(mockThemeProvider.isDarkMode, isFalse);
    final iconButton = tester.widget<IconButton>(find.byKey(const Key('theme_toggle')));
    expect((iconButton.icon as Icon).icon, Icons.dark_mode);

    await tester.tap(find.byKey(const Key('theme_toggle')));
    await tester.pumpAndSettle();

    expect(mockThemeProvider.isDarkMode, isTrue);
    final updatedIconButton = tester.widget<IconButton>(find.byKey(const Key('theme_toggle')));
    expect((updatedIconButton.icon as Icon).icon, Icons.light_mode);
  });

  testWidgets('notification button calls onNotificationPressed and resets count', (tester) async {
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'user');

    bool pressed = false;

    await tester.pumpWidget(createTestWidget(
      username: 'user',
      onNotificationPressed: () {
        pressed = true;
      },
    ));
    await tester.pumpAndSettle();

    // Symulowanie powiadomień
    mockNotificationProvider.setNotificationCount(3);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification_button')));
    await tester.pumpAndSettle();

    expect(pressed, isTrue);
    expect(mockNotificationProvider.notificationCount, 0);
  });

  testWidgets('logout button calls onLogoutPressed', (tester) async {
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'user');

    bool logoutCalled = false;

    await tester.pumpWidget(createTestWidget(
      username: 'user',
      onLogoutPressed: () {
        logoutCalled = true;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    expect(logoutCalled, isTrue);
  });
}

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  bool _isDarkMode = false;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  @override
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  Future<void> loadTheme() async {
    await Future.delayed(Duration(milliseconds: 10));
    notifyListeners();
  }
}

class MockNotificationProvider extends ChangeNotifier implements NotificationProvider {
  int _notificationCount = 0;

  @override
  int get notificationCount => _notificationCount;

  @override
  void setNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }

  @override
  void incrementNotificationCount() {
    _notificationCount++;
    notifyListeners();
  }

  @override
  void resetNotificationCount() {
    _notificationCount = 0;
    notifyListeners();
  }
}