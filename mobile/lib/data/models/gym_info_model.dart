class GymInfoModel {
  final String id;
  final String name;
  final String? ownerName;
  final String phone;
  final String? email;
  final String? website;
  final String address;
  final String? city;
  final String? logoPath;
  final String currency;
  final String? upiId;
  final String? upiPayeeName;
  final String? bankAccountHolder;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankName;
  final bool showUpiQrOnBill;
  final bool showBankDetailsOnBill;

  /// Name of the [PrintFormat] enum value to use by default when printing/sharing
  /// bills and receipts (e.g. 'thermal58', 'a5'). Null means "always ask".
  final String? defaultPrintFormat;
  final DateTime createdAt;
  final DateTime updatedAt;

  GymInfoModel({
    required this.id,
    required this.name,
    this.ownerName,
    required this.phone,
    this.email,
    this.website,
    required this.address,
    this.city,
    this.logoPath,
    required this.currency,
    this.upiId,
    this.upiPayeeName,
    this.bankAccountHolder,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankName,
    this.showUpiQrOnBill = true,
    this.showBankDetailsOnBill = true,
    this.defaultPrintFormat,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True once the admin has configured a usable UPI VPA to receive payments.
  bool get hasUpiConfigured => upiId != null && upiId!.trim().isNotEmpty;

  /// True once at least the account number and IFSC are configured for bank transfers.
  bool get hasBankDetailsConfigured =>
      (bankAccountNumber != null && bankAccountNumber!.trim().isNotEmpty) &&
      (bankIfsc != null && bankIfsc!.trim().isNotEmpty);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'logoPath': logoPath,
      'currency': currency,
      'upiId': upiId,
      'upiPayeeName': upiPayeeName,
      'bankAccountHolder': bankAccountHolder,
      'bankAccountNumber': bankAccountNumber,
      'bankIfsc': bankIfsc,
      'bankName': bankName,
      'showUpiQrOnBill': showUpiQrOnBill ? 1 : 0,
      'showBankDetailsOnBill': showBankDetailsOnBill ? 1 : 0,
      'defaultPrintFormat': defaultPrintFormat,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GymInfoModel.fromMap(Map<String, dynamic> map) {
    return GymInfoModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Elite Fitness Gym',
      ownerName: map['ownerName'],
      phone: map['phone'] ?? '',
      email: map['email'],
      website: map['website'],
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      logoPath: map['logoPath'],
      currency: map['currency'] ?? 'INR (₹)',
      upiId: map['upiId'],
      upiPayeeName: map['upiPayeeName'],
      bankAccountHolder: map['bankAccountHolder'],
      bankAccountNumber: map['bankAccountNumber'],
      bankIfsc: map['bankIfsc'],
      bankName: map['bankName'],
      showUpiQrOnBill: (map['showUpiQrOnBill'] ?? 1) == 1,
      showBankDetailsOnBill: (map['showBankDetailsOnBill'] ?? 1) == 1,
      defaultPrintFormat: map['defaultPrintFormat'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  GymInfoModel copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? city,
    String? logoPath,
    String? currency,
    String? upiId,
    String? upiPayeeName,
    String? bankAccountHolder,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankName,
    bool? showUpiQrOnBill,
    bool? showBankDetailsOnBill,
    String? defaultPrintFormat,
    bool clearDefaultPrintFormat = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GymInfoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      logoPath: logoPath ?? this.logoPath,
      currency: currency ?? this.currency,
      upiId: upiId ?? this.upiId,
      upiPayeeName: upiPayeeName ?? this.upiPayeeName,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankName: bankName ?? this.bankName,
      showUpiQrOnBill: showUpiQrOnBill ?? this.showUpiQrOnBill,
      showBankDetailsOnBill: showBankDetailsOnBill ?? this.showBankDetailsOnBill,
      defaultPrintFormat: clearDefaultPrintFormat ? null : (defaultPrintFormat ?? this.defaultPrintFormat),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
