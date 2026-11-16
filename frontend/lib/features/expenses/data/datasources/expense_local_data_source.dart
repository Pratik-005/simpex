import 'package:flutter/material.dart';
import '../../../../core/database/hive_service.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/expense.dart';

abstract class ExpenseLocalDataSource {
  List<Expense> getAllExpenses();
  Expense? getExpense(String id);
  Future<void> saveExpense(Expense expense);
  Future<void> saveExpenses(List<Expense> expenses);
  Future<void> updateSyncStatus(String id, SyncStatus status);
  Future<void> replaceIdAndSyncStatus(
    String oldId,
    String newId,
    SyncStatus status,
  );
  Future<void> deleteExpense(String id);
  Future<void> clear();
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final HiveService hiveService;

  ExpenseLocalDataSourceImpl({required this.hiveService});

  @override
  List<Expense> getAllExpenses() {
    final rawValues = hiveService.expensesBox.values;
    final List<Expense> expenses = [];

    for (final raw in rawValues) {
      try {
        final map = Map<String, dynamic>.from(raw);
        expenses.add(_mapToExpense(map));
      } catch (e) {
        debugPrint('[ExpenseLocalDataSource] Error parsing expense: $e');
      }
    }

    // Sort descending by date
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  @override
  Expense? getExpense(String id) {
    final raw = hiveService.expensesBox.get(id);
    if (raw == null) return null;
    return _mapToExpense(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    final map = _expenseToMap(expense);
    await hiveService.expensesBox.put(expense.id, map);
  }

  @override
  Future<void> saveExpenses(List<Expense> expenses) async {
    final entries = <String, Map<String, dynamic>>{};
    for (final expense in expenses) {
      entries[expense.id] = _expenseToMap(expense);
    }
    await hiveService.expensesBox.putAll(entries);
  }

  @override
  Future<void> updateSyncStatus(String id, SyncStatus status) async {
    final raw = hiveService.expensesBox.get(id);
    if (raw == null) return;
    final map = Map<String, dynamic>.from(raw);
    map['syncStatus'] = status.name;
    await hiveService.expensesBox.put(id, map);
  }

  @override
  Future<void> replaceIdAndSyncStatus(
    String oldId,
    String newId,
    SyncStatus status,
  ) async {
    final raw = hiveService.expensesBox.get(oldId);
    if (raw == null) {
      // Check if already stored with newId
      final existing = hiveService.expensesBox.get(newId);
      if (existing != null) {
        final map = Map<String, dynamic>.from(existing);
        map['syncStatus'] = status.name;
        await hiveService.expensesBox.put(newId, map);
      }
      return;
    }

    final map = Map<String, dynamic>.from(raw);
    map['id'] = newId;
    map['syncStatus'] = status.name;

    await hiveService.expensesBox.put(newId, map);
    if (oldId != newId) {
      await hiveService.expensesBox.delete(oldId);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await hiveService.expensesBox.delete(id);
  }

  @override
  Future<void> clear() async {
    await hiveService.expensesBox.clear();
  }

  // --- Helpers ---

  Map<String, dynamic> _expenseToMap(Expense expense) {
    return {
      'id': expense.id,
      'description': expense.merchant,
      'amountMinor': expense.amountPaise,
      'categoryId': expense.categoryId,
      'transactionDate': expense.date.toIso8601String(),
      'paymentMethod': expense.paymentMethod,
      'currency': expense.currency,
      'syncStatus': expense.syncStatus.name,
    };
  }

  Expense _mapToExpense(Map<String, dynamic> map) {
    final catId = (map['categoryId'] ?? '').toString();

    // Dynamically resolve category details
    String catName = 'General';
    Color? catColor;
    IconData? catIcon;

    final loadedCategories = CategoryRepository.instance.categories;
    Category? matched;
    try {
      matched = loadedCategories.firstWhere(
        (c) => c.id == catId,
        orElse: () => Category.defaults.firstWhere(
          (c) => c.id == catId || c.name.toLowerCase() == catId.toLowerCase(),
          orElse: () => Category.defaults.first,
        ),
      );
    } catch (_) {
      matched = null;
    }

    if (matched != null) {
      catName = matched.name;
      catColor = matched.color;
      catIcon = matched.icon;
    }

    final rawStatus = map['syncStatus']?.toString() ?? 'synced';
    final syncStatus = SyncStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => SyncStatus.synced,
    );

    return Expense(
      id: (map['id'] ?? '').toString(),
      merchant: (map['description'] ?? '').toString(),
      categoryId: catId,
      categoryName: catName,
      categoryColor: catColor,
      categoryIcon: catIcon,
      amountPaise: (map['amountMinor'] is num)
          ? (map['amountMinor'] as num).toInt()
          : 0,
      date: map['transactionDate'] != null
          ? DateTime.tryParse(map['transactionDate'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      paymentMethod: (map['paymentMethod'] ?? 'UPI').toString(),
      currency: (map['currency'] ?? 'INR').toString(),
      syncStatus: syncStatus,
    );
  }
}

