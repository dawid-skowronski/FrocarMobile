import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_project/widgets/loading_screen.dart';

void main() {
  testWidgets('LoadingScreen shows logo and progress indicator, then navigates', (WidgetTester tester) async {
    final testRoute = '/next';

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          testRoute: (context) => const Scaffold(body: Text('Next Screen')),
        },
        home: LoadingScreen(nextRoute: testRoute),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FadeTransition), findsOneWidget);

    final FadeTransition fade = tester.widget(find.byType(FadeTransition));
    expect(fade.opacity.value, 0.0);

    await tester.pump(const Duration(milliseconds: 500));
    expect(fade.opacity.value, 1.0);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Next Screen'), findsOneWidget);
  });
}
