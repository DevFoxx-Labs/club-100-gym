import 'package:flutter_test/flutter_test.dart';
import 'package:club_100_gym_app/data/models/trainer_model.dart';
import 'package:club_100_gym_app/data/models/membership_change_log_model.dart';
import 'package:club_100_gym_app/data/models/trainer_change_log_model.dart';
import 'package:club_100_gym_app/core/utils/sms_templates.dart';

void main() {
  group('TrainerModel Tests', () {
    test('TrainerModel supports photoPath serialization and copyWith', () {
      final trainer = TrainerModel(
        id: 't-1',
        name: 'Arjun Verma',
        phone: '9876543210',
        specialization: 'Strength & Conditioning',
        monthlySalary: 30000.0,
        photoPath: '/data/user/0/com.club100gym.club_100_gym_app/app_flutter/trainer_photos/arjun.jpg',
        isActive: true,
        createdAt: '2026-01-01T00:00:00.000',
        updatedAt: '2026-01-01T00:00:00.000',
      );

      final map = trainer.toMap();
      expect(map['photoPath'], '/data/user/0/com.club100gym.club_100_gym_app/app_flutter/trainer_photos/arjun.jpg');
      expect(map['name'], 'Arjun Verma');
      expect(trainer.speciality, 'Strength & Conditioning');

      final fromMap = TrainerModel.fromMap(map);
      expect(fromMap.photoPath, trainer.photoPath);
      expect(fromMap.monthlySalary, 30000.0);

      final updated = trainer.copyWith(photoPath: '/new/path/arjun_updated.jpg');
      expect(updated.photoPath, '/new/path/arjun_updated.jpg');
      expect(updated.name, 'Arjun Verma');
    });
  });

  group('Change Log Models Tests', () {
    test('MembershipChangeLogModel getters work as expected', () {
      final log = MembershipChangeLogModel(
        id: 'log-1',
        memberId: 'm-1',
        previousMembershipId: 'prev-1',
        newMembershipId: 'new-1',
        previousPlanNameSnapshot: 'Monthly Plan',
        newPlanNameSnapshot: 'Quarterly Pro Plan',
        previousFeeAmount: 1500.0,
        newFeeAmount: 3999.0,
        reason: 'Upgrade to Quarterly',
        changedAt: '2026-09-21T10:00:00.000',
      );

      expect(log.previousPlanName, 'Monthly Plan');
      expect(log.newPlanName, 'Quarterly Pro Plan');
      expect(log.newFee, 3999.0);
      expect(log.effectiveDate.year, 2026);
    });

    test('TrainerChangeLogModel getters work as expected', () {
      final log = TrainerChangeLogModel(
        id: 'tlog-1',
        memberId: 'm-1',
        previousTrainerNameSnapshot: 'Laksham',
        newTrainerNameSnapshot: 'Arjun',
        previousPersonalTrainingFee: 2000.0,
        newPersonalTrainingFee: 3000.0,
        reason: 'Trainer requested transfer',
        changedAt: '2026-09-21T10:00:00.000',
      );

      expect(log.previousTrainerName, 'Laksham');
      expect(log.newTrainerName, 'Arjun');
      expect(log.newPersonalTrainingFee, 3000.0);
      expect(log.changedAtDate.year, 2026);
    });
  });

  group('SmsTemplates Tests', () {
    test('Formats fee overdue and due today correctly', () {
      final overdue = SmsTemplates.feeOverdue(
        gymName: 'Club 100 The Gym',
        memberName: 'Rahul',
        amountDue: 1500,
        daysOverdue: 5,
      );
      expect(overdue, contains('Rahul'));
      expect(overdue, contains('₹1500'));
      expect(overdue, contains('Club 100 The Gym'));
      expect(overdue, contains('5 days'));

      final dueToday = SmsTemplates.feeDueToday(
        gymName: 'Club 100 The Gym',
        memberName: 'Rahul',
        amount: 1500,
      );
      expect(dueToday, contains('due today'));
    });
  });
}

