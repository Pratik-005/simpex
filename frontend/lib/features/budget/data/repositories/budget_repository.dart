import 'package:flutter/foundation.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/budget.dart';
import '../datasources/budget_local_data_source.dart';
import '../datasources/budget_remote_data_source.dart';

class BudgetRepository {
  BudgetRepository() {
    initFromCache();
  }

  static final BudgetRepository instance = BudgetRepository();

  void initFromCache() {
    if (sl.isRegistered<BudgetLocalDataSource>()) {
      final cached = sl<BudgetLocalDataSource>().getCurrentBudget();
      if (cached != null) {
        budgetNotifier.value = cached;
      }
    }
  }

  final ValueNotifier<Budget?> budgetNotifier = ValueNotifier<Budget?>(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  Budget? get currentBudget => budgetNotifier.value;
  bool get hasBudget => budgetNotifier.value != null;

  void clear() {
    budgetNotifier.value = null;
    errorNotifier.value = null;
    isLoadingNotifier.value = false;
  }

  Future<void> fetchCurrentBudget({int? month, int? year}) async {
    if (!sl.isRegistered<ApiClient>()) return;

    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final BudgetRemoteDataSource dataSource =
          sl.isRegistered<BudgetRemoteDataSource>()
          ? sl<BudgetRemoteDataSource>()
          : BudgetRemoteDataSourceImpl(apiClient: sl<ApiClient>());

      final budget = await dataSource.getCurrentBudget(
        month: month,
        year: year,
      );
      budgetNotifier.value = budget;
      if (budget != null && sl.isRegistered<BudgetLocalDataSource>()) {
        await sl<BudgetLocalDataSource>().saveCurrentBudget(budget);
      }
    } catch (e) {
      errorNotifier.value = e.toString();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<Budget?> getBudgetForMonth({
    required int month,
    required int year,
  }) async {
    if (!sl.isRegistered<ApiClient>()) {
      if (currentBudget != null &&
          currentBudget!.month == month &&
          currentBudget!.year == year) {
        return currentBudget;
      }
      return null;
    }

    try {
      final BudgetRemoteDataSource dataSource =
          sl.isRegistered<BudgetRemoteDataSource>()
          ? sl<BudgetRemoteDataSource>()
          : BudgetRemoteDataSourceImpl(apiClient: sl<ApiClient>());

      return await dataSource.getCurrentBudget(month: month, year: year);
    } catch (_) {
      return null;
    }
  }

  Future<Budget?> setBudget(int amountPaise, {int? month, int? year}) async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final BudgetRemoteDataSource dataSource =
          sl.isRegistered<BudgetRemoteDataSource>()
          ? sl<BudgetRemoteDataSource>()
          : BudgetRemoteDataSourceImpl(apiClient: sl<ApiClient>());

      final budget = await dataSource.setBudget(
        amountPaise: amountPaise,
        month: month,
        year: year,
      );

      budgetNotifier.value = budget;
      if (sl.isRegistered<BudgetLocalDataSource>()) {
        await sl<BudgetLocalDataSource>().saveCurrentBudget(budget);
      }
      return budget;
    } catch (e) {
      errorNotifier.value = e.toString();
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<Budget?> updateBudget(String budgetId, int amountPaise) async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final BudgetRemoteDataSource dataSource =
          sl.isRegistered<BudgetRemoteDataSource>()
          ? sl<BudgetRemoteDataSource>()
          : BudgetRemoteDataSourceImpl(apiClient: sl<ApiClient>());

      final budget = await dataSource.updateBudget(
        budgetId: budgetId,
        amountPaise: amountPaise,
      );

      budgetNotifier.value = budget;
      if (sl.isRegistered<BudgetLocalDataSource>()) {
        await sl<BudgetLocalDataSource>().saveCurrentBudget(budget);
      }
      return budget;
    } catch (e) {
      errorNotifier.value = e.toString();
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }
}
