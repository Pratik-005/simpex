import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String expensesBoxName = 'expenses_box';
  static const String syncQueueBoxName = 'sync_queue_box';
  static const String categoriesBoxName = 'categories_box';
  static const String budgetBoxName = 'budget_box';

  Box<Map>? _expensesBox;
  Box<Map>? _syncQueueBox;
  Box<Map>? _categoriesBox;
  Box<Map>? _budgetBox;

  Box<Map> get expensesBox {
    if (_expensesBox == null || !_expensesBox!.isOpen) {
      throw StateError('HiveService expensesBox is not open. Call init() first.');
    }
    return _expensesBox!;
  }

  Box<Map> get syncQueueBox {
    if (_syncQueueBox == null || !_syncQueueBox!.isOpen) {
      throw StateError('HiveService syncQueueBox is not open. Call init() first.');
    }
    return _syncQueueBox!;
  }

  Box<Map> get categoriesBox {
    if (_categoriesBox == null || !_categoriesBox!.isOpen) {
      throw StateError('HiveService categoriesBox is not open. Call init() first.');
    }
    return _categoriesBox!;
  }

  Box<Map> get budgetBox {
    if (_budgetBox == null || !_budgetBox!.isOpen) {
      throw StateError('HiveService budgetBox is not open. Call init() first.');
    }
    return _budgetBox!;
  }

  Future<void> init([String? customPath]) async {
    try {
      if (customPath != null) {
        Hive.init(customPath);
      } else {
        await Hive.initFlutter();
      }

      _expensesBox = await Hive.openBox<Map>(expensesBoxName);
      _syncQueueBox = await Hive.openBox<Map>(syncQueueBoxName);
      _categoriesBox = await Hive.openBox<Map>(categoriesBoxName);
      _budgetBox = await Hive.openBox<Map>(budgetBoxName);
    } catch (e, st) {
      debugPrint('Error initializing HiveService: $e\n$st');
      rethrow;
    }
  }

  /// Clean all local boxes (useful on user logout or clear-data)
  Future<void> clearAll() async {
    await Future.wait([
      if (_expensesBox != null && _expensesBox!.isOpen) _expensesBox!.clear(),
      if (_syncQueueBox != null && _syncQueueBox!.isOpen) _syncQueueBox!.clear(),
      if (_categoriesBox != null && _categoriesBox!.isOpen) _categoriesBox!.clear(),
      if (_budgetBox != null && _budgetBox!.isOpen) _budgetBox!.clear(),
    ]);
  }

  Future<void> close() async {
    await Future.wait([
      if (_expensesBox != null && _expensesBox!.isOpen) _expensesBox!.close(),
      if (_syncQueueBox != null && _syncQueueBox!.isOpen) _syncQueueBox!.close(),
      if (_categoriesBox != null && _categoriesBox!.isOpen) _categoriesBox!.close(),
      if (_budgetBox != null && _budgetBox!.isOpen) _budgetBox!.close(),
    ]);
  }
}
