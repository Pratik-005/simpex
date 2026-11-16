import 'package:flutter/material.dart';
import '../../../categories/domain/models/category.dart';

enum SyncStatus { synced, pending, failed }

class Expense {
  final String id;
  final String merchant;
  final String categoryId;
  final String categoryName;
  final int amountPaise;
  final DateTime date;
  final String paymentMethod;
  final SyncStatus syncStatus;
  final String? notes;
  final bool? isVoiceRecorded;
  final String? voiceTranscript;
  final String currency;
  final Color? categoryColor;
  final IconData? categoryIcon;

  const Expense({
    required this.id,
    required this.merchant,
    required this.categoryId,
    required this.categoryName,
    required this.amountPaise,
    required this.date,
    required this.paymentMethod,
    this.syncStatus = SyncStatus.synced,
    this.notes,
    this.isVoiceRecorded = false,
    this.voiceTranscript,
    this.currency = 'INR',
    this.categoryColor,
    this.categoryIcon,
  });

  Expense copyWith({
    String? id,
    String? merchant,
    String? categoryId,
    String? categoryName,
    int? amountPaise,
    DateTime? date,
    String? paymentMethod,
    SyncStatus? syncStatus,
    String? notes,
    bool? isVoiceRecorded,
    String? voiceTranscript,
    String? currency,
    Color? categoryColor,
    IconData? categoryIcon,
  }) {
    return Expense(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amountPaise: amountPaise ?? this.amountPaise,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes ?? this.notes,
      isVoiceRecorded: isVoiceRecorded ?? this.isVoiceRecorded ?? false,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      currency: currency ?? this.currency,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final catData = json['categoryId'];
    String catId = '';
    String catName = 'General';
    Color? catColor;
    IconData? catIcon;

    if (catData is Map<String, dynamic>) {
      catId = (catData['_id'] ?? catData['id'] ?? '').toString();
      catName = (catData['name'] ?? 'General').toString();
      if (catData['color'] != null) {
        catColor = Category.parseColor(catData['color']);
      }
      if (catData['icon'] != null) {
        catIcon = Category.parseIcon(catData['icon']?.toString());
      }
    } else if (catData != null) {
      catId = catData.toString();
    }

    return Expense(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      merchant: (json['description'] ?? json['merchant'] ?? '').toString(),
      categoryId: catId,
      categoryName: catName,
      amountPaise: json['amountMinor'] is num
          ? (json['amountMinor'] as num).toInt()
          : (json['amountPaise'] is num
              ? (json['amountPaise'] as num).toInt()
              : 0),
      date: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      paymentMethod: (json['paymentMethod'] ?? 'UPI').toString(),
      syncStatus: SyncStatus.synced,
      notes: json['notes']?.toString(),
      currency: (json['currency'] ?? 'INR').toString(),
      categoryColor: catColor,
      categoryIcon: catIcon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': merchant,
      'amountMinor': amountPaise,
      'categoryId': categoryId,
      'transactionDate': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'currency': currency,
      if (notes != null) 'notes': notes,
    };
  }
}

