import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/main_shell_page.dart';
import '../../../budget/data/repositories/budget_repository.dart';
import '../../../budget/domain/models/budget.dart';
import '../../../budget/presentation/widgets/set_budget_bottom_sheet.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/screens/category_expenses_screen.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/category_icon_badge.dart';
import '../../../../core/widgets/sync_status_badge.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../sync/domain/services/sync_engine.dart';
import '../../../categories/domain/models/category.dart';
import '../../../expenses/data/mock_expense_repository.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../expenses/presentation/widgets/add_expense_bottom_sheet.dart';
import '../../../expenses/presentation/widgets/expense_list_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = MockExpenseRepository.instance;
  final _budgetRepository = BudgetRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.fetchBackendExpenses();
    _budgetRepository.fetchCurrentBudget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: 'Simpex'),
      body: RefreshIndicator(
        onRefresh: () async {
          if (sl.isRegistered<SyncEngine>()) {
            await sl<SyncEngine>().sync();
          }
          await Future.wait([
            _repository.fetchBackendExpenses(force: true),
            _budgetRepository.fetchCurrentBudget(),
          ]);
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: ValueListenableBuilder<List<Expense>>(
          valueListenable: _repository.expensesNotifier,
          builder: (context, expenses, _) {
            final now = DateTime.now();
            final currentMonthExpenses = expenses
                .where((e) =>
                    e.date.year == now.year && e.date.month == now.month)
                .toList();
            final currentMonthSpendPaise = currentMonthExpenses.fold(
                0, (sum, expense) => sum + expense.amountPaise);
            final todaySpendPaise = _repository.todaySpendPaise;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Budget Bento Card (Dynamic Not-Set vs Set)
                  ValueListenableBuilder<Budget?>(
                    valueListenable: _budgetRepository.budgetNotifier,
                    builder: (context, budget, _) {
                      final now = DateTime.now();
                      final currentMonthName = DateFormat('MMMM').format(now);

                      if (budget == null) {
                        return BentoCard(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 20,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${currentMonthName.toUpperCase()} BUDGET',
                                    style: AppTypography.labelSm.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.tertiary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 13,
                                          color: AppColors.tertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Not Set',
                                          style: AppTypography.labelSm.copyWith(
                                            color: AppColors.tertiary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.savings_outlined,
                                      size: 22,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'No budget set for $currentMonthName',
                                          style: AppTypography.titleMd.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tap to set a monthly limit and track safe spend.',
                                          style: AppTypography.bodySm.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () =>
                                        SetBudgetBottomSheet.show(context),
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      final monthlyBudgetPaise = budget.amountPaise;
                      final budgetUsageRatio =
                          budget.usageRatio(currentMonthSpendPaise);
                      final safeRemainingPaise =
                          budget.remainingPaise(currentMonthSpendPaise);
                      final daysLeft = budget.daysRemaining;

                      return BentoCard(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 20,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${currentMonthName.toUpperCase()} TOTAL BUDGET',
                                  style: AppTypography.labelSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (budgetUsageRatio > 0.9
                                                ? AppColors.error
                                                : (budgetUsageRatio > 0.75
                                                    ? AppColors.tertiary
                                                    : AppColors.primary))
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            budgetUsageRatio > 0.9
                                                ? Icons.warning_amber_rounded
                                                : Icons.trending_up,
                                            size: 14,
                                            color: budgetUsageRatio > 0.9
                                                ? AppColors.error
                                                : (budgetUsageRatio > 0.75
                                                    ? AppColors.tertiary
                                                    : AppColors.primary),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${(budgetUsageRatio * 100).toStringAsFixed(1)}%',
                                            style: AppTypography.labelSm.copyWith(
                                              color: budgetUsageRatio > 0.9
                                                  ? AppColors.error
                                                  : (budgetUsageRatio > 0.75
                                                      ? AppColors.tertiary
                                                      : AppColors.primary),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => SetBudgetBottomSheet.show(
                                        context,
                                        initialBudget: budget,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors
                                              .surfaceContainerLowest,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.cardBorder,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          size: 14,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  CurrencyFormatter.formatPaise(currentMonthSpendPaise),
                                  style:
                                      AppTypography.displayLgMobile.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '/${CurrencyFormatter.formatPaise(monthlyBudgetPaise)}',
                                  style: AppTypography.headlineSm.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Gradient Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 8,
                                width: double.infinity,
                                color: AppColors.surfaceContainerLowest,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: budgetUsageRatio,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: budgetUsageRatio > 0.9
                                            ? const [
                                                AppColors.error,
                                                AppColors.errorContainer,
                                              ]
                                            : const [
                                                AppColors.primary,
                                                AppColors.surfaceTint,
                                                AppColors.tertiary,
                                              ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${CurrencyFormatter.formatPaise(safeRemainingPaise)} safe remaining',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '$daysLeft ${daysLeft == 1 ? "day" : "days"} left',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Spent Today Bento Sub-bar
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Spent Today',
                                            style: AppTypography.bodySm.copyWith(
                                              color:
                                                  AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.formatPaise(
                                              todaySpendPaise,
                                            ),
                                            style: AppTypography.headlineSm
                                                .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${currentMonthExpenses.length} logs this month',
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 14),
                // Sync Status Pill Banner
                Builder(
                  builder: (context) {
                    if (!sl.isRegistered<SyncEngine>()) {
                      return const SyncStatusBadge(status: SyncStatus.synced);
                    }
                    final engine = sl<SyncEngine>();
                    return ValueListenableBuilder<int>(
                      valueListenable: engine.pendingCountNotifier,
                      builder: (context, pendingCount, _) {
                        return ValueListenableBuilder<SyncStatus>(
                          valueListenable: engine.statusNotifier,
                          builder: (context, status, _) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: pendingCount > 0
                                  ? () => engine.sync()
                                  : null,
                              child: SyncStatusBadge(
                                status: status,
                                pendingCount: pendingCount,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Add New Transaction Primary Button
                AppButton(
                  label: 'Add New Expense',
                  icon: Icons.add,
                  variant: AppButtonVariant.primarySolid,
                  onPressed: () => AddExpenseBottomSheet.show(context),
                ),
                const SizedBox(height: 24),
                // Top Categories 2x2 Bento Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Top Categories',
                          style: AppTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '4 active',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoryExpensesScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final allCats = List<Category>.from(
                      CategoryRepository.instance.categories.isNotEmpty
                          ? CategoryRepository.instance.categories
                          : Category.defaults,
                    );

                    final Map<String, int> spendByCatId = {};
                    for (final cat in allCats) {
                      spendByCatId[cat.id] = 0;
                    }

                    for (final exp in currentMonthExpenses) {
                      Category? matched;
                      for (final cat in allCats) {
                        if (exp.categoryId == cat.id) {
                          matched = cat;
                          break;
                        }
                        final expName = exp.categoryName.toLowerCase().trim();
                        final catName = cat.name.toLowerCase().trim();
                        if (expName == catName) {
                          matched = cat;
                          break;
                        }
                        final normExp = expName
                            .replaceAll('&', 'and')
                            .replaceAll(RegExp(r'\s+'), ' ');
                        final normCat = catName
                            .replaceAll('&', 'and')
                            .replaceAll(RegExp(r'\s+'), ' ');
                        if (normExp == normCat ||
                            normExp.contains(normCat) ||
                            normCat.contains(normExp)) {
                          matched = cat;
                          break;
                        }
                      }

                      if (matched != null) {
                        spendByCatId[matched.id] =
                            (spendByCatId[matched.id] ?? 0) + exp.amountPaise;
                      } else if (allCats.isNotEmpty) {
                        spendByCatId[allCats.last.id] =
                            (spendByCatId[allCats.last.id] ?? 0) +
                            exp.amountPaise;
                      }
                    }

                    // Sort descending by highest spend first, second, third, fourth
                    allCats.sort((a, b) {
                      final aSpend = spendByCatId[a.id] ?? 0;
                      final bSpend = spendByCatId[b.id] ?? 0;
                      return bSpend.compareTo(aSpend);
                    });

                    final displayGridCats = allCats.take(4).toList();

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.2,
                          ),
                      itemCount: displayGridCats.length,
                      itemBuilder: (context, index) {
                        final cat = displayGridCats[index];
                        final actualSpend = spendByCatId[cat.id] ?? 0;
                        return BentoCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          borderRadius: 14,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryExpensesScreen(
                                  initialSelectedCategoryId: cat.id,
                                ),
                              ),
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
                                      CurrencyFormatter.formatPaise(
                                        actualSpend,
                                      ),
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
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Recent Activity Feed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        MainShellPage.switchTab(context, 1);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See History',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<bool>(
                  valueListenable: _repository.isLoadingNotifier,
                  builder: (context, isLoading, _) {
                    final recent5Expenses =
                        (List<Expense>.from(expenses)
                              ..sort((a, b) => b.date.compareTo(a.date)))
                            .take(5)
                            .toList();

                    if (isLoading && recent5Expenses.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }

                    if (recent5Expenses.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.cardBorder,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 26,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No expenses recorded yet',
                                style: AppTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent5Expenses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return ExpenseListItem(
                          expense: recent5Expenses[index],
                          showPaymentMethod: false,
                          onTap: () {
                            MainShellPage.switchTab(context, 1);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    ),
  );
}
}
