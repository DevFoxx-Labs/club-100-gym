class GymInfoModel {
  final String id;
  final String name;
  final String? ownerName;
  final String phone;
  final String? email;
  final String address;
  final String? city;
  final String? logoPath;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  GymInfoModel({
    required this.id,
    required this.name,
    this.ownerName,
    required this.phone,
    this.email,
    required this.address,
    this.city,
    this.logoPath,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'logoPath': logoPath,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GymInfoModel.fromMap(Map<String, dynamic> map) {
    return GymInfoModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Club 100 The Gym',
      ownerName: map['ownerName'],
      phone: map['phone'] ?? '070843 06574',
      email: map['email'],
      address: map['address'] ?? 'Transport Nagar, Prayagraj',
      city: map['city'] ?? 'Prayagraj',
      logoPath: map['logoPath'],
      currency: map['currency'] ?? 'INR (₹)',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }
}

