import 'package:flutter/foundation.dart' hide Category;
import '../../../../core/database/hive_service.dart';
import '../../domain/models/category.dart';

abstract class CategoryLocalDataSource {
  List<Category> getCategories();
  Future<void> saveCategories(List<Category> categories);
  Future<void> clear();
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final HiveService hiveService;

  CategoryLocalDataSourceImpl({required this.hiveService});

  @override
  List<Category> getCategories() {
    final rawList = hiveService.categoriesBox.values;
    final List<Category> categories = [];

    for (final raw in rawList) {
      try {
        final map = Map<String, dynamic>.from(raw);
        categories.add(Category.fromJson(map));
      } catch (e) {
        debugPrint('[CategoryLocalDataSource] Error parsing category: $e');
      }
    }

    return categories;
  }

  @override
  Future<void> saveCategories(List<Category> categories) async {
    final entries = <String, Map<String, dynamic>>{};
    for (final cat in categories) {
      entries[cat.id] = {
        'id': cat.id,
        'name': cat.name,
        'icon': Category.iconToKey(cat.icon),
        'color': Category.colorToHex(cat.color),
        'isDefault': cat.isDefault,
        'totalSpendPaise': cat.totalSpendPaise,
        'transactionCount': cat.transactionCount,
      };
    }
    await hiveService.categoriesBox.putAll(entries);
  }

  @override
  Future<void> clear() async {
    await hiveService.categoriesBox.clear();
  }
}
