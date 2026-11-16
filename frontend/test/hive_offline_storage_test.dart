import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/database/hive_service.dart';
import 'package:frontend/features/budget/data/datasources/budget_local_data_source.dart';
import 'package:frontend/features/budget/domain/models/budget.dart';
import 'package:frontend/features/categories/data/datasources/category_local_data_source.dart';
import 'package:frontend/features/categories/domain/models/category.dart';
import 'package:frontend/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:frontend/features/expenses/domain/models/expense.dart';
import 'package:frontend/features/sync/data/datasources/sync_queue_local_data_source.dart';
import 'package:frontend/features/sync/domain/models/sync_operation.dart';

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_simpex_test_');
    hiveService = HiveService();
    await hiveService.init(tempDir.path);
  });

  tearDown(() async {
    await hiveService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveService initialization', () {
    test('opens all four required boxes', () {
      expect(hiveService.expensesBox.isOpen, isTrue);
      expect(hiveService.syncQueueBox.isOpen, isTrue);
      expect(hiveService.categoriesBox.isOpen, isTrue);
      expect(hiveService.budgetBox.isOpen, isTrue);
    });
  });

  group('ExpenseLocalDataSource', () {
    test('saves, retrieves, and sorts expenses descending by date', () async {
      final dataSource = ExpenseLocalDataSourceImpl(hiveService: hiveService);

      final exp1 = Expense(
        id: 'temp-uuid-1',
        merchant: 'Blue Tokai',
        categoryId: '65b123456789012345678901',
        categoryName: 'Dining',
        amountPaise: 38000,
        date: DateTime(2026, 10, 20, 10, 0),
        paymentMethod: 'UPI',
        syncStatus: SyncStatus.pending,
      );

      final exp2 = Expense(
        id: 'temp-uuid-2',
        merchant: 'Shell Petrol',
        categoryId: '65b123456789012345678902',
        categoryName: 'Transport',
        amountPaise: 150000,
        date: DateTime(2026, 10, 25, 14, 30),
        paymentMethod: 'Debit Card',
        syncStatus: SyncStatus.pending,
      );

      await dataSource.saveExpense(exp1);
      await dataSource.saveExpense(exp2);

      final loaded = dataSource.getAllExpenses();
      expect(loaded.length, 2);
      // exp2 is newer so should be first
      expect(loaded[0].id, 'temp-uuid-2');
      expect(loaded[0].merchant, 'Shell Petrol');
      expect(loaded[0].amountPaise, 150000);
      expect(loaded[0].syncStatus, SyncStatus.pending);

      expect(loaded[1].id, 'temp-uuid-1');
      expect(loaded[1].merchant, 'Blue Tokai');
    });

    test('replaces temporary UUID with backend ObjectId upon reconciliation', () async {
      final dataSource = ExpenseLocalDataSourceImpl(hiveService: hiveService);

      final exp = Expense(
        id: 'temp-uuid-999',
        merchant: 'Swiggy',
        categoryId: '65b123456789012345678901',
        categoryName: 'Dining',
        amountPaise: 45000,
        date: DateTime.now(),
        paymentMethod: 'UPI',
        syncStatus: SyncStatus.pending,
      );

      await dataSource.saveExpense(exp);
      expect(dataSource.getExpense('temp-uuid-999'), isNotNull);

      // Backend sync returns MongoDB ObjectId
      const serverMongoId = '65bfa7890123456789012345';
      await dataSource.replaceIdAndSyncStatus(
        'temp-uuid-999',
        serverMongoId,
        SyncStatus.synced,
      );

      // Old temp UUID should no longer exist
      expect(dataSource.getExpense('temp-uuid-999'), isNull);

      // New server ID should exist with synced status
      final syncedExp = dataSource.getExpense(serverMongoId);
      expect(syncedExp, isNotNull);
      expect(syncedExp!.id, serverMongoId);
      expect(syncedExp.syncStatus, SyncStatus.synced);
      expect(syncedExp.merchant, 'Swiggy');
      expect(syncedExp.amountPaise, 45000);
    });

    test('deletes expense from local disk', () async {
      final dataSource = ExpenseLocalDataSourceImpl(hiveService: hiveService);

      final exp = Expense(
        id: 'exp-to-delete',
        merchant: 'Groceries',
        categoryId: '65b123456789012345678901',
        categoryName: 'Groceries',
        amountPaise: 120000,
        date: DateTime.now(),
        paymentMethod: 'Cash',
      );

      await dataSource.saveExpense(exp);
      expect(dataSource.getExpense('exp-to-delete'), isNotNull);

      await dataSource.deleteExpense('exp-to-delete');
      expect(dataSource.getExpense('exp-to-delete'), isNull);
    });
  });

  group('SyncQueueLocalDataSource', () {
    test('enqueues, returns chronologically, and removes operations', () async {
      final queue = SyncQueueLocalDataSourceImpl(hiveService: hiveService);

      final op1 = SyncOperationItem(
        operationId: 'op-1',
        action: SyncOperationType.create,
        timestamp: DateTime(2026, 10, 29, 10, 0),
        data: {'tempId': 'uuid-1', 'amountMinor': 1000},
      );

      final op2 = SyncOperationItem(
        operationId: 'op-2',
        action: SyncOperationType.delete,
        timestamp: DateTime(2026, 10, 29, 11, 0),
        data: {'id': '65b123'},
      );

      await queue.enqueue(op2);
      await queue.enqueue(op1);

      expect(queue.getPendingCount(), 2);

      final pending = queue.getPendingOperations();
      expect(pending.length, 2);
      // op1 was created at 10:00, op2 at 11:00 -> sorted ascending by timestamp
      expect(pending[0].operationId, 'op-1');
      expect(pending[1].operationId, 'op-2');

      // Remove op1
      await queue.remove('op-1');
      expect(queue.getPendingCount(), 1);
      expect(queue.getPendingOperations().first.operationId, 'op-2');
    });
  });

  group('CategoryLocalDataSource & BudgetLocalDataSource', () {
    test('caches and restores categories', () async {
      final catDataSource =
          CategoryLocalDataSourceImpl(hiveService: hiveService);

      final defaults = Category.defaults.take(3).toList();
      await catDataSource.saveCategories(defaults);

      final restored = catDataSource.getCategories();
      expect(restored.length, 3);
      expect(
        restored.map((c) => c.name).toSet(),
        defaults.map((c) => c.name).toSet(),
      );
    });

    test('caches and restores current budget', () async {
      final budgetDataSource =
          BudgetLocalDataSourceImpl(hiveService: hiveService);

      final budget = Budget(
        id: 'budget-101',
        amountPaise: 5000000,
        currency: 'INR',
        month: 10,
        year: 2026,
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
      );

      await budgetDataSource.saveCurrentBudget(budget);

      final restored = budgetDataSource.getCurrentBudget(month: 10, year: 2026);
      expect(restored, isNotNull);
      expect(restored!.id, 'budget-101');
      expect(restored.amountPaise, 5000000);
      expect(restored.month, 10);
      expect(restored.year, 2026);
    });
  });

  group('Simulated App Restart (Cold-Start Persistence)', () {
    test('expenses and sync queue survive app termination and restart', () async {
      // 1. First app session: save expense and enqueue sync operation
      final expDataSource1 =
          ExpenseLocalDataSourceImpl(hiveService: hiveService);
      final queue1 = SyncQueueLocalDataSourceImpl(hiveService: hiveService);

      final exp = Expense(
        id: 'offline-persisted-uuid',
        merchant: 'Offline Cafe',
        categoryId: '65b123456789012345678901',
        categoryName: 'Dining',
        amountPaise: 25000,
        date: DateTime(2026, 10, 29, 15, 0),
        paymentMethod: 'Cash',
        syncStatus: SyncStatus.pending,
      );

      await expDataSource1.saveExpense(exp);
      await queue1.enqueue(
        SyncOperationItem(
          operationId: 'sync-op-offline-1',
          action: SyncOperationType.create,
          timestamp: DateTime.now(),
          data: {'tempId': exp.id, 'amountMinor': exp.amountPaise},
        ),
      );

      // 2. Simulate app termination: close boxes
      await hiveService.close();

      // 3. Simulate app restart: re-initialize HiveService with same directory
      final hiveService2 = HiveService();
      await hiveService2.init(tempDir.path);

      final expDataSource2 =
          ExpenseLocalDataSourceImpl(hiveService: hiveService2);
      final queue2 = SyncQueueLocalDataSourceImpl(hiveService: hiveService2);

      // Verify expenses survive termination
      final loadedExpenses = expDataSource2.getAllExpenses();
      expect(loadedExpenses.length, 1);
      expect(loadedExpenses.first.id, 'offline-persisted-uuid');
      expect(loadedExpenses.first.merchant, 'Offline Cafe');
      expect(loadedExpenses.first.amountPaise, 25000);
      expect(loadedExpenses.first.syncStatus, SyncStatus.pending);

      // Verify sync queue survives termination
      expect(queue2.getPendingCount(), 1);
      final loadedOps = queue2.getPendingOperations();
      expect(loadedOps.first.operationId, 'sync-op-offline-1');
      expect(loadedOps.first.data['tempId'], 'offline-persisted-uuid');

      await hiveService2.close();
    });
  });
}
