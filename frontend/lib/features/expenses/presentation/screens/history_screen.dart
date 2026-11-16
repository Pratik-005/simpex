import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../categories/domain/models/category.dart';
import '../../data/mock_expense_repository.dart';
import '../../domain/models/expense.dart';
import '../widgets/add_expense_bottom_sheet.dart';
import '../widgets/expense_list_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = MockExpenseRepository.instance;
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategoryFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _repository.fetchFirstPage(
      categoryId: _selectedCategoryFilter,
      startDate: _fromDate,
      endDate: _effectiveEndDate,
    );
    _scrollController.addListener(_onScroll);
  }

  DateTime? get _effectiveEndDate {
    if (_toDate == null) return null;
    return DateTime(
      _toDate!.year,
      _toDate!.month,
      _toDate!.day,
      23,
      59,
      59,
      999,
    );
  }

  void _refetchWithCurrentFilters() {
    _repository.fetchFirstPage(
      force: true,
      categoryId: _selectedCategoryFilter,
      startDate: _fromDate,
      endDate: _effectiveEndDate,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _repository.fetchNextPage(
        categoryId: _selectedCategoryFilter,
        startDate: _fromDate,
        endDate: _effectiveEndDate,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _getCategoryName(String id) {
    final found = Category.defaults.where((c) => c.id == id);
    if (found.isNotEmpty) return found.first.name;
    return id.length > 1 ? '${id[0].toUpperCase()}${id.substring(1)}' : id;
  }

  String _formatDateRangeLabel() {
    final fmt = DateFormat('MMM dd');
    if (_fromDate != null && _toDate != null) {
      return '${fmt.format(_fromDate!)} - ${fmt.format(_toDate!)}';
    } else if (_fromDate != null) {
      return 'From ${fmt.format(_fromDate!)}';
    } else {
      return 'Until ${fmt.format(_toDate!)}';
    }
  }

  Widget _buildActiveFilterPill({
    required String label,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required bool isFromDate,
    required DateTime? currentDate,
    required DateTime? otherDate,
    required void Function(DateTime?) onSelected,
  }) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020, 1, 1);
    final lastDate = DateTime(now.year + 2, 12, 31);

    final initial = currentDate ?? (otherDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(lastDate) ? lastDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: AppColors.surfaceContainerHigh,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  void _showFilterSheet() {
    DateTime? tempFromDate = _fromDate;
    DateTime? tempToDate = _toDate;
    String? tempCategoryId = _selectedCategoryFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
                        'Filter Transactions',
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
                  const SizedBox(height: 20),
                  // Date Range Section
                  Text(
                    'DATE RANGE',
                    style: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _pickDate(
                              ctx,
                              isFromDate: true,
                              currentDate: tempFromDate,
                              otherDate: tempToDate,
                              onSelected: (date) {
                                setModalState(() {
                                  tempFromDate = date;
                                  if (tempToDate != null &&
                                      tempFromDate!.isAfter(tempToDate!)) {
                                    tempToDate = tempFromDate;
                                  }
                                });
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tempFromDate != null
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From Date',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tempFromDate != null
                                            ? DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(tempFromDate!)
                                            : 'Select date',
                                        style: AppTypography.bodySm.copyWith(
                                          fontWeight: tempFromDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: tempFromDate != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _pickDate(
                              ctx,
                              isFromDate: false,
                              currentDate: tempToDate,
                              otherDate: tempFromDate,
                              onSelected: (date) {
                                setModalState(() {
                                  tempToDate = date;
                                  if (tempFromDate != null &&
                                      tempToDate!.isBefore(tempFromDate!)) {
                                    tempFromDate = tempToDate;
                                  }
                                });
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: tempToDate != null
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To Date',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tempToDate != null
                                            ? DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(tempToDate!)
                                            : 'Select date',
                                        style: AppTypography.bodySm.copyWith(
                                          fontWeight: tempToDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: tempToDate != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Categories Section (NO "All Categories" chip)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CATEGORY',
                        style: AppTypography.labelSm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        tempCategoryId == null ? 'All Included' : '1 Selected',
                        style: AppTypography.labelSm.copyWith(
                          color: tempCategoryId == null
                              ? AppColors.onSurfaceVariant
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a category to filter, or leave unselected to show all.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Render ONLY actual categories, NO "All Categories"
                      ...Category.defaults.map((c) {
                        final isSelected = tempCategoryId == c.id;
                        return ChoiceChip(
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempCategoryId = c.id;
                              } else {
                                tempCategoryId = null; // deselect
                              }
                            });
                          },
                          avatar: Icon(
                            c.icon,
                            size: 14,
                            color: isSelected
                                ? Colors.black
                                : AppColors.onSurfaceVariant,
                          ),
                          label: Text(c.name),
                          labelStyle: AppTypography.labelSm.copyWith(
                            color: isSelected
                                ? Colors.black
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          backgroundColor: AppColors.surfaceContainerLowest,
                          selectedColor: AppColors.primary,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Bottom Actions: Clear and Apply Filters
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Clear',
                          variant: AppButtonVariant.outline,
                          onPressed: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                              _selectedCategoryFilter = null;
                            });
                            _repository.fetchFirstPage(
                              force: true,
                              categoryId: null,
                              startDate: null,
                              endDate: null,
                            );
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Apply',
                          variant: AppButtonVariant.primarySolid,
                          onPressed: () {
                            setState(() {
                              _fromDate = tempFromDate;
                              _toDate = tempToDate;
                              _selectedCategoryFilter = tempCategoryId;
                            });
                            _refetchWithCurrentFilters();
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStitchTransactionDrawer(BuildContext context, Expense expense) {
    final isSynced = expense.syncStatus == SyncStatus.synced;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
        ),
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
            const SizedBox(height: 14),

            // Top Header: Category Tag & Sync Status Pill & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expense.categoryName,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSynced ? Icons.check_circle : Icons.sync,
                            size: 13,
                            color: isSynced
                                ? AppColors.primary
                                : AppColors.tertiary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isSynced ? 'Cloud Synced' : 'Pending Sync',
                            style: AppTypography.labelSm.copyWith(
                              color: isSynced
                                  ? AppColors.onSurface
                                  : AppColors.tertiary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.outline,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Merchant, Large Amount & Time/Payment
            Center(
              child: Column(
                children: [
                  Text(
                    expense.merchant,
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '-${CurrencyFormatter.formatPaise(expense.amountPaise)}',
                    style: AppTypography.displayLg.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM dd, hh:mm a').format(expense.date)} • ${expense.paymentMethod}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // AI Voice Intelligence Transcript Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.record_voice_over,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Voice Intelligence Transcript',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${expense.voiceTranscript ?? "Voice prompt: Recorded expense for ${expense.merchant}"}"',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurface,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions: Edit Details / Delete Entry
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit Details',
                    icon: Icons.edit,
                    variant: AppButtonVariant.outline,
                    height: 48,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      AddExpenseBottomSheet.show(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _repository.deleteExpense(expense.id);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${expense.merchant} deleted'),
                          backgroundColor: AppColors.surfaceContainerHighest,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Delete Entry',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
      appBar: AppHeader(title: 'Expense History'),
      body: RefreshIndicator(
        onRefresh: () async => _refetchWithCurrentFilters(),
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: ValueListenableBuilder<List<Expense>>(
          valueListenable: _repository.expensesNotifier,
          builder: (context, expenses, _) {
            final now = DateTime.now();

            // Filter by category and date
            final filteredExpenses = expenses.where((e) {
              if (_selectedCategoryFilter != null &&
                  _selectedCategoryFilter!.isNotEmpty &&
                  _selectedCategoryFilter != 'all') {
                if (e.categoryId != _selectedCategoryFilter) {
                  return false;
                }
              }
              if (_fromDate != null && e.date.isBefore(_fromDate!)) {
                return false;
              }
              if (_toDate != null &&
                  _effectiveEndDate != null &&
                  e.date.isAfter(_effectiveEndDate!)) {
                return false;
              }
              return true;
            }).toList();

            final hasActiveFilters =
                _selectedCategoryFilter != null ||
                _fromDate != null ||
                _toDate != null;

            final totalFilteredPaise = filteredExpenses.fold(
              0,
              (sum, e) => sum + e.amountPaise,
            );
            final voiceRecordedCount = filteredExpenses
                .where((e) => e.isVoiceRecorded == true)
                .length;

            // Group by date
            final Map<String, List<Expense>> groupedExpenses = {};
            for (final exp in filteredExpenses) {
              final expDate = DateTime(
                exp.date.year,
                exp.date.month,
                exp.date.day,
              );
              final nowDate = DateTime(now.year, now.month, now.day);
              final diffDays = nowDate.difference(expDate).inDays;

              String dateKey;
              if (diffDays == 0) {
                dateKey = 'Today, ${DateFormat('MMM dd').format(exp.date)}';
              } else if (diffDays == 1) {
                dateKey = 'Yesterday, ${DateFormat('MMM dd').format(exp.date)}';
              } else {
                dateKey = DateFormat('MMM dd, yyyy').format(exp.date);
              }
              groupedExpenses.putIfAbsent(dateKey, () => []).add(exp);
            }

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Filters Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (!hasActiveFilters)
                              Text(
                                'All Transactions',
                                style: AppTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            if (_selectedCategoryFilter != null) ...[
                              _buildActiveFilterPill(
                                label:
                                    'Category: ${_getCategoryName(_selectedCategoryFilter!)}',
                                onClear: () {
                                  setState(
                                    () => _selectedCategoryFilter = null,
                                  );
                                  _refetchWithCurrentFilters();
                                },
                              ),
                            ],
                            if (_fromDate != null || _toDate != null) ...[
                              _buildActiveFilterPill(
                                label: _formatDateRangeLabel(),
                                onClear: () {
                                  setState(() {
                                    _fromDate = null;
                                    _toDate = null;
                                  });
                                  _refetchWithCurrentFilters();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showFilterSheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasActiveFilters
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh,
                            border: Border.all(
                              color: hasActiveFilters
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.tune,
                              size: 16,
                              color: hasActiveFilters
                                  ? AppColors.onPrimary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Monthly Metric Summary Strip matching Stitch
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'FILTERED SPEND',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                fontSize: 10,
                              ),
                            ),
                            if (_selectedCategoryFilter != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getCategoryName(
                                    _selectedCategoryFilter!,
                                  ).toUpperCase(),
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatPaise(totalFilteredPaise),
                          style: AppTypography.displayLgMobile.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${filteredExpenses.length} records recorded ($voiceRecordedCount via Voice AI)',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                  'Up to date',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grouped Transactions List
                  if (filteredExpenses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: AppColors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching transactions found',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...groupedExpenses.entries.map((entry) {
                      final groupTitle = entry.key;
                      final groupItems = entry.value;
                      final groupSum = groupItems.fold(
                        0,
                        (sum, e) => sum + e.amountPaise,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Section Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  groupTitle,
                                  style: AppTypography.titleMd.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatPaise(groupSum),
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // List items inside group
                          ...groupItems.map((expense) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Dismissible(
                                key: ValueKey(expense.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                ),
                                onDismissed: (_) {
                                  _repository.deleteExpense(expense.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${expense.merchant} deleted',
                                      ),
                                      backgroundColor:
                                          AppColors.surfaceContainerHighest,
                                    ),
                                  );
                                },
                                child: ExpenseListItem(
                                  expense: expense,
                                  isHistoryVariant: true,
                                  onTap: () => _showStitchTransactionDrawer(
                                    context,
                                    expense,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                        ],
                      );
                    }),
                  ValueListenableBuilder<bool>(
                    valueListenable: _repository.isLoadingMoreNotifier,
                    builder: (context, isLoadingMore, _) {
                      if (isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        );
                      }

                      return const SizedBox(height: 24);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
