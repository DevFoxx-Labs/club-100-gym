class ExpenseCategories {
  static const List<String> all = [
    'Rent',
    'Utilities',
    'Salaries & Wages',
    'Equipment',
    'Maintenance',
    'Marketing',
    'Supplies',
    'Insurance',
    'Other',
  ];
}

class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.title,
    this.category = 'Other',
    required this.amount,
    required this.expenseDate,
    this.paymentMethod = 'Cash',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: map['expenseDate'] != null ? DateTime.parse(map['expenseDate']) : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  ExpenseModel copyWith({
    String? title,
    String? category,
    double? amount,
    DateTime? expenseDate,
    String? paymentMethod,
    String? notes,
    bool clearNotes = false,
  }) {
    return ExpenseModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
