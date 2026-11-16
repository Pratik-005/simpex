import 'package:flutter/foundation.dart';
import '../../../../core/database/hive_service.dart';
import '../../domain/models/budget.dart';

abstract class BudgetLocalDataSource {
  Budget? getCurrentBudget({int? month, int? year});
  Future<void> saveCurrentBudget(Budget budget);
  Future<void> clear();
}

class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  final HiveService hiveService;

  BudgetLocalDataSourceImpl({required this.hiveService});

  static const String currentBudgetKey = 'current_budget';

  @override
  Budget? getCurrentBudget({int? month, int? year}) {
    final raw = hiveService.budgetBox.get(currentBudgetKey);
    if (raw == null) return null;

    try {
      final map = Map<String, dynamic>.from(raw);
      final budget = Budget.fromJson(map);

      if (month != null && year != null) {
        if (budget.month == month && budget.year == year) {
          return budget;
        }
        // Also check if specific month budget key exists
        final specificRaw = hiveService.budgetBox.get('budget_${year}_$month');
        if (specificRaw != null) {
          return Budget.fromJson(Map<String, dynamic>.from(specificRaw));
        }
        return null;
      }

      return budget;
    } catch (e) {
      debugPrint('[BudgetLocalDataSource] Error parsing cached budget: $e');
      return null;
    }
  }

  @override
  Future<void> saveCurrentBudget(Budget budget) async {
    final map = {
      'id': budget.id,
      'amountMinor': budget.amountPaise,
      'currency': budget.currency,
      'month': budget.month,
      'year': budget.year,
      'startDate': budget.startDate.toIso8601String(),
      'endDate': budget.endDate.toIso8601String(),
      'createdAt': budget.createdAt?.toIso8601String(),
      'updatedAt': budget.updatedAt?.toIso8601String(),
    };

    await hiveService.budgetBox.put(currentBudgetKey, map);
    await hiveService.budgetBox.put(
      'budget_${budget.year}_${budget.month}',
      map,
    );
  }

  @override
  Future<void> clear() async {
    await hiveService.budgetBox.clear();
  }
}

