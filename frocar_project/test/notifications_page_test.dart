import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:test_project/services/api_service.dart';
import 'package:test_project/providers/notification_provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/notifications_page.dart';

import 'notifications_page_test.mocks.dart';

@GenerateMocks([ApiService, FlutterSecureStorage])
void main() {
  late MockApiService mockApiService;
  late MockFlutterSecureStorage mockSecureStorage;
  late NotificationProvider notificationProvider;
  late ThemeProvider themeProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockSecureStorage = MockFlutterSecureStorage();
    notificationProvider = NotificationProvider();
    themeProvider = ThemeProvider();

    when(mockSecureStorage.read(key: 'token')).thenAnswer((_) async => 'mock_token');
    when(mockSecureStorage.read(key: 'username')).thenAnswer((_) async => 'test_user');
    when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  Widget _wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApiService),
        Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Pokazuje spinner podczas ładowania', (tester) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    when(mockApiService.fetchAccountNotifications())
        .thenAnswer((_) => completer.future);

    await tester.pumpWidget(_wrapWithProviders(const NotificationsPage()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Pokazuje błąd przy fetchAccountNotifications', (tester) async {
    when(mockApiService.fetchAccountNotifications()).thenThrow(Exception('Fetch Error'));

    await tester.pumpWidget(_wrapWithProviders(const NotificationsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Wystąpił błąd podczas ładowania powiadomień.'), findsOneWidget);
  });

  testWidgets('Pokazuje komunikat gdy brak powiadomień', (tester) async {
    when(mockApiService.fetchAccountNotifications())
        .thenAnswer((_) async => <Map<String, dynamic>>[]);

    await tester.pumpWidget(_wrapWithProviders(const NotificationsPage()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Brak nowych powiadomień.'), findsOneWidget);
  });

  testWidgets('Pokazuje listę powiadomień', (tester) async {
    final sample = <Map<String, dynamic>>[
      {'notificationId': 1, 'message': 'Test 1', 'createdAt': '2025-05-28'},
      {'notificationId': 2, 'message': 'Test 2', 'createdAt': null},
    ];
    when(mockApiService.fetchAccountNotifications())
        .thenAnswer((_) async => sample);

    await tester.pumpWidget(_wrapWithProviders(const NotificationsPage()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Test 1'), findsOneWidget);
    expect(find.text('Data: 2025-05-28'), findsOneWidget);
    expect(find.text('Test 2'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('Oznacza powiadomienie jako przeczytane', (tester) async {
    final sample = <Map<String, dynamic>>[
      {'notificationId': 1, 'message': 'One', 'createdAt': null},
      {'notificationId': 2, 'message': 'Two', 'createdAt': null},
    ];
    when(mockApiService.fetchAccountNotifications())
        .thenAnswer((_) async => sample);
    when(mockApiService.markAccountNotificationAsRead(1))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(_wrapWithProviders(const NotificationsPage()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final firstCheck = find.widgetWithIcon(IconButton, Icons.check).first;
    await tester.tap(firstCheck);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('One'), findsNothing);
    expect(find.text('Two'), findsOneWidget);
    expect(notificationProvider.notificationCount, 1);
  });
}