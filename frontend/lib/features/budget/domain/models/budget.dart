class Budget {
  final String id;
  final int amountPaise;
  final String currency;
  final int month;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Budget({
    required this.id,
    required this.amountPaise,
    required this.currency,
    required this.month,
    required this.year,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    if (now.year == year && now.month == month) {
      final remaining = lastDayOfMonth - now.day;
      return remaining >= 0 ? remaining : 0;
    }
    // If future or past month
    final lastDay = DateTime(year, month, lastDayOfMonth);
    if (now.isBefore(startDate)) {
      return lastDayOfMonth;
    } else if (now.isAfter(lastDay)) {
      return 0;
    }
    return 0;
  }

  double usageRatio(int totalSpendPaise) {
    if (amountPaise <= 0) return 0.0;
    return (totalSpendPaise / amountPaise).clamp(0.0, 1.0);
  }

  int remainingPaise(int totalSpendPaise) {
    final rem = amountPaise - totalSpendPaise;
    return rem >= 0 ? rem : 0;
  }

  int dailySafeSpendPaise(int totalSpendPaise) {
    final days = daysRemaining;
    if (days <= 0) return remainingPaise(totalSpendPaise);
    return (remainingPaise(totalSpendPaise) / days).round();
  }

  Budget copyWith({
    String? id,
    int? amountPaise,
    String? currency,
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      amountPaise: amountPaise ?? this.amountPaise,
      currency: currency ?? this.currency,
      month: month ?? this.month,
      year: year ?? this.year,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    final amount = json['amountMinor'] is num
        ? (json['amountMinor'] as num).toInt()
        : (json['amountPaise'] is num
            ? (json['amountPaise'] as num).toInt()
            : 0);

    return Budget(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      amountPaise: amount,
      currency: (json['currency'] ?? 'INR').toString(),
      month: json['month'] is num
          ? (json['month'] as num).toInt()
          : DateTime.now().month,
      year: json['year'] is num
          ? (json['year'] as num).toInt()
          : DateTime.now().year,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amountMinor': amountPaise,
      'currency': currency,
      'month': month,
      'year': year,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
