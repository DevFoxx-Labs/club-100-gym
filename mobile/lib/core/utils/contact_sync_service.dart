import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSyncService {
  ContactSyncService._();

  static Future<bool> addMemberContact({
    required String name,
    required String phone,
  }) async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: false);
      if (!granted) return false;

      final contact = Contact()
        ..name = Name(first: name)
        ..phones = [Phone(phone)];
      await contact.insert();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> syncMemberToContacts(dynamic member) async {
    return await addMemberContact(name: member.name, phone: member.phone);
  }
}

