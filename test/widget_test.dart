import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finsight/main.dart';
import 'package:finsight/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('FinSight app launch and navigate to onboarding test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FinSightApp());
    expect(find.byType(FinSightApp), findsOneWidget);

    // Advance past splash screen (3 seconds)
    await tester.pump(const Duration(seconds: 4));
    // The splash callback awaits secure storage before replacing its route.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
