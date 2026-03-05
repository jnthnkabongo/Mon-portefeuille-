enum TransactionType { income, expense }

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.createdAt,
    this.deviceId,
  });

  final int? id;
  final TransactionType type;
  final double amount;
  final String category;
  final String note;
  final DateTime createdAt;
  final int? deviceId;

  FinanceTransaction copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? category,
    String? note,
    DateTime? createdAt,
    int? deviceId,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  String get typeDbValue =>
      type == TransactionType.income ? 'income' : 'expense';

  static TransactionType parseType(String? value) {
    if (value == null || value.isEmpty) {
      return TransactionType.expense;
    }

    switch (value.toLowerCase().trim()) {
      case 'income':
      case 'revenu':
      case 'entrée':
        return TransactionType.income;
      case 'expense':
      case 'dépense':
      case 'sortie':
        return TransactionType.expense;
      default:
        // Si la valeur n'est pas reconnue, on considère que c'est une dépense par défaut
        print(
          'Type de transaction non reconnu: "$value", utilisation de expense par défaut',
        );
        return TransactionType.expense;
    }
  }

  Map<String, Object?> toDbMap() {
    return <String, Object?>{
      if (id != null) 'id': id,
      'type': typeDbValue,
      'amount': amount,
      'category': category,
      'note': note,
      if (deviceId != null) 'device_id': deviceId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static FinanceTransaction fromDbMap(Map<String, Object?> map) {
    return FinanceTransaction(
      id: map['id'] as int?,
      type: parseType(map['type'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: (map['category'] as String?)?.trim() ?? '',
      note: (map['note'] as String?)?.trim() ?? '',
      deviceId: map['device_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }
}
