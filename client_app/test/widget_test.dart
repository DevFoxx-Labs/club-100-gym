import 'package:flutter_test/flutter_test.dart';
import 'package:the_elite_fitness_client/core/models/client_announcement_model.dart';
import 'package:the_elite_fitness_client/features/onboarding/welcome_screen.dart';
import 'package:the_elite_fitness_client/main.dart';

void main() {
  group('Client App Tests', () {
    test('ClientAnnouncementModel serialization and category visuals work', () {
      final now = DateTime(2026, 9, 22, 10, 30);
      final model = ClientAnnouncementModel(
        id: 'client-ann-1',
        title: 'Zumba Class Tomorrow',
        message: "Don't miss our special Zumba Dance Fitness class tomorrow at 6:00 AM in the Aerobics Studio. Let's move, sweat and stay healthy together! 💃",
        category: 'class',
        isPinned: true,
        isImportant: true,
        createdAt: now,
        isRead: false,
      );

      expect(model.displayTitle, 'Zumba Class Tomorrow');
      expect(model.visuals.label, 'Class / Workout');
      expect(model.isPinned, isTrue);

      final map = model.toMap();
      expect(map['title'], 'Zumba Class Tomorrow');
      expect(map['category'], 'class');
      expect(map['isPinned'], 1);

      final fromMap = ClientAnnouncementModel.fromMap(map, isRead: true);
      expect(fromMap.id, 'client-ann-1');
      expect(fromMap.displayTitle, 'Zumba Class Tomorrow');
      expect(fromMap.isRead, isTrue);
    });

    testWidgets('WelcomeScreen renders key onboarding elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const EliteFitnessClientApp(startWithFeed: false),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('MEMBER PORTAL'), findsOneWidget);
    });
  });
}
