import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/budget.dart';

abstract class BudgetRemoteDataSource {
  Future<Budget?> getCurrentBudget({int? month, int? year});
  Future<Budget> setBudget({required int amountPaise, int? month, int? year});
  Future<Budget> updateBudget({required String budgetId, required int amountPaise});
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final ApiClient apiClient;

  BudgetRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Budget?> getCurrentBudget({int? month, int? year}) async {
    final Map<String, dynamic> queryParams = {};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    final response = await apiClient.dio.get(
      ApiConstants.currentBudget,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data['data'];
    if (data == null) {
      return null;
    }
    return Budget.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Budget> setBudget({
    required int amountPaise,
    int? month,
    int? year,
  }) async {
    final Map<String, dynamic> body = {
      'amountMinor': amountPaise,
      'month': ?month,
      'year': ?year,
    };

    final response = await apiClient.dio.post(
      ApiConstants.budgets,
      data: body,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Budget.fromJson(data);
  }

  @override
  Future<Budget> updateBudget({
    required String budgetId,
    required int amountPaise,
  }) async {
    final response = await apiClient.dio.patch(
      '${ApiConstants.budgets}/$budgetId',
      data: {'amountMinor': amountPaise},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Budget.fromJson(data);
  }
}
