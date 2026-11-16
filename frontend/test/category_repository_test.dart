import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/injection/init_dependencies.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:frontend/features/categories/data/repositories/category_repository.dart';
import 'package:frontend/features/categories/domain/models/category.dart';

class _FakeCategoryRemoteDataSource implements CategoryRemoteDataSource {
  final List<Category> stored = [];

  @override
  Future<List<Category>> getCategories() async {
    return List<Category>.from(stored);
  }

  @override
  Future<Category> createCategory({
    required String name,
    required Color color,
    required IconData icon,
  }) async {
    final cat = Category(
      id: 'cat_${stored.length + 1}',
      name: name,
      color: color,
      icon: icon,
      isDefault: false,
    );
    stored.add(cat);
    return cat;
  }

  @override
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    Color? color,
    IconData? icon,
  }) async {
    final idx = stored.indexWhere((c) => c.id == categoryId);
    if (idx >= 0) {
      final updated = stored[idx].copyWith(
        name: name,
        color: color,
        icon: icon,
      );
      stored[idx] = updated;
      return updated;
    }
    throw Exception('Category not found');
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    stored.removeWhere((c) => c.id == categoryId);
  }
}

void main() {
  late _FakeCategoryRemoteDataSource fakeDataSource;
  late CategoryRepository repository;

  setUp(() {
    fakeDataSource = _FakeCategoryRemoteDataSource();
    if (sl.isRegistered<CategoryRemoteDataSource>()) {
      sl.unregister<CategoryRemoteDataSource>();
    }
    sl.registerSingleton<CategoryRemoteDataSource>(fakeDataSource);

    // Also register a dummy ApiClient if needed
    if (!sl.isRegistered<ApiClient>()) {
      // Mock / dummy ApiClient registration not strictly needed since fakeDataSource is registered
    }

    repository = CategoryRepository();
  });

  tearDown(() {
    if (sl.isRegistered<CategoryRemoteDataSource>()) {
      sl.unregister<CategoryRemoteDataSource>();
    }
  });

  test('CategoryRepository initializes with default categories', () {
    expect(repository.categories.length, equals(Category.defaults.length));
  });

  test(
    'CategoryRepository creates, updates, and deletes categories with notifications',
    () async {
      int notifyCount = 0;
      repository.categoriesNotifier.addListener(() {
        notifyCount++;
      });

      final created = await repository.createCategory(
        name: 'Freelance Tech',
        color: const Color(0xFF6366F1),
        icon: Icons.computer,
      );

      expect(created.name, equals('Freelance Tech'));
      expect(
        repository.categories.any((c) => c.name == 'Freelance Tech'),
        isTrue,
      );
      expect(notifyCount, greaterThanOrEqualTo(1));

      final updated = await repository.updateCategory(
        categoryId: created.id,
        name: 'Freelance Consulting',
      );

      expect(updated.name, equals('Freelance Consulting'));
      expect(
        repository.categories.any((c) => c.name == 'Freelance Consulting'),
        isTrue,
      );

      await repository.deleteCategory(created.id);
      expect(repository.categories.any((c) => c.id == created.id), isFalse);
    },
  );
}
