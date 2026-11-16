import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int totalSpendPaise;
  final int transactionCount;
  final bool isDefault;
  final int? monthlyLimitPaise;
  final bool isRecurring;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.totalSpendPaise = 0,
    this.transactionCount = 0,
    this.isDefault = true,
    this.monthlyLimitPaise,
    this.isRecurring = true,
  });

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    int? totalSpendPaise,
    int? transactionCount,
    bool? isDefault,
    int? monthlyLimitPaise,
    bool? isRecurring,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      totalSpendPaise: totalSpendPaise ?? this.totalSpendPaise,
      transactionCount: transactionCount ?? this.transactionCount,
      isDefault: isDefault ?? this.isDefault,
      monthlyLimitPaise: monthlyLimitPaise ?? this.monthlyLimitPaise,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: parseIcon(json['icon']?.toString()),
      color: parseColor(json['color']),
      isDefault: json['isDefault'] == true,
      totalSpendPaise: json['totalSpendPaise'] is num
          ? (json['totalSpendPaise'] as num).toInt()
          : 0,
      transactionCount: json['transactionCount'] is num
          ? (json['transactionCount'] as num).toInt()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': colorToHex(color),
      'icon': iconToKey(icon),
    };
  }

  static IconData parseIcon(String? key) {
    switch (key) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping_cart':
      case 'local_mall':
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'local_taxi':
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      case 'subscriptions':
      case 'receipt_long':
        return Icons.subscriptions_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'menu_book':
      case 'school':
        return Icons.menu_book_outlined;
      case 'card_giftcard':
      case 'featured_seasonal_and_gifts':
        return Icons.card_giftcard_outlined;
      case 'savings':
        return Icons.savings_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'payments':
      case 'more_horiz':
      default:
        return Icons.category_outlined;
    }
  }

  static String iconToKey(IconData icon) {
    if (icon == Icons.fitness_center_outlined ||
        icon == Icons.fitness_center) {
      return 'fitness_center';
    }
    if (icon == Icons.pets_outlined || icon == Icons.pets) {
      return 'pets';
    }
    if (icon == Icons.menu_book_outlined ||
        icon == Icons.menu_book ||
        icon == Icons.school_outlined ||
        icon == Icons.school) {
      return 'menu_book';
    }
    if (icon == Icons.flight_outlined || icon == Icons.flight) {
      return 'flight';
    }
    if (icon == Icons.card_giftcard_outlined ||
        icon == Icons.card_giftcard) {
      return 'card_giftcard';
    }
    if (icon == Icons.sports_esports_outlined ||
        icon == Icons.sports_esports) {
      return 'sports_esports';
    }
    if (icon == Icons.restaurant_rounded || icon == Icons.restaurant) {
      return 'restaurant';
    }
    if (icon == Icons.directions_car_outlined ||
        icon == Icons.directions_car ||
        icon == Icons.local_taxi_outlined ||
        icon == Icons.local_taxi) {
      return 'directions_car';
    }
    if (icon == Icons.bolt_outlined || icon == Icons.bolt) {
      return 'bolt';
    }
    if (icon == Icons.shopping_bag_outlined ||
        icon == Icons.shopping_cart ||
        icon == Icons.shopping_cart_outlined ||
        icon == Icons.local_mall_outlined) {
      return 'shopping_bag';
    }
    if (icon == Icons.medical_services_outlined ||
        icon == Icons.medical_services) {
      return 'medical_services';
    }
    if (icon == Icons.subscriptions_outlined ||
        icon == Icons.subscriptions ||
        icon == Icons.receipt_long) {
      return 'subscriptions';
    }
    if (icon == Icons.savings_outlined || icon == Icons.savings) {
      return 'savings';
    }
    if (icon == Icons.home_outlined || icon == Icons.home) {
      return 'home';
    }
    if (icon == Icons.local_cafe_outlined || icon == Icons.local_cafe) {
      return 'local_cafe';
    }
    if (icon == Icons.movie_outlined || icon == Icons.movie) {
      return 'movie';
    }
    return 'category';
  }

  static Color parseColor(dynamic colorValue) {
    if (colorValue is String &&
        colorValue.startsWith('#') &&
        colorValue.length == 7) {
      final hex = colorValue.replaceFirst('#', 'FF');
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    }
    return const Color(0xFF10B981);
  }

  static String colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  static const List<Category> defaults = [
    Category(
      id: '6ad469f73965bcc8647ee772',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFFB95F),
      totalSpendPaise: 640000,
      transactionCount: 9,
      isDefault: true,
      monthlyLimitPaise: 1500000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee771',
      name: 'Groceries',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFF10B981),
      totalSpendPaise: 980000,
      transactionCount: 14,
      isDefault: true,
      monthlyLimitPaise: 2000000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee775',
      name: 'Utilities',
      icon: Icons.bolt_outlined,
      color: Color(0xFFC0C1FF),
      totalSpendPaise: 450000,
      transactionCount: 3,
      isDefault: true,
      monthlyLimitPaise: 800000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee773',
      name: 'Transport',
      icon: Icons.directions_car_outlined,
      color: Color(0xFF4EDEA3),
      totalSpendPaise: 320000,
      transactionCount: 18,
      isDefault: true,
      monthlyLimitPaise: 1000000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee774',
      name: 'Shopping',
      icon: Icons.local_mall_outlined,
      color: Color(0xFFFFB95F),
      totalSpendPaise: 275000,
      transactionCount: 5,
      isDefault: true,
      monthlyLimitPaise: 1200000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee776',
      name: 'Healthcare',
      icon: Icons.medical_services_outlined,
      color: Color(0xFFFFB4AB),
      totalSpendPaise: 180000,
      transactionCount: 2,
      isDefault: true,
      monthlyLimitPaise: 500000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee777',
      name: 'Education',
      icon: Icons.school,
      color: Color(0xFF38BDF8),
      totalSpendPaise: 0,
      transactionCount: 0,
      isDefault: true,
      monthlyLimitPaise: 500000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee778',
      name: 'Entertainment',
      icon: Icons.sports_esports_outlined,
      color: Color(0xFFC0C1FF),
      totalSpendPaise: 210000,
      transactionCount: 4,
      isDefault: true,
      monthlyLimitPaise: 600000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee779',
      name: 'Travel',
      icon: Icons.flight_outlined,
      color: Color(0xFFFFB95F),
      totalSpendPaise: 820000,
      transactionCount: 3,
      isDefault: true,
      monthlyLimitPaise: 2500000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee77a',
      name: 'Personal Care',
      icon: Icons.spa,
      color: Color(0xFFEC4899),
      totalSpendPaise: 95000,
      transactionCount: 2,
      isDefault: true,
      monthlyLimitPaise: 300000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee77b',
      name: 'Bills & Subscriptions',
      icon: Icons.subscriptions_outlined,
      color: Color(0xFF10B981),
      totalSpendPaise: 390000,
      transactionCount: 6,
      isDefault: true,
      monthlyLimitPaise: 500000,
    ),
    Category(
      id: '6ad469f73965bcc8647ee77c',
      name: 'Other / General',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF86948A),
      totalSpendPaise: 110000,
      transactionCount: 2,
      isDefault: true,
      monthlyLimitPaise: 500000,
    ),
  ];
}
