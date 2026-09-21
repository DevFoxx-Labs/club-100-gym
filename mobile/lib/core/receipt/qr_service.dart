import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/models/receipt_model.dart';

class QrService {
  static String generateQrPayload(ReceiptModel receipt) {
    final rawData = {
      'gym': 'Elite Fitness Gym',
      'recNo': receipt.receiptNumber,
      'member': receipt.memberName,
      'phone': receipt.memberPhone,
      'amount': receipt.amount,
      'date': receipt.paymentDate.toIso8601String().split('T').first,
      'plan': receipt.planName,
    };

    final jsonStr = jsonEncode(rawData);
    final hash = sha256.convert(utf8.encode('$jsonStr:CLUB100SECRET')).toString().substring(0, 12);
    
    rawData['sig'] = hash;
    return jsonEncode(rawData);
  }

  static Map<String, dynamic>? verifyQrPayload(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final sig = data['sig'];
      if (sig == null) return null;

      data.remove('sig');
      final jsonStr = jsonEncode(data);
      final expectedSig = sha256.convert(utf8.encode('$jsonStr:CLUB100SECRET')).toString().substring(0, 12);

      if (sig == expectedSig) {
        data['isValid'] = true;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

