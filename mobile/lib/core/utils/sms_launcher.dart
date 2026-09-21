import 'package:url_launcher/url_launcher.dart';

class SmsLauncher {
  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        // Fallback for some device URI handlers
        final fallbackUri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
        return await launchUrl(fallbackUri);
      }
    } catch (e) {
      return false;
    }
  }

  static String getFeeReminderTemplate({
    required String memberName,
    required String gymName,
    required int dueDays,
    required double amount,
  }) {
    if (dueDays == 0) {
      return "Hi $memberName, your membership fee of ₹${amount.toStringAsFixed(0)} for $gymName is DUE TODAY. Please pay to keep training uninterrupted!";
    } else if (dueDays < 0) {
      return "Hi $memberName, your membership fee of ₹${amount.toStringAsFixed(0)} for $gymName is OVERDUE by ${dueDays.abs()} days. Kindly renew at the earliest.";
    } else {
      return "Hi $memberName, friendly reminder that your membership fee of ₹${amount.toStringAsFixed(0)} for $gymName is due in $dueDays days. Thank you!";
    }
  }

  static String getPaymentConfirmationTemplate({
    required String memberName,
    required String gymName,
    required String receiptNumber,
    required double amount,
  }) {
    return "Hi $memberName, payment of ₹${amount.toStringAsFixed(0)} received successfully at $gymName. Receipt No: $receiptNumber. Thank you!";
  }
}

