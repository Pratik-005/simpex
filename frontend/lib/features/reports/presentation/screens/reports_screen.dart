import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../budget/data/repositories/budget_repository.dart';
import '../../../budget/domain/models/budget.dart';
import '../../../categories/domain/models/category.dart';
import '../../../expenses/data/mock_expense_repository.dart';
import '../../../expenses/domain/models/expense.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repository = MockExpenseRepository.instance;
  final _budgetRepository = BudgetRepository.instance;
  final ScrollController _scrollController = ScrollController();

  late DateTime _selectedDate;
  int _selectedBarIndex = 0;
  bool _isExpandedView = false;

  Budget? _selectedMonthBudget;
  List<Expense> _monthExpenses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, 1);
    _selectedBarIndex = (now.day - 1).clamp(0, 30);
    _loadDataForSelectedMonth();
    _repository.expensesNotifier.addListener(_onExpensesChanged);
  }

  @override
  void dispose() {
    _repository.expensesNotifier.removeListener(_onExpensesChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onExpensesChanged() {
    if (mounted) {
      _loadDataForSelectedMonth();
    }
  }

  Future<void> _loadDataForSelectedMonth() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _budgetRepository.getBudgetForMonth(
          month: _selectedDate.month,
          year: _selectedDate.year,
        ),
        _repository.getExpensesForMonth(
          year: _selectedDate.year,
          month: _selectedDate.month,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _selectedMonthBudget = results[0] as Budget?;
        _monthExpenses = results[1] as List<Expense>;
        final daysInMonth = DateUtils.getDaysInMonth(
          _selectedDate.year,
          _selectedDate.month,
        );
        if (_selectedBarIndex >= daysInMonth) {
          _selectedBarIndex = daysInMonth - 1;
        }
      });
    } catch (_) {
      // Gracefully maintain state on failure
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    _loadDataForSelectedMonth();
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _selectedDate.year < now.year ||
        (_selectedDate.year == now.year && _selectedDate.month < now.month);
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    _loadDataForSelectedMonth();
  }

  void _showMonthYearPicker() {
    int pickerYear = _selectedDate.year;
    int pickerMonth = _selectedDate.month;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          final now = DateTime.now();
          final canIncrementYear = pickerYear < now.year;
          final months = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.cardBorder),
                left: BorderSide(color: AppColors.cardBorder),
                right: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month & Year',
                        style: AppTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Year Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: AppColors.onSurface,
                          ),
                          onPressed: () {
                            setPickerState(() => pickerYear--);
                          },
                        ),
                        Text(
                          '$pickerYear',
                          style: AppTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: canIncrementYear
                                ? AppColors.onSurface
                                : AppColors.onSurface.withValues(alpha: 0.25),
                          ),
                          onPressed: canIncrementYear
                              ? () {
                                  setPickerState(() => pickerYear++);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Months Grid (3 columns, 4 rows)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNum = index + 1;
                      final isFutureMonth = (pickerYear > now.year) ||
                          (pickerYear == now.year && monthNum > now.month);
                      final isSelected = !isFutureMonth &&
                          (monthNum == pickerMonth) &&
                          (pickerYear == _selectedDate.year);
                      final monthName = months[index];

                      if (isFutureMonth) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  AppColors.cardBorder.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthName.substring(0, 3),
                            style: AppTypography.labelSm.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  AppColors.outline.withValues(alpha: 0.35),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return InkWell(
                        onTap: () {
                          setPickerState(() {
                            pickerMonth = monthNum;
                          });
                          Navigator.of(ctx).pop();
                          setState(() {
                            _selectedDate = DateTime(pickerYear, monthNum, 1);
                          });
                          _loadDataForSelectedMonth();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthName.substring(0, 3),
                            style: AppTypography.labelSm.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Generates velocity data for all days of the selected month (1..daysInMonth)
  List<Map<String, dynamic>> _generateDailyVelocity(
    int daysInMonth,
    List<Expense> expenses,
  ) {
    final Map<int, int> spendByDay = {};

    // 1. Map real expenses for the selected month to their day
    for (final exp in expenses) {
      if (exp.date.year == _selectedDate.year &&
          exp.date.month == _selectedDate.month) {
        final day = exp.date.day;
        if (day >= 1 && day <= daysInMonth) {
          spendByDay[day] = (spendByDay[day] ?? 0) + exp.amountPaise;
        }
      }
    }

    // 2. Find monthly peak dynamically from real expenses
    int maxPaise = 0;
    int peakDay = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final amt = spendByDay[d] ?? 0;
      if (amt > maxPaise) {
        maxPaise = amt;
        peakDay = d;
      }
    }

    final monthShort = DateFormat('MMM').format(_selectedDate);

    // 3. Construct day points for all days (1..daysInMonth)
    final List<Map<String, dynamic>> result = [];
    for (int d = 1; d <= daysInMonth; d++) {
      final amt = spendByDay[d] ?? 0;
      final dayStr = d.toString().padLeft(2, '0');
      final isPeak = (peakDay > 0 && d == peakDay && amt > 0);
      final ratio = maxPaise > 0 && amt > 0
          ? (amt / maxPaise).clamp(0.08, 1.0)
          : 0.04;

      result.add({
        'day': dayStr,
        'dayNum': d,
        'label': '$monthShort $dayStr',
        'amountPaise': amt,
        'ratio': ratio,
        'isPeak': isPeak,
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat('MMMM yyyy').format(_selectedDate);
    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedDate.year,
      _selectedDate.month,
    );

    // Real Total Spend calculation strictly from selected month's expenses
    final totalSpendPaise = _monthExpenses.fold<int>(
      0,
      (sum, e) => sum + e.amountPaise,
    );
    final budgetPaise = _selectedMonthBudget?.amountPaise ?? 0;

    final dailyVelocityData = _generateDailyVelocity(
      daysInMonth,
      _monthExpenses,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Expense Reports',
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module 1: Period Navigation Bar
                _buildPeriodNavigationBar(monthTitle, daysInMonth),
                const SizedBox(height: 16),

                // Module 2: Hero Spend Summary Module
                _buildHeroSpendSummary(
                  totalSpendPaise: totalSpendPaise,
                  budgetPaise: budgetPaise,
                ),
                const SizedBox(height: 16),

                // Module 3: Daily Velocity Spending Chart
                _buildDailyVelocityChart(dailyVelocityData, daysInMonth),
                const SizedBox(height: 16),

                // Module 4: Category Allocation Module
                _buildCategoryAllocation(totalSpendPaise, _monthExpenses),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
                minHeight: 2.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodNavigationBar(String monthTitle, int daysInMonth) {
    final canGoNext = _canGoNext;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: _previousMonth,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainer,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: _showMonthYearPicker,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            monthTitle,
                            style: AppTypography.titleMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$daysInMonth Days Consolidated • Tap to change',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: canGoNext ? _nextMonth : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canGoNext
                    ? AppColors.surfaceContainer
                    : AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                border: Border.all(
                  color: canGoNext
                      ? AppColors.cardBorder
                      : AppColors.cardBorder.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: canGoNext
                      ? AppColors.onSurface
                      : AppColors.onSurface.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSpendSummary({
    required int totalSpendPaise,
    required int budgetPaise,
  }) {
    final hasBudget = budgetPaise > 0;
    final remainingPaise = budgetPaise - totalSpendPaise;
    final budgetRatio = hasBudget
        ? (totalSpendPaise / budgetPaise).clamp(0.0, 1.0)
        : 0.0;
    final isWithinBudget = totalSpendPaise <= budgetPaise;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Ambient Glow Orbs from Stitch
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer.withValues(alpha: 0.12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL NET SPEND',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      CurrencyFormatter.formatPaise(totalSpendPaise),
                      style: AppTypography.displayLgMobile.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasBudget
                          ? '/ ${CurrencyFormatter.formatPaise(budgetPaise)} budget'
                          : '/ No budget set',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Compact Budget Progress Bar matching Stitch
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: hasBudget ? budgetRatio : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Budget remaining and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        hasBudget
                            ? (remainingPaise >= 0
                                ? 'Remaining: ${CurrencyFormatter.formatPaise(remainingPaise)}'
                                : 'Exceeded by: ${CurrencyFormatter.formatPaise(remainingPaise.abs())}')
                            : 'No budget target configured',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasBudget)
                      Text(
                        isWithinBudget ? 'Within Safe Limits' : 'Budget Exceeded',
                        style: AppTypography.labelSm.copyWith(
                          color: isWithinBudget
                              ? AppColors.primary
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      )
                    else
                      Text(
                        'Unbudgeted',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
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
  }

  Widget _buildDailyVelocityChart(
    List<Map<String, dynamic>> dailyData,
    int daysInMonth,
  ) {
    final safeIndex = dailyData.isEmpty
        ? 0
        : _selectedBarIndex.clamp(0, dailyData.length - 1);
    final selectedItem = dailyData.isNotEmpty ? dailyData[safeIndex] : null;

    final peakItem = dailyData.firstWhere(
      (item) => item['isPeak'] == true,
      orElse: () => {
        'label': 'None',
        'amountPaise': 0,
        'isPeak': false,
      },
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Daily Velocity & Peak Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Velocity',
                      style: AppTypography.titleMd.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All $daysInMonth days • Tap or scrub to inspect',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: peakItem['isPeak'] == true
                            ? AppColors.tertiary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      peakItem['isPeak'] == true
                          ? 'Peak: ${peakItem['label']}'
                          : 'No Peak',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Selected Tooltip Pill & View Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (selectedItem != null &&
                              selectedItem['isPeak'] == true)
                          ? AppColors.tertiaryContainer.withValues(alpha: 0.6)
                          : AppColors.primary.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (selectedItem != null &&
                                  selectedItem['isPeak'] == true)
                              ? AppColors.tertiary
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          selectedItem != null
                              ? '${selectedItem['label']}: ${selectedItem['amountPaise'] > 0 ? CurrencyFormatter.formatPaise(selectedItem['amountPaise']) : "₹0 (No spend)"}'
                              : 'No spend',
                          style: AppTypography.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpandedView = !_isExpandedView;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isExpandedView
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isExpandedView
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isExpandedView
                            ? Icons.calendar_view_month
                            : Icons.view_week_outlined,
                        size: 13,
                        color: _isExpandedView
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isExpandedView ? 'Overview' : 'Expand',
                        style: AppTypography.labelSm.copyWith(
                          color: _isExpandedView
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Render Bars: All Days Fit Overview OR Scrollable Expanded Mode
          _isExpandedView
              ? _buildExpandedScrollableBars(dailyData, safeIndex)
              : _buildAllDaysFitBars(dailyData, daysInMonth, safeIndex),
        ],
      ),
    );
  }

  /// Full-month fit view displaying all 31 days side-by-side with touch scrubbing
  Widget _buildAllDaysFitBars(
    List<Map<String, dynamic>> dailyData,
    int daysInMonth,
    int safeIndex,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final fraction =
                (details.localPosition.dx / totalWidth).clamp(0.0, 0.999);
            final tappedIndex = (fraction * daysInMonth).floor();
            setState(() => _selectedBarIndex = tappedIndex);
          },
          onHorizontalDragUpdate: (details) {
            final fraction =
                (details.localPosition.dx / totalWidth).clamp(0.0, 0.999);
            final dragIndex = (fraction * daysInMonth).floor();
            setState(() => _selectedBarIndex = dragIndex);
          },
          child: Column(
            children: [
              SizedBox(
                height: 125,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(daysInMonth, (index) {
                    final item = dailyData[index];
                    final isSelected = index == safeIndex;
                    final isPeak = item['isPeak'] as bool;
                    final ratio = item['ratio'] as double;
                    final hasSpend = (item['amountPaise'] as int) > 0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: ratio,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isPeak
                                    ? AppColors.tertiaryContainer
                                    : isSelected
                                        ? AppColors.primary
                                        : hasSpend
                                            ? AppColors.surfaceContainerHighest
                                            : AppColors.surfaceContainerHigh
                                                .withValues(alpha: 0.5),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2.5),
                                ),
                                boxShadow: isPeak
                                    ? [
                                        BoxShadow(
                                          color: AppColors.tertiaryContainer
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),

              // Timeline Axis Markers across the full month
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: {1, 5, 10, 15, 20, 25, daysInMonth}.map((dayNum) {
                  final isHighlighted = (safeIndex + 1) == dayNum;
                  return Text(
                    dayNum.toString().padLeft(2, '0'),
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 10,
                      fontWeight:
                          isHighlighted ? FontWeight.w700 : FontWeight.w500,
                      color: isHighlighted
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Scrollable expanded view for comfortable inspection of every single day
  Widget _buildExpandedScrollableBars(
    List<Map<String, dynamic>> dailyData,
    int safeIndex,
  ) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dailyData.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = dailyData[index];
          final isSelected = index == safeIndex;
          final isPeak = item['isPeak'] as bool;
          final ratio = item['ratio'] as double;
          final hasSpend = (item['amountPaise'] as int) > 0;

          return InkWell(
            onTap: () => setState(() => _selectedBarIndex = index),
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isSelected ? 10 : 8,
                          decoration: BoxDecoration(
                            color: isPeak
                                ? AppColors.tertiaryContainer
                                : isSelected
                                    ? AppColors.primary
                                    : hasSpend
                                        ? AppColors.surfaceContainerHighest
                                        : AppColors.surfaceContainerHigh
                                            .withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                            boxShadow: isPeak
                                ? [
                                    BoxShadow(
                                      color: AppColors.tertiaryContainer
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.4),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['day'],
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 10,
                      fontWeight: isSelected || isPeak
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isPeak
                          ? AppColors.tertiary
                          : isSelected
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryAllocation(
    int totalSpendPaise,
    List<Expense> monthExpenses,
  ) {
    // Dynamically group expenses by category for the selected month
    final Map<String, int> catAmounts = {};
    final Map<String, String> catNames = {};
    for (final exp in monthExpenses) {
      catAmounts[exp.categoryId] =
          (catAmounts[exp.categoryId] ?? 0) + exp.amountPaise;
      if (exp.categoryName.isNotEmpty) {
        catNames[exp.categoryId] = exp.categoryName;
      }
    }

    final List<Map<String, dynamic>> allocationData = [];
    for (final entry in catAmounts.entries) {
      final catId = entry.key;
      final amount = entry.value;
      final percent = totalSpendPaise > 0
          ? ((amount / totalSpendPaise) * 100).round()
          : 0;

      Category? matched;
      for (final def in Category.defaults) {
        if (def.id == catId ||
            def.name.toLowerCase() == (catNames[catId] ?? '').toLowerCase()) {
          matched = def;
          break;
        }
      }

      allocationData.add({
        'name': catNames[catId] ?? matched?.name ?? 'Other',
        'percentage': percent,
        'amountPaise': amount,
        'icon': matched?.icon ?? Icons.category_outlined,
        'color': matched?.color ?? AppColors.primary,
      });
    }

    allocationData.sort(
      (a, b) => (b['amountPaise'] as int).compareTo(a['amountPaise'] as int),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pie_chart,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Category Allocation',
                    style: AppTypography.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '${allocationData.length} Categories',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (allocationData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.pie_chart_outline,
                      size: 40,
                      color: AppColors.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No category expenses recorded for this month',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allocationData.length,
              separatorBuilder: (_, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final cat = allocationData[index];
                final catColor = cat['color'] as Color;
                final catIcon = cat['icon'] as IconData;
                final percent = cat['percentage'] as int;
                final amountPaise = cat['amountPaise'] as int;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Icon(catIcon, size: 14, color: catColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  cat['name'],
                                  style: AppTypography.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$percent%',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.formatPaise(amountPaise),
                          style: AppTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress Bar
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (percent / 100.0).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: catColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }


}
