import '../../../../core/database/hive_service.dart';
import '../../domain/models/sync_operation.dart';

abstract class SyncQueueLocalDataSource {
  Future<void> enqueue(SyncOperationItem item);
  List<SyncOperationItem> getPendingOperations();
  Future<void> remove(String operationId);
  int getPendingCount();
  Future<void> clear();
}

class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  final HiveService hiveService;

  SyncQueueLocalDataSourceImpl({required this.hiveService});

  @override
  Future<void> enqueue(SyncOperationItem item) async {
    await hiveService.syncQueueBox.put(item.operationId, item.toJson());
  }

  @override
  List<SyncOperationItem> getPendingOperations() {
    final rawList = hiveService.syncQueueBox.values;
    final operations = <SyncOperationItem>[];

    for (final raw in rawList) {
      operations.add(
        SyncOperationItem.fromJson(Map<String, dynamic>.from(raw)),
      );
    }

    // Sort chronologically so mutations play in proper order
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  @override
  Future<void> remove(String operationId) async {
    await hiveService.syncQueueBox.delete(operationId);
  }

  @override
  int getPendingCount() {
    return hiveService.syncQueueBox.length;
  }

  @override
  Future<void> clear() async {
    await hiveService.syncQueueBox.clear();
  }
}
