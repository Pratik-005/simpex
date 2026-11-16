abstract class SyncOperationType {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
}

class SyncOperationItem {
  final String operationId;
  final String action; // 'create' | 'update' | 'delete'
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const SyncOperationItem({
    required this.operationId,
    required this.action,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  factory SyncOperationItem.fromJson(Map<String, dynamic> json) {
    return SyncOperationItem(
      operationId: (json['operationId'] ?? '').toString(),
      action: (json['action'] ?? 'create').toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }
}
