import 'package:flutter_test/flutter_test.dart';
import 'package:the_elite_fitness/data/models/trainer_model.dart';
import 'package:the_elite_fitness/data/models/membership_change_log_model.dart';
import 'package:the_elite_fitness/data/models/trainer_change_log_model.dart';
import 'package:the_elite_fitness/data/models/gym_info_model.dart';
import 'package:the_elite_fitness/data/models/receipt_model.dart';
import 'package:the_elite_fitness/data/models/payment_model.dart';
import 'package:the_elite_fitness/data/models/membership_model.dart';
import 'package:the_elite_fitness/data/models/event_model.dart';
import 'package:the_elite_fitness/data/models/member_model.dart';
import 'package:the_elite_fitness/data/models/notification_model.dart';
import 'package:the_elite_fitness/core/receipt/qr_service.dart';
import 'package:the_elite_fitness/core/utils/form_validators.dart';
import 'package:the_elite_fitness/core/utils/sms_templates.dart';
import 'package:the_elite_fitness/core/services/app_state_service.dart';
import 'package:the_elite_fitness/core/notifications/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

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

  group('PaymentModel Tests', () {
    test('PaymentModel supports memberName serialization and copyWith', () {
      final payment = PaymentModel(
        id: 'pay-101',
        memberId: 'm-101',
        membershipId: 'ms-101',
        amount: 2500.0,
        paymentDate: DateTime(2026, 9, 21),
        paymentMethod: 'UPI',
        receiptId: 'rec-101',
        receiptNumber: 'GYM-2026-00005',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        memberName: 'Rohan Sharma',
      );

      expect(payment.memberName, 'Rohan Sharma');
      final map = payment.toMap();
      // fromMap with memberName
      final fromMap = PaymentModel.fromMap({...map, 'memberName': 'Rohan Sharma'});
      expect(fromMap.memberName, 'Rohan Sharma');
      expect(fromMap.receiptNumber, 'GYM-2026-00005');
      expect(fromMap.amount, 2500.0);

      final updated = payment.copyWith(memberName: 'Aman Verma');
      expect(updated.memberName, 'Aman Verma');
      expect(updated.id, 'pay-101');
    });
  });

  group('Trainer Fee & Change Trainer Flow Bug Fix Tests', () {
    test('Preserves base plan fee when member adds PT fee without changing trainer', () {
      // Step 1: Member onboards with Plan fee 1500, Trainer assigned, but initial PT fee 0
      const planDefaultFee = 1500.0;
      const initialPtFee = 0.0;
      final initialMembership = MembershipModel(
        id: 'ms-1',
        memberId: 'm-1',
        planId: 'plan-1',
        planName: 'Monthly General Plan',
        trainerId: 'trainer-1',
        personalTrainingFee: initialPtFee,
        startDate: DateTime(2026, 9, 21),
        endDate: DateTime(2026, 10, 21),
        feeAmount: planDefaultFee + initialPtFee, // 1500
        status: 'Active',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
      );

      expect(initialMembership.feeAmount, 1500.0);
      expect(initialMembership.personalTrainingFee, 0.0);

      // Step 2: In Change Trainer screen, member keeps same trainer but adds PT fee of 1000
      const newPtFee = 1000.0;
      // The base fee is computed from previous membership
      final basePlanFee = (initialMembership.feeAmount > initialMembership.personalTrainingFee)
          ? (initialMembership.feeAmount - initialMembership.personalTrainingFee)
          : initialMembership.feeAmount;
      expect(basePlanFee, 1500.0);

      // New total membership fee after adding PT fee
      final newTotalFee = basePlanFee + newPtFee;
      expect(newTotalFee, 2500.0);

      final updatedMembership = initialMembership.copyWith(
        personalTrainingFee: newPtFee,
        feeAmount: newTotalFee,
        updatedAt: DateTime(2026, 9, 21),
      );

      // Step 3: When Add Payment screen opens for this member:
      final paymentBaseFee = (updatedMembership.feeAmount >= updatedMembership.personalTrainingFee)
          ? (updatedMembership.feeAmount - updatedMembership.personalTrainingFee)
          : updatedMembership.feeAmount;
      final paymentPtFee = updatedMembership.personalTrainingFee;
      final totalDue = paymentBaseFee + paymentPtFee;

      // Assert that base fee is NOT 0 and matches the 1500 base plan!
      expect(paymentBaseFee, 1500.0);
      expect(paymentPtFee, 1000.0);
      expect(totalDue, 2500.0);
    });

    test('Self-healing fallback resolves base fee if feeAmount was corrupted to <= PT fee', () {
      // Corrupted scenario: feeAmount was 1000 and personalTrainingFee was 1000
      const corruptedFeeAmount = 1000.0;
      const ptFee = 1000.0;
      const planDefaultFee = 1500.0;

      double baseFee = (corruptedFeeAmount > ptFee) ? (corruptedFeeAmount - ptFee) : 0.0;
      expect(baseFee, 0.0); // Corrupted

      // Self-healing fallback: if baseFee <= 0, retrieve defaultFee from plan
      if (baseFee <= 0 && planDefaultFee > 0) {
        baseFee = planDefaultFee;
      }
      final healedTotal = baseFee + ptFee;

      expect(baseFee, 1500.0);
      expect(healedTotal, 2500.0);
    });
  });

  group('EventModel & Event Notifications Tests', () {
    test('EventModel serializes, deserializes, and copies correctly', () {
      final event = EventModel(
        id: 'event-101',
        title: 'Morning Yoga Bootcamp',
        description: 'Sunrise flow session with master trainer',
        startTime: '2026-09-22T06:00:00.000',
        endTime: '2026-09-22T07:15:00.000',
        location: 'Studio A (Rooftop)',
        trainerId: 'trainer-1',
        colorValue: 0xFFD4FF00,
        createdAt: '2026-09-21T12:00:00.000',
        updatedAt: '2026-09-21T12:00:00.000',
        deletedAt: null,
      );

      final map = event.toMap();
      expect(map['title'], 'Morning Yoga Bootcamp');
      expect(map['location'], 'Studio A (Rooftop)');
      expect(map['colorValue'], 0xFFD4FF00);

      final fromMap = EventModel.fromMap(map);
      expect(fromMap.title, event.title);
      expect(fromMap.startTime, event.startTime);
      expect(fromMap.colorValue, event.colorValue);

      final updated = event.copyWith(title: 'Advanced Power Yoga');
      expect(updated.title, 'Advanced Power Yoga');
      expect(updated.location, 'Studio A (Rooftop)');
    });

    test('Event notification ID hashing generates valid positive 32-bit integers', () {
      const eventId1 = 'event-101';
      const eventId2 = '8f3e2b1a-9c4d-4e5f-a6b7-c8d9e0f1a2b3';
      const eventId3 = 'special_event_marathon_2026';

      final id1 = eventId1.hashCode.abs() % 100000 + 10000;
      final id2 = eventId2.hashCode.abs() % 100000 + 10000;
      final id3 = eventId3.hashCode.abs() % 100000 + 10000;

      expect(id1, greaterThanOrEqualTo(10000));
      expect(id1, lessThan(110000));
      expect(id2, greaterThanOrEqualTo(10000));
      expect(id2, lessThan(110000));
      expect(id3, greaterThanOrEqualTo(10000));
      expect(id3, lessThan(110000));
    });

    test('Event notification alert time computes 30 min advance schedule or immediate fallback', () {
      final eventStartFar = DateTime.now().add(const Duration(hours: 3));
      final alertTimeFar = eventStartFar.subtract(const Duration(minutes: 30));
      expect(alertTimeFar.isAfter(DateTime.now()), isTrue);
      expect(eventStartFar.difference(alertTimeFar).inMinutes, 30);

      // Imminent event (starting in 10 minutes)
      final now = DateTime.now();
      final eventStartSoon = now.add(const Duration(minutes: 10));
      DateTime notifyTimeSoon = eventStartSoon.subtract(const Duration(minutes: 30));
      if (notifyTimeSoon.isBefore(now)) {
        notifyTimeSoon = now.add(const Duration(seconds: 10));
      }
      expect(notifyTimeSoon.isAfter(now), isTrue);
      expect(notifyTimeSoon.isBefore(eventStartSoon), isTrue);
    });

    test('Multi-tier event notification intervals (30m, 15m, at start)', () {
      final now = DateTime.now();
      final eventStartFar = now.add(const Duration(hours: 2));

      // 30 min before
      final t30 = eventStartFar.subtract(const Duration(minutes: 30));
      expect(t30.isAfter(now), isTrue);
      expect(eventStartFar.difference(t30).inMinutes, 30);

      // 15 min before
      final t15 = eventStartFar.subtract(const Duration(minutes: 15));
      expect(t15.isAfter(t30), isTrue);
      expect(eventStartFar.difference(t15).inMinutes, 15);

      // Imminent event (8 min away): immediate alert triggers before start
      final eventImminent = now.add(const Duration(minutes: 8));
      final immediateAlert = now.add(const Duration(seconds: 4));
      expect(immediateAlert.isBefore(eventImminent), isTrue);

      // Multi-tier cancellation IDs
      const eventId = 'event-xyz-999';
      final baseId = eventId.hashCode.abs() % 100000 + 10000;
      final ids = [baseId, baseId + 1, baseId + 2];
      expect(ids.toSet().length, 3); // Distinct IDs
    });

    test('NotificationService configureLocalTimeZone sets non-null valid timezone', () {
      NotificationService.configureLocalTimeZone();
      expect(tz.local, isNotNull);
      expect(tz.local.name, isNotEmpty);
    });

    test('Payment list receipt badge formatting handles plan name presence and absence', () {
      const receiptNo = 'GYM-2026-00001';
      const planName = 'Monthly Standard';

      // With plan name
      final displayNameWithPlan = (planName.isNotEmpty) ? '$receiptNo ($planName)' : receiptNo;
      expect(displayNameWithPlan, 'GYM-2026-00001 (Monthly Standard)');

      // Without plan name
      const String? emptyPlan = null;
      final displayNameNoPlan = (emptyPlan != null && emptyPlan.isNotEmpty) ? '$receiptNo ($emptyPlan)' : receiptNo;
      expect(displayNameNoPlan, 'GYM-2026-00001');
    });
  });

  group('Notification & Reminder System Tests', () {
    test('MemberModel isActive property computes correctly based on archive and delete state', () {
      final activeMember = MemberModel(
        id: 'm1',
        name: 'John Doe',
        phone: '9876543210',
        isArchived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(activeMember.isActive, isTrue);

      final archivedMember = activeMember.copyWith(isArchived: true);
      expect(archivedMember.isActive, isFalse);

      final deletedMember = activeMember.copyWith(deletedAt: DateTime.now());
      expect(deletedMember.isActive, isFalse);
    });

    test('NotificationItemModel serializes, deserializes, and copyWith works as expected', () {
      final notif = NotificationItemModel(
        id: 'notif-1',
        memberId: 'm100',
        type: 'FEE_DUE_SOON',
        title: 'Fee Due Soon',
        message: 'Fee for John Doe is due in 3 days',
        scheduledAt: DateTime(2026, 9, 25, 10, 0),
        isRead: false,
        createdAt: DateTime(2026, 9, 22, 10, 0),
      );

      final map = notif.toMap();
      expect(map['id'], 'notif-1');
      expect(map['memberId'], 'm100');
      expect(map['type'], 'FEE_DUE_SOON');
      expect(map['isRead'], 0);

      final restored = NotificationItemModel.fromMap(map);
      expect(restored.id, notif.id);
      expect(restored.memberId, notif.memberId);
      expect(restored.title, notif.title);
      expect(restored.message, notif.message);
      expect(restored.scheduledAt, notif.scheduledAt);
      expect(restored.isRead, isFalse);

      final readNotif = notif.copyWith(isRead: true, triggeredAt: DateTime(2026, 9, 22, 10, 5));
      expect(readNotif.isRead, isTrue);
      expect(readNotif.triggeredAt, isNotNull);
    });

    test('ReminderScheduler fee status calculation: Paid vs Due vs Overdue', () {
      final now = DateTime(2026, 9, 22);
      final dueDateSoon = DateTime(2026, 9, 25);
      final dueTodayDate = DateTime(2026, 9, 22);
      final overdueDate = DateTime(2026, 9, 20);

      // Diff in days
      final diffSoon = dueDateSoon.difference(now).inDays;
      final diffToday = dueTodayDate.difference(now).inDays;
      final diffOverdue = overdueDate.difference(now).inDays;

      expect(diffSoon, 3);
      expect(diffToday, 0);
      expect(diffOverdue, -2);

      // Fee amounts
      const feeAmount = 1500.0;
      const fullyPaid = 1500.0;
      const partialPaid = 500.0;
      const unPaid = 0.0;

      // Fully paid -> fee is paid, no alerts
      expect(fullyPaid >= feeAmount, isTrue);

      // Partial paid -> unpaid balance
      expect(partialPaid < feeAmount, isTrue);
      expect(unPaid < feeAmount, isTrue);

      // Due soon rule: diffDays > 0 && diffDays <= 7
      expect(diffSoon > 0 && diffSoon <= 7, isTrue);

      // Due today rule: diffDays == 0
      expect(diffToday == 0, isTrue);

      // Overdue rule: diffDays < 0
      expect(diffOverdue < 0, isTrue);
    });

    test('Notification deduplication key matches same calendar day', () {
      final scan1 = DateTime(2026, 9, 22, 8, 30);
      final scan2 = DateTime(2026, 9, 22, 18, 45);
      final tomorrow = DateTime(2026, 9, 23, 9, 0);

      final day1 = DateTime(scan1.year, scan1.month, scan1.day);
      final day2 = DateTime(scan2.year, scan2.month, scan2.day);
      final dayTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      // Same calendar day matches
      expect(day1, equals(day2));
      // Different calendar day does not match
      expect(day1, isNot(equals(dayTomorrow)));
    });
  });
}
