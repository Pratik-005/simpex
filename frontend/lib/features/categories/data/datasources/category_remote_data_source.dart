import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/category.dart';

abstract class CategoryRemoteDataSource {
  Future<List<Category>> getCategories();
  Future<Category> createCategory({
    required String name,
    required Color color,
    required IconData icon,
  });
  Future<void> deleteCategory(String categoryId);
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    Color? color,
    IconData? icon,
  });
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient apiClient;

  CategoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<Category>> getCategories() async {
    final response = await apiClient.dio.get(ApiConstants.categories);
    final rawData = response.data['data'];
    if (rawData is List) {
      return rawData
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Category> createCategory({
    required String name,
    required Color color,
    required IconData icon,
  }) async {
    final response = await apiClient.dio.post(
      ApiConstants.categories,
      data: {
        'name': name.trim(),
        'color': Category.colorToHex(color),
        'icon': Category.iconToKey(icon),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return Category.fromJson(data);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await apiClient.dio.delete('${ApiConstants.categories}/$categoryId');
  }

  @override
  Future<Category> updateCategory({
    required String categoryId,
    String? name,
    Color? color,
    IconData? icon,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name.trim();
    if (color != null) data['color'] = Category.colorToHex(color);
    if (icon != null) data['icon'] = Category.iconToKey(icon);

    final response = await apiClient.dio.patch(
      '${ApiConstants.categories}/$categoryId',
      data: data,
    );
    final respData = response.data['data'] as Map<String, dynamic>;
    return Category.fromJson(respData);
  }
}
