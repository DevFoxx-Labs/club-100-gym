/// Builds and validates UPI ("Unified Payments Interface") deep-link payloads
/// used to render pay-by-QR codes on bills. Any UPI app (GPay, PhonePe, Paytm,
/// BHIM, bank apps) can scan the resulting QR and will pre-fill the payee,
/// amount, and a reference note automatically.
class UpiService {
  UpiService._();

  static final RegExp _upiIdRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');

  /// Validates a UPI VPA (Virtual Payment Address) such as `gymname@okhdfcbank`.
  static bool isValidUpiId(String? upiId) {
    if (upiId == null || upiId.trim().isEmpty) return false;
    return _upiIdRegex.hasMatch(upiId.trim());
  }

  /// Builds a standard `upi://pay` deep link with the amount pre-filled so
  /// any UPI app scanning the bill's QR opens directly to the payment screen.
  static String buildPaymentUri({
    required String upiId,
    required String payeeName,
    required double amount,
    String? note,
    String? transactionRefId,
  }) {
    final params = <String, String>{
      'pa': upiId.trim(),
      'pn': payeeName.trim().isNotEmpty ? payeeName.trim() : 'Gym',
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      if (note != null && note.trim().isNotEmpty) 'tn': note.trim(),
      if (transactionRefId != null && transactionRefId.trim().isNotEmpty) 'tr': transactionRefId.trim(),
    };

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'upi://pay?$query';
  }
}
