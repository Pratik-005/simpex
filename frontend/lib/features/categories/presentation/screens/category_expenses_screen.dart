import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/category_icon_badge.dart';
import '../../../expenses/data/mock_expense_repository.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/models/category.dart';

class CategoryExpensesScreen extends StatefulWidget {
  final String? initialSelectedCategoryId;

  const CategoryExpensesScreen({
    super.key,
    this.initialSelectedCategoryId,
  });

  @override
  State<CategoryExpensesScreen> createState() => _CategoryExpensesScreenState();
}

class _CategoryExpensesScreenState extends State<CategoryExpensesScreen> {
  @override
  void initState() {
    super.initState();
    MockExpenseRepository.instance.fetchBackendExpenses();
    CategoryRepository.instance.fetchCategories();
  }

  bool _matchesCategory(Expense expense, Category category) {
    if (expense.categoryId == category.id) return true;
    final expCatName = expense.categoryName.toLowerCase().trim();
    final catName = category.name.toLowerCase().trim();
    if (expCatName == catName) return true;

    final normExp =
        expCatName.replaceAll('&', 'and').replaceAll(RegExp(r'\s+'), ' ');
    final normCat =
        catName.replaceAll('&', 'and').replaceAll(RegExp(r'\s+'), ' ');
    if (normExp == normCat) return true;
    if (normExp.contains(normCat) || normCat.contains(normExp)) return true;

    return false;
  }

  void _showCategoryTransactionsSheet(
    BuildContext context,
    Category category,
    List<Expense> expenses,
    int totalSpendPaise,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.cardBorder),
            left: BorderSide(color: AppColors.cardBorder),
            right: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CategoryIconBadge(
                  icon: category.icon,
                  color: category.color,
                  size: 40,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${expenses.length} ${expenses.length == 1 ? "transaction" : "transactions"} this month • ${CurrencyFormatter.formatPaise(totalSpendPaise)}',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 32,
                        color: AppColors.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No transactions recorded in this category this month',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: expenses.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: AppColors.cardBorder,
                    height: 1,
                  ),
                  itemBuilder: (ctx, index) {
                    final exp = expenses[index];
                    final dateStr =
                        DateFormat('MMM dd, yyyy • hh:mm a').format(exp.date);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.payment_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.merchant,
                                  style: AppTypography.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      dateStr,
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        exp.paymentMethod,
                                        style: AppTypography.labelSm.copyWith(
                                          fontSize: 9,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (exp.notes != null &&
                                    exp.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    exp.notes!,
                                    style: AppTypography.bodySm.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '- ${CurrencyFormatter.formatPaise(exp.amountPaise)}',
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Categories',
        showBackButton: true,
      ),
      body: ValueListenableBuilder<List<Expense>>(
        valueListenable: MockExpenseRepository.instance.expensesNotifier,
        builder: (context, allExpenses, _) {
          return ValueListenableBuilder<List<Category>>(
            valueListenable: CategoryRepository.instance.categoriesNotifier,
            builder: (context, allCategories, _) {
              final activeCategories = List<Category>.from(
                allCategories.isNotEmpty ? allCategories : Category.defaults,
              );

              final now = DateTime.now();
              final currentMonthExpenses = allExpenses
                  .where((e) =>
                      e.date.year == now.year && e.date.month == now.month)
                  .toList();

              final Map<String, int> spendByCatId = {};
              final Map<String, List<Expense>> expensesByCatId = {};

              for (final cat in activeCategories) {
                spendByCatId[cat.id] = 0;
                expensesByCatId[cat.id] = [];
              }

              for (final exp in currentMonthExpenses) {
                Category? matched;
                for (final cat in activeCategories) {
                  if (_matchesCategory(exp, cat)) {
                    matched = cat;
                    break;
                  }
                }
                if (matched != null) {
                  spendByCatId[matched.id] =
                      (spendByCatId[matched.id] ?? 0) + exp.amountPaise;
                  expensesByCatId[matched.id]?.add(exp);
                } else if (activeCategories.isNotEmpty) {
                  spendByCatId[activeCategories.last.id] =
                      (spendByCatId[activeCategories.last.id] ?? 0) +
                      exp.amountPaise;
                  expensesByCatId[activeCategories.last.id]?.add(exp);
                }
              }

              // Sort categories by highest spend first, second, and likewise
              activeCategories.sort((a, b) {
                final aSpend = spendByCatId[a.id] ?? 0;
                final bSpend = spendByCatId[b.id] ?? 0;
                return bSpend.compareTo(aSpend);
              });

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerHigh,
                onRefresh: () async {
                  await Future.wait([
                    MockExpenseRepository.instance.fetchBackendExpenses(),
                    CategoryRepository.instance
                        .fetchCategories(forceRefresh: true),
                  ]);
                },
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: activeCategories.length,
                  itemBuilder: (context, index) {
                    final cat = activeCategories[index];
                    final actualSpend = spendByCatId[cat.id] ?? 0;
                    final catExpenses = expensesByCatId[cat.id] ?? [];

                    return BentoCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      borderRadius: 14,
                      onTap: () {
                        _showCategoryTransactionsSheet(
                          context,
                          cat,
                          catExpenses,
                          actualSpend,
                        );
                      },
                      child: Row(
                        children: [
                          CategoryIconBadge(
                            icon: cat.icon,
                            color: cat.color,
                            size: 36,
                            iconSize: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat.name,
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  CurrencyFormatter.formatPaise(actualSpend),
                                  style: AppTypography.titleMd.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
