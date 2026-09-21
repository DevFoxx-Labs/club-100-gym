import 'package:flutter_test/flutter_test.dart';
import 'package:the_elite_fitness/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    await tester.pumpWidget(const Club100GymApp(isSetupComplete: false));
    expect(find.byType(Club100GymApp), findsOneWidget);
  });
}
