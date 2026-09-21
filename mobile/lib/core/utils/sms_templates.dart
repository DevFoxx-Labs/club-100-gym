import 'package:intl/intl.dart';

class SmsTemplates {
  SmsTemplates._();

  static String feeReminder({
    required String gymName,
    required String memberName,
    double? amountDue,
    double? amount,
    DateTime? dueDate,
  }) {
    final effectiveAmount = amount ?? amountDue ?? 0;
    final amountStr = '₹${effectiveAmount.toStringAsFixed(0)}';
    final due = dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : 'soon';
    return 'Dear $memberName, your gym fee of $amountStr at $gymName is due on $due. '
        'Please pay at your earliest convenience to continue your workout sessions. Thank you!';
  }

  static String feeDueSoon({
    required String gymName,
    required String memberName,
    int daysLeft = 3,
    double? amount,
    double? amountDue,
  }) {
    final effectiveAmount = amount ?? amountDue ?? 0;
    final amountStr = '₹${effectiveAmount.toStringAsFixed(0)}';
    return 'Dear $memberName, your gym fee of $amountStr at $gymName is due in $daysLeft days. '
        'Please renew on time to avoid interruption. Thank you!';
  }

  static String feeDueToday({
    required String gymName,
    required String memberName,
    double? amountDue,
    double? amount,
  }) {
    final effectiveAmount = amount ?? amountDue ?? 0;
    final amountStr = '₹${effectiveAmount.toStringAsFixed(0)}';
    return 'Hello $memberName, this is a reminder that your membership fee of $amountStr at $gymName is due today. '
        'Please visit the desk to complete payment. Thank you!';
  }

  static String feeOverdue({
    required String gymName,
    required String memberName,
    double? amountDue,
    double? amount,
    int? daysOverdue,
  }) {
    final effectiveAmount = amount ?? amountDue ?? 0;
    final amountStr = '₹${effectiveAmount.toStringAsFixed(0)}';
    final overdueStr = daysOverdue != null ? 'by $daysOverdue days' : '';
    return 'Urgent: Dear $memberName, your gym fee of $amountStr at $gymName is overdue $overdueStr. '
        'Please clear your pending dues today to avoid membership interruption. Thank you!';
  }

  static String membershipExpiry({
    required String gymName,
    required String memberName,
    dynamic expiryDate,
  }) {
    String expiry = 'soon';
    if (expiryDate is DateTime) {
      expiry = DateFormat('dd MMM yyyy').format(expiryDate);
    } else if (expiryDate is String) {
      expiry = expiryDate;
    }
    return 'Dear $memberName, your membership at $gymName will expire on $expiry. '
        'Renew now to maintain uninterrupted access to all workout zones!';
  }

  static String paymentReceipt({
    required String gymName,
    required String memberName,
    required String receiptNumber,
    required double amount,
    dynamic date,
  }) {
    final amountStr = '₹${amount.toStringAsFixed(0)}';
    return 'Dear $memberName, payment of $amountStr received with thanks at $gymName. '
        'Receipt No: $receiptNumber. Stay strong and keep training!';
  }

  static String paymentConfirmation({
    required String gymName,
    required String memberName,
    required double amountPaid,
    required String receiptNumber,
  }) => paymentReceipt(gymName: gymName, memberName: memberName, receiptNumber: receiptNumber, amount: amountPaid);

  static String welcomeMessage({
    required String gymName,
    required String memberName,
    String? planName,
  }) {
    final plan = planName != null ? ' for $planName' : '';
    return 'Welcome to $gymName, $memberName! Your membership$plan is now active. '
        'Let\'s achieve your fitness goals together!';
  }

  static String welcomeMember({
    required String gymName,
    required String memberName,
    required String planName,
  }) => welcomeMessage(gymName: gymName, memberName: memberName, planName: planName);
}
