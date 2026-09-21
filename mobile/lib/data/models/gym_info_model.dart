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
      'website': website,
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
      name: map['name'] ?? 'Elite Fitness Gym',
      ownerName: map['ownerName'],
      phone: map['phone'] ?? '',
      email: map['email'],
      website: map['website'],
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      logoPath: map['logoPath'],
      currency: map['currency'] ?? 'INR (₹)',
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
