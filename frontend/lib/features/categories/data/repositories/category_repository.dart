import 'package:flutter/material.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/category.dart';
import '../datasources/category_local_data_source.dart';
import '../datasources/category_remote_data_source.dart';

class CategoryRepository {
  CategoryRepository() {
    initFromCache();
  }

  static final CategoryRepository instance = CategoryRepository();

  void initFromCache() {
    if (sl.isRegistered<CategoryLocalDataSource>()) {
      final cached = sl<CategoryLocalDataSource>().getCategories();
      if (cached.isNotEmpty) {
        categoriesNotifier.value = cached;
      }
    }
  }

  final ValueNotifier<List<Category>> categoriesNotifier =
      ValueNotifier<List<Category>>(List<Category>.from(Category.defaults));
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  bool _hasFetched = false;
  bool get hasFetched => _hasFetched;

  List<Category> get categories => categoriesNotifier.value;

  CategoryRemoteDataSource _getDataSource() {
    return sl.isRegistered<CategoryRemoteDataSource>()
        ? sl<CategoryRemoteDataSource>()
        : CategoryRemoteDataSourceImpl(apiClient: sl<ApiClient>());
  }

  Future<List<Category>> fetchCategories({bool forceRefresh = false}) async {
    if (_hasFetched && !forceRefresh && categoriesNotifier.value.isNotEmpty) {
      return categoriesNotifier.value;
    }
    if (!sl.isRegistered<ApiClient>()) return categoriesNotifier.value;

    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final dataSource = _getDataSource();
      final remoteList = await dataSource.getCategories();
      if (remoteList.isNotEmpty) {
        categoriesNotifier.value = remoteList;
        _hasFetched = true;
        if (sl.isRegistered<CategoryLocalDataSource>()) {
          await sl<CategoryLocalDataSource>().saveCategories(remoteList);
        }
      }
      return categoriesNotifier.value;
    } catch (e) {
      debugPrint('[CategoryRepository] fetchCategories error: $e');
      errorNotifier.value = e.toString();
      return categoriesNotifier.value;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<Category> createCategory({
    required String name,
    required Color color,
    required IconData icon,
  }) async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final dataSource = _getDataSource();
      final created = await dataSource.createCategory(
        name: name,
        color: color,
        icon: icon,
      );

      final current = List<Category>.from(categoriesNotifier.value);
      final idx = current.indexWhere((c) => c.id == created.id);
      if (idx >= 0) {
        current[idx] = created;
      } else {
        current.add(created);
      }
      categoriesNotifier.value = current;
      if (sl.isRegistered<CategoryLocalDataSource>()) {
        await sl<CategoryLocalDataSource>().saveCategories(current);
      }
      return created;
    } catch (e) {
      errorNotifier.value = e.toString();
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    Color? color,
    IconData? icon,
  }) async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final dataSource = _getDataSource();
      final updated = await dataSource.updateCategory(
        categoryId: categoryId,
        name: name,
        color: color,
        icon: icon,
      );

      final current = List<Category>.from(categoriesNotifier.value);
      final idx = current.indexWhere((c) => c.id == categoryId);
      if (idx >= 0) {
        current[idx] = updated;
      } else {
        current.add(updated);
      }
      categoriesNotifier.value = current;
      if (sl.isRegistered<CategoryLocalDataSource>()) {
        await sl<CategoryLocalDataSource>().saveCategories(current);
      }
      return updated;
    } catch (e) {
      errorNotifier.value = e.toString();
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    isLoadingNotifier.value = true;
    errorNotifier.value = null;

    try {
      final dataSource = _getDataSource();
      await dataSource.deleteCategory(categoryId);

      final current = List<Category>.from(categoriesNotifier.value);
      current.removeWhere((c) => c.id == categoryId);
      categoriesNotifier.value = current;
      if (sl.isRegistered<CategoryLocalDataSource>()) {
        await sl<CategoryLocalDataSource>().saveCategories(current);
      }
    } catch (e) {
      errorNotifier.value = e.toString();
      rethrow;
    } finally {
      isLoadingNotifier.value = false;
    }
  }
}
