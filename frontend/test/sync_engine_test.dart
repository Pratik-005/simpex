import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/database/hive_service.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/auth_storage.dart';
import 'package:frontend/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:frontend/features/expenses/domain/models/expense.dart';
import 'package:frontend/features/sync/data/datasources/sync_queue_local_data_source.dart';
import 'package:frontend/features/sync/domain/models/sync_operation.dart';
import 'package:frontend/features/sync/domain/services/sync_engine.dart';

class FakeAuthStorage extends Fake implements AuthStorage {
  @override
  Future<String?> getAccessToken() async => 'test-mock-token';

  @override
  Future<String?> getRefreshToken() async => 'test-mock-refresh';
}

void main() {
  late Directory tempDir;
  late HiveService hiveService;
  late ExpenseLocalDataSource expenseDataSource;
  late SyncQueueLocalDataSource queueDataSource;
  late FakeAuthStorage fakeAuthStorage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_sync_engine_test_');
    hiveService = HiveService();
    await hiveService.init(tempDir.path);

    expenseDataSource = ExpenseLocalDataSourceImpl(hiveService: hiveService);
    queueDataSource = SyncQueueLocalDataSourceImpl(hiveService: hiveService);
    fakeAuthStorage = FakeAuthStorage();
  });

  tearDown(() async {
    await hiveService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('SyncEngine processes pending batch and reconciles tempId with server ObjectId', () async {
    // 1. Setup mock Dio to intercept /sync/batch
    final mockDio = Dio();
    mockDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/sync/batch')) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'total': 1,
                    'synced': 1,
                    'duplicates': 0,
                    'failed': 0,
                    'results': [
                      {
                        'operationId': 'test-op-1',
                        'action': 'create',
                        'status': 'synced',
                        'entityId': '65ba00112233445566778899',
                      }
                    ],
                  },
                },
              ),
            );
          }
          return handler.next(options);
        },
      ),
    );

    final apiClient = ApiClient(
      authStorage: fakeAuthStorage,
      customDio: mockDio,
    );

    final engine = SyncEngine(
      syncQueueLocalDataSource: queueDataSource,
      expenseLocalDataSource: expenseDataSource,
      apiClient: apiClient,
    );

    // 2. Add an offline pending expense and queue operation
    final offlineExpense = Expense(
      id: 'local-temp-uuid-42',
      merchant: 'Coldplay Ticket',
      categoryId: '65b123456789012345678901',
      categoryName: 'Entertainment',
      amountPaise: 499900,
      date: DateTime.now(),
      paymentMethod: 'UPI',
      syncStatus: SyncStatus.pending,
    );
    await expenseDataSource.saveExpense(offlineExpense);

    await queueDataSource.enqueue(
      SyncOperationItem(
        operationId: 'test-op-1',
        action: SyncOperationType.create,
        timestamp: DateTime.now(),
        data: {
          'tempId': 'local-temp-uuid-42',
          'amountMinor': 499900,
          'currency': 'INR',
          'categoryId': '65b123456789012345678901',
          'description': 'Coldplay Ticket',
          'transactionDate': DateTime.now().toIso8601String(),
          'paymentMethod': 'UPI',
        },
      ),
    );

    engine.refreshPendingCount();

    expect(engine.pendingCountNotifier.value, 1);
    expect(engine.statusNotifier.value, SyncStatus.pending);

    // 3. Trigger SyncEngine.sync()
    await engine.sync();

    // 4. Verify outcomes:
    // a. Queue is now empty
    expect(queueDataSource.getPendingCount(), 0);
    expect(engine.pendingCountNotifier.value, 0);
    expect(engine.statusNotifier.value, SyncStatus.synced);

    // b. Old temporary UUID is replaced in local storage
    expect(expenseDataSource.getExpense('local-temp-uuid-42'), isNull);

    // c. New MongoDB server ObjectId exists and has SyncStatus.synced
    final reconciled =
        expenseDataSource.getExpense('65ba00112233445566778899');
    expect(reconciled, isNotNull);
    expect(reconciled!.id, '65ba00112233445566778899');
    expect(reconciled.syncStatus, SyncStatus.synced);
    expect(reconciled.merchant, 'Coldplay Ticket');
    expect(reconciled.amountPaise, 499900);

    engine.dispose();
  });

  test('SyncEngine keeps queue and updates status to failed when network errors occur', () async {
    final mockDio = Dio();
    mockDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: 'No internet connection',
            ),
          );
        },
      ),
    );

    final apiClient = ApiClient(
      authStorage: fakeAuthStorage,
      customDio: mockDio,
    );

    final engine = SyncEngine(
      syncQueueLocalDataSource: queueDataSource,
      expenseLocalDataSource: expenseDataSource,
      apiClient: apiClient,
    );

    await queueDataSource.enqueue(
      SyncOperationItem(
        operationId: 'offline-retry-op',
        action: SyncOperationType.create,
        timestamp: DateTime.now(),
        data: {'tempId': 'temp-123'},
      ),
    );

    await engine.sync();

    // Operation must remain in queue for retry when connection returns
    expect(queueDataSource.getPendingCount(), 1);
    expect(engine.statusNotifier.value, SyncStatus.failed);

    engine.dispose();
  });
}
