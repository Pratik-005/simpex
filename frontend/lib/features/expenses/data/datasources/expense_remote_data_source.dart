import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/paginated_expenses.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 50,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<PaginatedExpenses> getExpensesPaginated({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Expense> createExpense({
    required int amountMinor,
    required String currency,
    required String categoryId,
    required String description,
    required DateTime transactionDate,
    required String paymentMethod,
    String? notes,
    String? idempotencyKey,
  });

  Future<void> deleteExpense(String expenseId);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final ApiClient apiClient;

  ExpenseRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaginatedExpenses> getExpensesPaginated({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      queryParams['categoryId'] = categoryId;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await apiClient.dio.get(
      ApiConstants.expenses,
      queryParameters: queryParams,
    );

    return PaginatedExpenses.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 50,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final paginated = await getExpensesPaginated(
      page: page,
      limit: limit,
      categoryId: categoryId,
      search: search,
      startDate: startDate,
      endDate: endDate,
    );
    return paginated.items;
  }

  @override
  Future<Expense> createExpense({
    required int amountMinor,
    required String currency,
    required String categoryId,
    required String description,
    required DateTime transactionDate,
    required String paymentMethod,
    String? notes,
    String? idempotencyKey,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.expenses,
      data: {
        'amountMinor': amountMinor,
        'currency': currency,
        'categoryId': categoryId,
        'description': description,
        'transactionDate': transactionDate.toIso8601String(),
        'paymentMethod': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (idempotencyKey != null && idempotencyKey.isNotEmpty)
          'idempotencyKey': idempotencyKey,
      },
      options: idempotencyKey != null && idempotencyKey.isNotEmpty
          ? Options(headers: {'Idempotency-Key': idempotencyKey})
          : null,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return Expense.fromJson(data);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await apiClient.dio.delete('${ApiConstants.expenses}/$expenseId');
  }
}
