import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/injection/init_dependencies.dart';
import '../../../core/network/api_client.dart';
import '../../budget/data/repositories/budget_repository.dart';
import '../../categories/data/repositories/category_repository.dart';
import '../../categories/domain/models/category.dart';
import '../../sync/data/datasources/sync_queue_local_data_source.dart';
import '../../sync/domain/models/sync_operation.dart';
import '../../sync/domain/services/sync_engine.dart';
import '../domain/models/expense.dart';
import 'datasources/expense_local_data_source.dart';
import 'datasources/expense_remote_data_source.dart';

import '../domain/models/paginated_expenses.dart';

class MockExpenseRepository {
  MockExpenseRepository() {
    initFromLocalStorage();
  }

  static final MockExpenseRepository instance = MockExpenseRepository();
  final _uuid = const Uuid();

  final ValueNotifier<List<Expense>> expensesNotifier =
      ValueNotifier<List<Expense>>([]);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingMoreNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  bool _hasFetchedFromBackend = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _activeCategoryId;
  DateTime? _activeStartDate;
  DateTime? _activeEndDate;
  String? _activeSearch;

  void initFromLocalStorage() {
    if (sl.isRegistered<ExpenseLocalDataSource>()) {
      final localExpenses = sl<ExpenseLocalDataSource>().getAllExpenses();
      if (localExpenses.isNotEmpty) {
        expensesNotifier.value = localExpenses;
        return;
      }
    }
    if (!sl.isRegistered<ApiClient>()) {
      _initDefaultExpenses();
    }
  }

  String? get activeCategoryId => _activeCategoryId;
  DateTime? get activeStartDate => _activeStartDate;
  DateTime? get activeEndDate => _activeEndDate;
  String? get activeSearch => _activeSearch;

  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;

  void setPaginationStateForTesting({
    required int currentPage,
    required bool hasMore,
  }) {
    _currentPage = currentPage;
    _hasMore = hasMore;
  }

  void _initDefaultExpenses() {
    final now = DateTime.now();
    expensesNotifier.value = [
      Expense(
        id: _uuid.v4(),
        merchant: 'Blue Tokai Roasters',
        categoryId: 'dining',
        categoryName: 'Dining',
        amountPaise: 38000, // ₹380.00
        date: DateTime(now.year, now.month, now.day, 20, 30),
        paymentMethod: 'UPI • Google Pay',
        syncStatus: SyncStatus.synced,
        isVoiceRecorded: true,
        voiceTranscript: 'Recorded two iced cappuccinos at Blue Tokai',
      ),
      Expense(
        id: _uuid.v4(),
        merchant: 'Shell Fuel Station',
        categoryId: 'transport',
        categoryName: 'Transport',
        amountPaise: 145000, // ₹1,450.00
        date: DateTime(now.year, now.month, now.day, 16, 12),
        paymentMethod: 'HDFC Debit • Offline',
        syncStatus: SyncStatus.pending,
        isVoiceRecorded: true,
        voiceTranscript: 'Put 1450 rupees petrol in the car at Shell',
      ),
      Expense(
        id: _uuid.v4(),
        merchant: 'Swiggy Gourmet',
        categoryId: 'dining',
        categoryName: 'Food & Dining',
        amountPaise: 62000, // ₹620.00
        date: DateTime(now.year, now.month, now.day, 13, 20),
        paymentMethod: 'ICICI NetBanking',
        syncStatus: SyncStatus.synced,
        isVoiceRecorded: true,
        voiceTranscript: 'Log six twenty rupees spent on Swiggy lunch',
      ),
    ];
  }

  List<Expense> get expenses => List.unmodifiable(expensesNotifier.value);

  int get totalSpendPaise =>
      expenses.fold(0, (sum, expense) => sum + expense.amountPaise);

  int get currentMonthSpendPaise {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0, (sum, expense) => sum + expense.amountPaise);
  }

  List<Expense> get currentMonthExpenses {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  Future<List<Expense>> getExpensesForMonth({
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    if (sl.isRegistered<ApiClient>()) {
      try {
        if (sl.isRegistered<ExpenseRemoteDataSource>()) {
          final paginated = await sl<ExpenseRemoteDataSource>().getExpensesPaginated(
            page: 1,
            limit: 100,
            startDate: start,
            endDate: end,
          );
          return paginated.items;
        } else {
          final response = await sl<ApiClient>().dio.get(
            ApiConstants.expenses,
            queryParameters: {
              'page': 1,
              'limit': 100,
              'startDate': start.toIso8601String(),
              'endDate': end.toIso8601String(),
            },
          );
          final paginated = PaginatedExpenses.fromJson(
            response.data as Map<String, dynamic>,
          );
          return paginated.items;
        }
      } catch (_) {
        // Fallback to local memory filtering on network issue
      }
    }

    return expensesNotifier.value
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  int get todaySpendPaise {
    final now = DateTime.now();
    return expenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold(0, (sum, expense) => sum + expense.amountPaise);
  }

  void reseedIfStale() {
    if (sl.isRegistered<ApiClient>()) {
      if (!_hasFetchedFromBackend) {
        fetchBackendExpenses();
      }
      return;
    }
    if (expensesNotifier.value.isEmpty ||
        expensesNotifier.value.any((e) => e.isVoiceRecorded == null)) {
      _initDefaultExpenses();
    }
  }

  int get voiceRecordedCount =>
      expenses.where((e) => e.isVoiceRecorded == true).length;

  void clear() {
    expensesNotifier.value = [];
    _hasFetchedFromBackend = false;
    _currentPage = 1;
    _hasMore = true;
    isLoadingMoreNotifier.value = false;
    _activeCategoryId = null;
    _activeStartDate = null;
    _activeEndDate = null;
    _activeSearch = null;
  }

  Future<void> fetchFirstPage({
    bool force = false,
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    _activeCategoryId = categoryId;
    _activeSearch = search;
    _activeStartDate = startDate;
    _activeEndDate = endDate;

    if (!sl.isRegistered<ApiClient>()) return;
    if (_hasFetchedFromBackend && !force && expensesNotifier.value.isNotEmpty) {
      return;
    }

    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final PaginatedExpenses paginated;
      if (sl.isRegistered<ExpenseRemoteDataSource>()) {
        paginated = await sl<ExpenseRemoteDataSource>().getExpensesPaginated(
          page: 1,
          limit: limit,
          categoryId: categoryId,
          search: search,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        final Map<String, dynamic> queryParams = {'page': 1, 'limit': limit};
        if (categoryId != null &&
            categoryId.isNotEmpty &&
            categoryId != 'all') {
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

        final response = await sl<ApiClient>().dio.get(
          ApiConstants.expenses,
          queryParameters: queryParams,
        );
        paginated = PaginatedExpenses.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      _currentPage = 1;
      _hasMore = paginated.hasMore;

      // Preserve any pending local items that haven't synced yet
      final pendingLocal = expensesNotifier.value
          .where(
            (e) =>
                e.syncStatus == SyncStatus.pending ||
                e.syncStatus == SyncStatus.failed,
          )
          .where((e) => !paginated.items.any((f) => f.id == e.id))
          .toList();

      _hasFetchedFromBackend = true;
      expensesNotifier.value = [...pendingLocal, ...paginated.items];

      if (sl.isRegistered<ExpenseLocalDataSource>()) {
        await sl<ExpenseLocalDataSource>().saveExpenses(paginated.items);
      }
    } catch (e) {
      errorNotifier.value = e.toString();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> fetchNextPage({
    String? categoryId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    if (!sl.isRegistered<ApiClient>()) return;
    if (!_hasMore || isLoadingMoreNotifier.value || isLoadingNotifier.value) {
      return;
    }

    final effectiveCategoryId = categoryId ?? _activeCategoryId;
    final effectiveSearch = search ?? _activeSearch;
    final effectiveStartDate = startDate ?? _activeStartDate;
    final effectiveEndDate = endDate ?? _activeEndDate;

    isLoadingMoreNotifier.value = true;

    try {
      final nextPage = _currentPage + 1;
      final PaginatedExpenses paginated;
      if (sl.isRegistered<ExpenseRemoteDataSource>()) {
        paginated = await sl<ExpenseRemoteDataSource>().getExpensesPaginated(
          page: nextPage,
          limit: limit,
          categoryId: effectiveCategoryId,
          search: effectiveSearch,
          startDate: effectiveStartDate,
          endDate: effectiveEndDate,
        );
      } else {
        final Map<String, dynamic> queryParams = {
          'page': nextPage,
          'limit': limit,
        };
        if (effectiveCategoryId != null &&
            effectiveCategoryId.isNotEmpty &&
            effectiveCategoryId != 'all') {
          queryParams['categoryId'] = effectiveCategoryId;
        }
        if (effectiveSearch != null && effectiveSearch.isNotEmpty) {
          queryParams['search'] = effectiveSearch;
        }
        if (effectiveStartDate != null) {
          queryParams['startDate'] = effectiveStartDate.toIso8601String();
        }
        if (effectiveEndDate != null) {
          queryParams['endDate'] = effectiveEndDate.toIso8601String();
        }

        final response = await sl<ApiClient>().dio.get(
          ApiConstants.expenses,
          queryParameters: queryParams,
        );
        paginated = PaginatedExpenses.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      _currentPage = nextPage;
      _hasMore = paginated.hasMore;

      // Deduplicate items against already loaded list
      final existingIds = expensesNotifier.value.map((e) => e.id).toSet();
      final newItems = paginated.items
          .where((e) => !existingIds.contains(e.id))
          .toList();

      expensesNotifier.value = [...expensesNotifier.value, ...newItems];

      if (sl.isRegistered<ExpenseLocalDataSource>()) {
        await sl<ExpenseLocalDataSource>().saveExpenses(newItems);
      }
    } catch (e) {
      errorNotifier.value = e.toString();
    } finally {
      isLoadingMoreNotifier.value = false;
    }
  }

  Future<void> fetchBackendExpenses({bool force = false}) async {
    await fetchFirstPage(force: force);
  }

  Future<Expense> addExpense({
    required String merchant,
    required String categoryId,
    required String categoryName,
    required int amountPaise,
    required DateTime date,
    required String paymentMethod,
    String? notes,
    SyncStatus syncStatus = SyncStatus.synced,
    bool isVoiceRecorded = false,
    String? voiceTranscript,
    String currency = 'INR',
  }) async {
    final tempId = _uuid.v4();

    // 1. Resolve valid 24-char ObjectId for category
    String targetCatId = categoryId;
    if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(targetCatId)) {
      final searchName = categoryName
          .toLowerCase()
          .replaceAll('&', 'and')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final searchSlug = categoryId
          .toLowerCase()
          .replaceAll('_', '')
          .replaceAll('-', '')
          .trim();

      List<Category> cats = CategoryRepository.instance.categories;
      if (cats.isEmpty && sl.isRegistered<ApiClient>()) {
        try {
          cats = await CategoryRepository.instance.fetchCategories();
        } catch (_) {}
      }

      if (cats.isNotEmpty) {
        Category? matchedCat;
        for (final c in cats) {
          final normName = c.name
              .toLowerCase()
              .replaceAll('&', 'and')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (normName == searchName ||
              c.name.toLowerCase() == categoryName.toLowerCase()) {
            matchedCat = c;
            break;
          }
        }
        if (matchedCat == null) {
          for (final c in cats) {
            final normName = c.name
                .toLowerCase()
                .replaceAll('&', 'and')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            if (normName.contains(searchSlug) ||
                searchName.contains(normName) ||
                normName.contains(searchName)) {
              matchedCat = c;
              break;
            }
          }
        }
        matchedCat ??= cats.firstWhere(
          (c) => RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(c.id),
          orElse: () => cats.first,
        );

        if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(matchedCat.id)) {
          targetCatId = matchedCat.id;
        }
      }
    }

    // 2. Map paymentMethod to allowed backend enum values
    String validMethod = 'UPI';
    final lower = paymentMethod.toLowerCase();
    if (lower.contains('cash')) {
      validMethod = 'Cash';
    } else if (lower.contains('credit')) {
      validMethod = 'Credit Card';
    } else if (lower.contains('debit')) {
      validMethod = 'Debit Card';
    } else if (lower.contains('apple')) {
      validMethod = 'Apple Pay';
    } else if (lower.contains('upi')) {
      validMethod = 'UPI';
    } else {
      validMethod = 'Other';
    }

    final newExpense = Expense(
      id: tempId,
      merchant: merchant,
      categoryId: targetCatId,
      categoryName: categoryName,
      amountPaise: amountPaise,
      date: date,
      paymentMethod: validMethod,
      syncStatus: SyncStatus.pending,
      notes: notes,
      isVoiceRecorded: isVoiceRecorded,
      voiceTranscript: voiceTranscript,
      currency: currency,
    );

    // 3. Optimistically add to in-memory UI list
    expensesNotifier.value = [newExpense, ...expensesNotifier.value];

    // 4. Save to persistent local Hive storage
    if (sl.isRegistered<ExpenseLocalDataSource>()) {
      await sl<ExpenseLocalDataSource>().saveExpense(newExpense);
    }

    // 5. Enqueue to persistent sync queue
    if (sl.isRegistered<SyncQueueLocalDataSource>()) {
      final op = SyncOperationItem(
        operationId: _uuid.v4(),
        action: SyncOperationType.create,
        timestamp: DateTime.now(),
        data: {
          'tempId': tempId,
          'amountMinor': amountPaise,
          'currency': currency,
          'categoryId': targetCatId,
          'description': merchant,
          'transactionDate': date.toIso8601String(),
          'paymentMethod': validMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      await sl<SyncQueueLocalDataSource>().enqueue(op);
    }

    // 6. Trigger background sync via SyncEngine
    if (sl.isRegistered<SyncEngine>()) {
      sl<SyncEngine>().sync();
    }

    // 7. Refresh budget calculation dynamically
    if (sl.isRegistered<BudgetRepository>()) {
      sl<BudgetRepository>().fetchCurrentBudget();
    }

    return newExpense;
  }

  Future<void> deleteExpense(String id) async {
    // 1. Remove from in-memory UI list
    expensesNotifier.value = expensesNotifier.value
        .where((e) => e.id != id)
        .toList();

    // 2. Remove from persistent local storage
    if (sl.isRegistered<ExpenseLocalDataSource>()) {
      await sl<ExpenseLocalDataSource>().deleteExpense(id);
    }

    // 3. Queue management
    if (sl.isRegistered<SyncQueueLocalDataSource>()) {
      final pendingOps = sl<SyncQueueLocalDataSource>().getPendingOperations();
      final matchingCreate = pendingOps.firstWhere(
        (op) =>
            op.action == SyncOperationType.create &&
            (op.data['tempId'] == id || op.data['id'] == id),
        orElse: () => SyncOperationItem(
          operationId: '',
          action: SyncOperationType.create,
          timestamp: DateTime.now(),
          data: const {},
        ),
      );

      if (matchingCreate.operationId.isNotEmpty) {
        await sl<SyncQueueLocalDataSource>().remove(matchingCreate.operationId);
      } else if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
        final op = SyncOperationItem(
          operationId: _uuid.v4(),
          action: SyncOperationType.delete,
          timestamp: DateTime.now(),
          data: {'id': id},
        );
        await sl<SyncQueueLocalDataSource>().enqueue(op);
      }
    }

    // 4. Trigger background sync
    if (sl.isRegistered<SyncEngine>()) {
      sl<SyncEngine>().sync();
    }
  }
}

typedef ExpenseRepository = MockExpenseRepository;
