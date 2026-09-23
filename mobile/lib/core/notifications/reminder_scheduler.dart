import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../services/app_state_service.dart';
import 'notification_service.dart';

class _ReminderRule {
  final String type;
  final String title;
  final String Function(String memberName, double feeAmount, int days) message;
  const _ReminderRule(this.type, this.title, this.message);
}

/// Offline-first reminder scheduler for member fee dues, overdues, and membership expirations.
/// Scans on app launch, on foreground resume, and on membership/payment mutations.
/// Records each alert in SQLite and triggers local notifications on the device.
class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._internal();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._internal();

  final MemberRepository _memberRepo = MemberRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final NotificationService _notificationService = NotificationService();
  final BillRepository _billRepo = BillRepository();

  bool _isScanning = false;

  Future<void> runDailyScan({DateTime? referenceDate}) async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final now = referenceDate ?? DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final settings = await _settingsRepo.getNotificationSettings();
      final members = await _memberRepo.getMembers();

      for (final member in members) {
        if (!member.isActive || member.deletedAt != null) continue;

        final membership = await _memberRepo.getLatestMembership(member.id);
        if (membership == null) continue;

        final endDate = DateTime(
          membership.endDate.year,
          membership.endDate.month,
          membership.endDate.day,
        );
        final daysUntilEnd = endDate.difference(today).inDays;

        // 1. Fee Payment Status
        final totalPaid = await _paymentRepo.getTotalPaidForMembership(membership.id);
        final isPaidInFull = totalPaid >= membership.feeAmount;

        if (!isPaidInFull) {
          final feeRule = _evaluateFeeRule(daysUntilEnd, settings);
          if (feeRule != null) {
            await _raiseReminder(
              member: member,
              membership: membership,
              rule: feeRule,
              days: daysUntilEnd,
              today: today,
            );
          }
        }

        // 2. Membership Expiration Status (even if fees were settled)
        final expiryRule = _evaluateExpiryRule(daysUntilEnd, settings);
        if (expiryRule != null) {
          await _raiseReminder(
            member: member,
            membership: membership,
            rule: expiryRule,
            days: daysUntilEnd,
            today: today,
          );
        }

        // 3. Auto-generate the renewal bill one day before membership expiry
        if (daysUntilEnd == 1) {
          await _autoGenerateRenewalBill(member: member, membership: membership);
        }
      }

      await _billRepo.refreshOverdueStatuses(referenceDate: today);
    } catch (e, stack) {
      debugPrint('ReminderScheduler.runDailyScan error: $e\n$stack');
    } finally {
      _isScanning = false;
    }
  }

  Future<void> _raiseReminder({
    required MemberModel member,
    required MembershipModel membership,
    required _ReminderRule rule,
    required int days,
    required DateTime today,
  }) async {
    final message = rule.message(member.name, membership.feeAmount, days);
    final notificationId = await _notificationRepo.recordIfNew(
      memberId: member.id,
      type: rule.type,
      title: rule.title,
      message: message,
      scheduledAt: today,
    );

    // If already recorded today, suppress duplicate push
    if (notificationId == null) return;

    // Trigger local push notification on the device
    final notifIntId = (notificationId.hashCode.abs() % 100000) + 20000;
    await _notificationService.showNotification(
      id: notifIntId,
      title: rule.title,
      body: message,
      payload: 'member:${member.id}',
    );

    AppStateService.instance.notifyNotificationsChanged();
  }

  /// Auto-generates the next bill for a membership's upcoming renewal/expiry,
  /// guarded against duplicates for the same billing cycle.
  Future<void> _autoGenerateRenewalBill({
    required MemberModel member,
    required MembershipModel membership,
  }) async {
    final alreadyExists = await _billRepo.billExistsForCycle(membership.id, membership.endDate);
    if (alreadyExists) return;

    final now = DateTime.now();
    const uuid = Uuid();
    final bill = BillModel(
      id: uuid.v4(),
      billNumber: await _billRepo.generateNextBillNumber(),
      memberId: member.id,
      memberName: member.name,
      memberPhone: member.phone,
      membershipId: membership.id,
      planName: membership.planName,
      amount: membership.feeAmount,
      billDate: now,
      dueDate: membership.endDate,
      status: 'Pending',
      isAutoGenerated: true,
      cycleKey: BillRepository.cycleKeyFor(membership.id, membership.endDate),
      createdAt: now,
      updatedAt: now,
    );
    await _billRepo.createBill(bill);
    AppStateService.instance.notifyBillsChanged();
  }

  _ReminderRule? _evaluateFeeRule(int daysUntilEnd, Map<String, bool> settings) {
    if (daysUntilEnd < 0 && (settings['feeOverdue'] ?? true)) {
      return _ReminderRule(
        'FEE_OVERDUE',
        'Fee Overdue',
        (name, amount, days) => "$name's fee of ₹${amount.toStringAsFixed(0)} is overdue by ${days.abs()} days.",
      );
    }
    if (daysUntilEnd == 0 && (settings['feeDue'] ?? true)) {
      return _ReminderRule(
        'FEE_DUE_TODAY',
        'Fee Due Today',
        (name, amount, days) => "$name's fee of ₹${amount.toStringAsFixed(0)} is due today.",
      );
    }
    if (daysUntilEnd == 1 && (settings['fee1d'] ?? true)) {
      return _ReminderRule(
        'FEE_DUE_SOON',
        'Fee Due Tomorrow',
        (name, amount, days) => "$name's fee of ₹${amount.toStringAsFixed(0)} is due tomorrow.",
      );
    }
    if (daysUntilEnd == 3 && (settings['fee3d'] ?? true)) {
      return _ReminderRule(
        'FEE_DUE_SOON',
        'Fee Due in 3 Days',
        (name, amount, days) => "$name's fee of ₹${amount.toStringAsFixed(0)} is due in 3 days.",
      );
    }
    if (daysUntilEnd == 7 && (settings['fee7d'] ?? true)) {
      return _ReminderRule(
        'FEE_DUE_SOON',
        'Fee Due in 7 Days',
        (name, amount, days) => "$name's fee of ₹${amount.toStringAsFixed(0)} is due in 7 days.",
      );
    }
    if (daysUntilEnd > 0 && daysUntilEnd <= 7 && (settings['fee7d'] ?? true)) {
      return _ReminderRule(
        'FEE_DUE_SOON',
        'Fee Due in $daysUntilEnd Days',
        (name, amount, days) => "$name's fee of ₹${amount.toStringAsFixed(0)} is due in $days days.",
      );
    }
    return null;
  }

  _ReminderRule? _evaluateExpiryRule(int daysUntilEnd, Map<String, bool> settings) {
    if (daysUntilEnd < 0 && (settings['expiry1d'] ?? true)) {
      return _ReminderRule(
        'MEMBERSHIP_EXPIRED',
        'Membership Expired',
        (name, amount, days) => "$name's gym membership expired ${days.abs()} days ago.",
      );
    }
    if (daysUntilEnd == 0 && (settings['expiry1d'] ?? true)) {
      return _ReminderRule(
        'MEMBERSHIP_EXPIRING',
        'Membership Expiring Today',
        (name, amount, days) => "$name's gym membership expires today.",
      );
    }
    if (daysUntilEnd == 1 && (settings['expiry1d'] ?? true)) {
      return _ReminderRule(
        'MEMBERSHIP_EXPIRING',
        'Membership Expiring Tomorrow',
        (name, amount, days) => "$name's gym membership expires tomorrow.",
      );
    }
    if (daysUntilEnd == 3 && (settings['expiry3d'] ?? true)) {
      return _ReminderRule(
        'MEMBERSHIP_EXPIRING',
        'Membership Expiring in 3 Days',
        (name, amount, days) => "$name's gym membership expires in 3 days.",
      );
    }
    if (daysUntilEnd == 7 && (settings['expiry7d'] ?? true)) {
      return _ReminderRule(
        'MEMBERSHIP_EXPIRING',
        'Membership Expiring in 7 Days',
        (name, amount, days) => "$name's gym membership expires in 7 days.",
      );
    }
    if (daysUntilEnd > 0 && daysUntilEnd <= 7 && (settings['expiry7d'] ?? true)) {
      return _ReminderRule(
        'MEMBERSHIP_EXPIRING',
        'Membership Expiring in $daysUntilEnd Days',
        (name, amount, days) => "$name's gym membership expires in $days days.",
      );
    }
    return null;
  }
}

