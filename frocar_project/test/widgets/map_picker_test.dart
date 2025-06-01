import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:test_project/providers/theme_provider.dart';
import 'package:test_project/widgets/map_picker.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockHttpClient mockClient;
  late ThemeProvider themeProvider;

  Widget createWidgetUnderTest({bool isDarkMode = false}) {
    themeProvider = ThemeProvider();

    if (themeProvider.isDarkMode != isDarkMode) {
      themeProvider.toggleTheme();
    }

    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => themeProvider,
      child: MaterialApp(
        home: MapPicker(httpClient: mockClient),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(FakeRoute());
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(const CameraPosition(target: LatLng(0, 0), zoom: 10));
  });

  setUp(() {
    mockClient = MockHttpClient();
  });

  group('MapPicker Tests', () {
    testWidgets('initially renders GoogleMap with correct initial position', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(GoogleMap), findsOneWidget);
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMap.initialCameraPosition.target.latitude, 52.2297);
      expect(googleMap.initialCameraPosition.target.longitude, 21.0122);
      expect(googleMap.initialCameraPosition.zoom, 10);
      expect(googleMap.markers, isEmpty);
    });

    testWidgets('shows CircularProgressIndicator while searching', (tester) async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('[{"lat": "52.2297", "lon": "21.0122"}]', 200);
      });

      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Warsaw');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMap.markers.length, 1);
      expect(googleMap.markers.first.position.latitude, 52.2297);
      expect(googleMap.markers.first.position.longitude, 21.0122);
    });

    testWidgets('shows SnackBar when searching with empty address', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Proszę wpisać adres'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows SnackBar when API returns no results', (tester) async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('[]', 200));

      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Invalid Address');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Nie znaleziono lokalizacji dla podanego adresu'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows SnackBar on API error', (tester) async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Error', 500));

      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Warsaw');
      await tester.tap(find.byIcon(Icons.search));

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Błąd podczas wyszukiwania adresu'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('tapping on map sets marker and enables confirm button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final googleMapFinder = find.byType(GoogleMap);
      expect(googleMapFinder, findsOneWidget);

      final position = LatLng(52.0, 21.0);
      final googleMap = tester.widget<GoogleMap>(googleMapFinder);
      googleMap.onTap!(position);

      await tester.pump();

      final updatedGoogleMap = tester.widget<GoogleMap>(googleMapFinder);
      expect(updatedGoogleMap.markers.length, 1);
      expect(updatedGoogleMap.markers.first.markerId.value, 'selected-location');
      expect(updatedGoogleMap.markers.first.position.latitude, 52.0);
      expect(updatedGoogleMap.markers.first.position.longitude, 21.0);

      final confirmButton = find.widgetWithIcon(IconButton, Icons.check);
      expect(confirmButton, findsOneWidget);

      final buttonWidget = tester.widget<IconButton>(confirmButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('confirm button returns selected location when location is selected', (tester) async {
      final navigatorObserver = MockNavigatorObserver();
      when(() => navigatorObserver.didPop(any(), any())).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: MapPicker(httpClient: mockClient),
          navigatorObservers: [navigatorObserver],
        ),
      );

      final position = LatLng(52.0, 21.0);
      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      googleMap.onTap!(position);

      await tester.pump();

      final updatedGoogleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(updatedGoogleMap.markers.length, 1);
      expect(updatedGoogleMap.markers.first.position.latitude, 52.0);
      expect(updatedGoogleMap.markers.first.position.longitude, 21.0);

      final confirmButton = find.widgetWithIcon(IconButton, Icons.check);
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });

    testWidgets('confirm button shows SnackBar if no location selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final confirmButton = find.widgetWithIcon(IconButton, Icons.check);
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Proszę wybrać lokalizację na mapie'), findsOneWidget);
    });
  });
}