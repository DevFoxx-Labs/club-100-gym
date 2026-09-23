import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSyncService {
  ContactSyncService._();

  /// On Android 14+, some devices reject a new raw contact that has no
  /// explicit account when the device's "default account for new contacts"
  /// is set to a cloud account, throwing from a native background coroutine
  /// that Dart's try/catch can never see. Reusing an account already present
  /// on the device (if any) avoids that no-account code path entirely.
  static Future<Account?> _findDeviceAccount() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: false,
        withAccounts: true,
      );
      for (final c in contacts) {
        if (c.accounts.isNotEmpty) return c.accounts.first;
      }
    } catch (_) {}
    return null;
  }

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

      final account = await _findDeviceAccount();
      if (account != null) {
        contact.accounts = [account];
      }

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

