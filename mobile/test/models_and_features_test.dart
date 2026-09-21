import 'package:flutter_test/flutter_test.dart';
import 'package:club_100_gym_app/data/models/trainer_model.dart';
import 'package:club_100_gym_app/data/models/membership_change_log_model.dart';
import 'package:club_100_gym_app/data/models/trainer_change_log_model.dart';
import 'package:club_100_gym_app/data/models/gym_info_model.dart';
import 'package:club_100_gym_app/data/models/receipt_model.dart';
import 'package:club_100_gym_app/core/receipt/qr_service.dart';
import 'package:club_100_gym_app/core/utils/form_validators.dart';
import 'package:club_100_gym_app/core/utils/sms_templates.dart';
import 'package:club_100_gym_app/core/services/app_state_service.dart';

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

  group('GymInfoModel Tests', () {
    test('GymInfoModel serializes and deserializes website correctly', () {
      final gym = GymInfoModel(
        id: 'default',
        name: 'Elite Fitness Gym',
        phone: '9876543210',
        website: 'https://elitefitnessgym.com',
        address: '123 Main St',
        currency: 'INR (₹)',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final map = gym.toMap();
      expect(map['website'], 'https://elitefitnessgym.com');

      final fromMap = GymInfoModel.fromMap(map);
      expect(fromMap.website, 'https://elitefitnessgym.com');

      final updated = gym.copyWith(website: 'elitefitness.com');
      expect(updated.website, 'elitefitness.com');
    });
  });

  group('ReceiptModel & Personal Training Fees Tests', () {
    test('ReceiptModel serializes trainerName and personalTrainingFee', () {
      final receipt = ReceiptModel(
        id: 'rec-1',
        paymentId: 'pay-1',
        receiptNumber: 'REC-2026-0001',
        memberName: 'Rahul Sharma',
        memberPhone: '9876543210',
        planName: 'Monthly Plan',
        trainerName: 'Vikram Singh',
        personalTrainingFee: 2500.0,
        amount: 4000.0,
        paymentMethod: 'UPI',
        paymentDate: DateTime(2026, 9, 21),
        startDate: DateTime(2026, 9, 21),
        endDate: DateTime(2026, 10, 21),
        qrPayload: 'test-payload',
        createdAt: DateTime(2026, 9, 21),
      );

      final map = receipt.toMap();
      expect(map['trainerName'], 'Vikram Singh');
      expect(map['personalTrainingFee'], 2500.0);

      final fromMap = ReceiptModel.fromMap(map);
      expect(fromMap.trainerName, 'Vikram Singh');
      expect(fromMap.personalTrainingFee, 2500.0);

      // Base Plan Fee = Total (4000) - PT (2500) = 1500
      final baseFee = fromMap.amount - fromMap.personalTrainingFee;
      expect(baseFee, 1500.0);
    });

    test('QrService encodes and validates personal training details', () {
      final receipt = ReceiptModel(
        id: 'rec-2',
        paymentId: 'pay-2',
        receiptNumber: 'REC-2026-0002',
        memberName: 'Anita Roy',
        memberPhone: '9876543211',
        planName: 'Quarterly Pro Plan',
        trainerName: 'Priya Patel',
        personalTrainingFee: 3000.0,
        amount: 6999.0,
        paymentMethod: 'Cash',
        paymentDate: DateTime(2026, 9, 21),
        startDate: DateTime(2026, 9, 21),
        endDate: DateTime(2026, 12, 21),
        qrPayload: '',
        createdAt: DateTime(2026, 9, 21),
      );

      final payload = QrService.generateQrPayload(receipt);
      expect(payload, contains('Priya Patel'));
      expect(payload, contains('3000'));

      final verified = QrService.verifyQrPayload(payload);
      expect(verified, isNotNull);
      expect(verified!['isValid'], isTrue);
      expect(verified['trainer'], 'Priya Patel');
      expect(verified['ptFee'], 3000.0);
    });
  });

  group('FormValidators Tests', () {
    test('validateName validates minimum characters and required state', () {
      expect(FormValidators.validateName(null), isNotNull);
      expect(FormValidators.validateName(''), isNotNull);
      expect(FormValidators.validateName('   '), isNotNull);
      expect(FormValidators.validateName('A'), isNotNull);
      expect(FormValidators.validateName('John'), isNull);
    });

    test('validatePhone validates numeric and digit count', () {
      expect(FormValidators.validatePhone(null), isNotNull);
      expect(FormValidators.validatePhone('12345'), isNotNull);
      expect(FormValidators.validatePhone('9876543210'), isNull);
      expect(FormValidators.validatePhone('+91 98765 43210'), isNull);
    });

    test('validateEmail validates format when provided', () {
      expect(FormValidators.validateEmail(null), isNull); // Optional
      expect(FormValidators.validateEmail(''), isNull); // Optional
      expect(FormValidators.validateEmail('invalid-email'), isNotNull);
      expect(FormValidators.validateEmail('test@gym.com'), isNull);
    });

    test('validateWebsite validates URLs and domain formats', () {
      expect(FormValidators.validateWebsite(null), isNull); // Optional
      expect(FormValidators.validateWebsite(''), isNull); // Optional
      expect(FormValidators.validateWebsite('not a website'), isNotNull);
      expect(FormValidators.validateWebsite('elitefitnessgym.com'), isNull);
      expect(FormValidators.validateWebsite('www.elitefitnessgym.com'), isNull);
      expect(FormValidators.validateWebsite('https://elitefitnessgym.com'), isNull);
      expect(FormValidators.validateWebsite('http://gym.in/club'), isNull);
    });

    test('validateAmount validates positive numbers', () {
      expect(FormValidators.validateAmount(null), isNotNull);
      expect(FormValidators.validateAmount('abc'), isNotNull);
      expect(FormValidators.validateAmount('-100'), isNotNull);
      expect(FormValidators.validateAmount('0', allowZero: false), isNotNull);
      expect(FormValidators.validateAmount('0', allowZero: true), isNull);
      expect(FormValidators.validateAmount('1500'), isNull);
      expect(FormValidators.validateAmount('2500.50'), isNull);
    });

    test('validateMpin validates numeric digits', () {
      expect(FormValidators.validateMpin('12'), isNotNull);
      expect(FormValidators.validateMpin('abcd'), isNotNull);
      expect(FormValidators.validateMpin('1234'), isNull);
      expect(FormValidators.validateMpin('123456'), isNull);
    });
  });

  group('AppStateService Tests', () {
    test('Notifies listeners on app state events', () {
      final service = AppStateService.instance;
      int callCount = 0;
      void listener() => callCount++;

      service.addListener(listener);
      service.notifyGymInfoChanged();
      expect(callCount, 1);
      expect(service.lastEventType, AppStateEventType.gymInfoChanged);

      service.notifyPaymentsChanged();
      expect(callCount, 2);
      expect(service.lastEventType, AppStateEventType.paymentsChanged);

      service.notifyMembersChanged();
      expect(callCount, 3);
      expect(service.lastEventType, AppStateEventType.membersChanged);

      service.removeListener(listener);
      service.notifyTrainersChanged();
      expect(callCount, 3); // Removed listener should not trigger
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
        gymName: 'Elite Fitness Gym',
        memberName: 'Rahul',
        amountDue: 1500,
        daysOverdue: 5,
      );
      expect(overdue, contains('Rahul'));
      expect(overdue, contains('₹1500'));
      expect(overdue, contains('Elite Fitness Gym'));
      expect(overdue, contains('5 days'));

      final dueToday = SmsTemplates.feeDueToday(
        gymName: 'Elite Fitness Gym',
        memberName: 'Rahul',
        amount: 1500,
      );
      expect(dueToday, contains('due today'));
    });
  });
}
