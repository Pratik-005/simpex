import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/network/api_client.dart';
import '../../../budget/data/repositories/budget_repository.dart';
import '../../../expenses/data/datasources/expense_local_data_source.dart';
import '../../../expenses/data/mock_expense_repository.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../data/datasources/sync_queue_local_data_source.dart';
import '../models/sync_operation.dart';

class SyncEngine {
  final SyncQueueLocalDataSource syncQueueLocalDataSource;
  final ExpenseLocalDataSource expenseLocalDataSource;
  final ApiClient apiClient;

  final ValueNotifier<SyncStatus> statusNotifier = ValueNotifier<SyncStatus>(
    SyncStatus.synced,
  );
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  bool _isDisposed = false;

  SyncEngine({
    required this.syncQueueLocalDataSource,
    required this.expenseLocalDataSource,
    required this.apiClient,
  }) {
    refreshPendingCount();
  }

  void refreshPendingCount() {
    final count = syncQueueLocalDataSource.getPendingCount();
    pendingCountNotifier.value = count;
    if (count == 0) {
      statusNotifier.value = SyncStatus.synced;
    } else if (statusNotifier.value != SyncStatus.failed) {
      statusNotifier.value = SyncStatus.pending;
    }
  }

  Future<void> sync() async {
    if (isSyncingNotifier.value || _isDisposed) return;

    final pendingOps = syncQueueLocalDataSource.getPendingOperations();
    if (pendingOps.isEmpty) {
      refreshPendingCount();
      return;
    }

    isSyncingNotifier.value = true;
    statusNotifier.value = SyncStatus.pending;

    bool hadAnySuccess = false;

    try {
      // Process in batches of 50 operations
      const batchSize = 50;
      for (var i = 0; i < pendingOps.length; i += batchSize) {
        final end = (i + batchSize < pendingOps.length)
            ? i + batchSize
            : pendingOps.length;
        final batch = pendingOps.sublist(i, end);

        final payload = {'operations': batch.map((op) => op.toJson()).toList()};

        final response = await apiClient.dio.post(
          ApiConstants.syncBatch,
          data: payload,
        );

        if (response.statusCode == 200 && response.data != null) {
          final resData = response.data['data'] as Map<String, dynamic>?;
          final results = resData?['results'] as List<dynamic>? ?? [];

          for (final rawResult in results) {
            if (rawResult is! Map<String, dynamic>) continue;

            final opId = rawResult['operationId']?.toString() ?? '';
            final status = rawResult['status']?.toString() ?? '';
            final serverId = rawResult['entityId']?.toString();
            final action = rawResult['action']?.toString() ?? '';

            // Find matching original operation
            final originalOp = batch.firstWhere(
              (o) => o.operationId == opId,
              orElse: () => SyncOperationItem(
                operationId: opId,
                action: SyncOperationType.create,
                timestamp: DateTime.now(),
                data: const {},
              ),
            );

            if (status == 'synced' || status == 'duplicate') {
              hadAnySuccess = true;

              if (action == 'create' ||
                  originalOp.action == SyncOperationType.create) {
                final tempId =
                    originalOp.data['tempId']?.toString() ??
                    originalOp.data['id']?.toString() ??
                    '';
                final finalId = (serverId != null && serverId.isNotEmpty)
                    ? serverId
                    : tempId;

                // 1. Update persistent local storage
                await expenseLocalDataSource.replaceIdAndSyncStatus(
                  tempId,
                  finalId,
                  SyncStatus.synced,
                );

                // 2. Update in-memory state
                _updateInMemoryExpense(tempId, finalId, SyncStatus.synced);
              } else if (action == 'update' ||
                  originalOp.action == SyncOperationType.update) {
                final id = originalOp.data['id']?.toString() ?? '';
                await expenseLocalDataSource.updateSyncStatus(
                  id,
                  SyncStatus.synced,
                );
                _updateInMemoryStatus(id, SyncStatus.synced);
              } else if (action == 'delete' ||
                  originalOp.action == SyncOperationType.delete) {
                final id = originalOp.data['id']?.toString() ?? '';
                await expenseLocalDataSource.deleteExpense(id);
                _removeInMemoryExpense(id);
              }

              // Remove successfully processed operation from queue
              await syncQueueLocalDataSource.remove(opId);
            } else {
              // Operation failed on backend
              debugPrint(
                '[SyncEngine] Operation $opId failed: ${rawResult['error']}',
              );
              final tempId =
                  originalOp.data['tempId']?.toString() ??
                  originalOp.data['id']?.toString() ??
                  '';
              if (tempId.isNotEmpty) {
                await expenseLocalDataSource.updateSyncStatus(
                  tempId,
                  SyncStatus.failed,
                );
                _updateInMemoryStatus(tempId, SyncStatus.failed);
              }
            }
          }
        }
      }

      refreshPendingCount();

      // Refresh budget if any updates took place
      if (hadAnySuccess && sl.isRegistered<BudgetRepository>()) {
        try {
          sl<BudgetRepository>().fetchCurrentBudget();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[SyncEngine] Batch sync network/server error: $e');
      statusNotifier.value = SyncStatus.failed;
    } finally {
      isSyncingNotifier.value = false;
      refreshPendingCount();
    }
  }

  void _updateInMemoryExpense(
    String oldId,
    String newId,
    SyncStatus newStatus,
  ) {
    final notifier = MockExpenseRepository.instance.expensesNotifier;
    notifier.value = notifier.value.map((e) {
      if (e.id == oldId) {
        return e.copyWith(id: newId, syncStatus: newStatus);
      }
      return e;
    }).toList();
  }

  void _updateInMemoryStatus(String id, SyncStatus newStatus) {
    final notifier = MockExpenseRepository.instance.expensesNotifier;
    notifier.value = notifier.value.map((e) {
      if (e.id == id) {
        return e.copyWith(syncStatus: newStatus);
      }
      return e;
    }).toList();
  }

  void _removeInMemoryExpense(String id) {
    final notifier = MockExpenseRepository.instance.expensesNotifier;
    notifier.value = notifier.value.where((e) => e.id != id).toList();
  }

  void dispose() {
    _isDisposed = true;
    statusNotifier.dispose();
    pendingCountNotifier.dispose();
    isSyncingNotifier.dispose();
  }
}
