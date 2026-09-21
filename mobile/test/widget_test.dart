import 'package:flutter_test/flutter_test.dart';
import 'package:club_100_gym_app/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    await tester.pumpWidget(const Club100GymApp(isSetupComplete: false));
    expect(find.text('ELITE FITNESS GYM'), findsOneWidget);
  });
}
