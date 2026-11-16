import 'expense.dart';

class PaginatedExpenses {
  final List<Expense> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;
  final int? nextPage;

  const PaginatedExpenses({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
    this.nextPage,
  });

  factory PaginatedExpenses.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final List<Expense> items;
    if (rawList is List) {
      items = rawList
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      items = [];
    }

    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    final page = (pagination['page'] as num?)?.toInt() ?? 1;
    final total = (pagination['total'] as num?)?.toInt() ?? items.length;
    final limit = (pagination['limit'] as num?)?.toInt() ?? 20;
    final totalPages = (pagination['totalPages'] as num?)?.toInt() ??
        (limit > 0 ? (total / limit).ceil() : 1);
    final hasMore = pagination['hasMore'] as bool? ?? (page < totalPages);
    final nextPage = (pagination['nextPage'] as num?)?.toInt();

    return PaginatedExpenses(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasMore: hasMore,
      nextPage: nextPage,
    );
  }
}
