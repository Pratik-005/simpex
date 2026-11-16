import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/budget.dart';

class SetBudgetBottomSheet extends StatefulWidget {
  final Budget? initialBudget;

  const SetBudgetBottomSheet({super.key, this.initialBudget});

  static Future<void> show(BuildContext context, {Budget? initialBudget}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetBudgetBottomSheet(initialBudget: initialBudget),
    );
  }

  @override
  State<SetBudgetBottomSheet> createState() => _SetBudgetBottomSheetState();
}

class _SetBudgetBottomSheetState extends State<SetBudgetBottomSheet> {
  final _amountController = TextEditingController();
  final _repository = BudgetRepository.instance;

  String _currencyCode = 'INR';
  String _currencySymbol = '₹';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserCurrency();

    final budget = widget.initialBudget ?? _repository.currentBudget;
    if (budget != null && budget.amountPaise > 0) {
      final double amt = budget.amountPaise / 100;
      _amountController.text = amt == amt.roundToDouble()
          ? amt.toInt().toString()
          : amt.toString();
    }
  }

  void _loadUserCurrency() {
    try {
      if (sl.isRegistered<AuthStorage>()) {
        final user = sl<AuthStorage>().getUser();
        if (user != null && user.currency.isNotEmpty) {
          final item = CurrencyConstants.find(user.currency);
          setState(() {
            _currencyCode = item.code;
            _currencySymbol = item.symbol;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitBudget() async {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a budget amount');
      return;
    }

    final double? parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      setState(() => _errorMessage = 'Please enter a valid positive number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int amountPaise = (parsed * 100).round();
      await _repository.setBudget(amountPaise);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${DateFormat('MMMM').format(DateTime.now())} budget set to ${CurrencyFormatter.formatPaise(amountPaise)}',
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
            ),
            backgroundColor: AppColors.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to set budget. Please try again.';
        });
      }
    }
  }

  List<int> get _quickSuggestions => [
    5000,
    10000,
    15000,
    20000,
    25000,
    50000,
    75000,
    100000,
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final isEditing = widget.initialBudget != null || _repository.hasBudget;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing
                          ? 'Edit $monthName Budget'
                          : 'Set $monthName Budget',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Monthly target for ${DateFormat('MMMM yyyy').format(now)}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
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
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Input Field
            AppTextField(
              controller: _amountController,
              label: 'Monthly Budget Amount ($_currencyCode)',
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIconWidget: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 12, right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _currencySymbol,
                    style: AppTypography.titleMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: AppTypography.labelSm.copyWith(color: AppColors.error),
              ),
            ],

            const SizedBox(height: 14),

            // Quick Suggestion Chips
            Text(
              'Quick Select',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickSuggestions.map((amt) {
                final isSelected =
                    _amountController.text.trim() == amt.toString();
                return InkWell(
                  onTap: () {
                    setState(() {
                      _amountController.text = amt.toString();
                      _errorMessage = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      '$_currencySymbol${NumberFormat.decimalPattern().format(amt)}',
                      style: AppTypography.labelSm.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Informative Context Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This budget is specific to $monthName. Next month, you can set a fresh budget.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons: Cancel and Save
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outline,
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Save',
                    variant: AppButtonVariant.primarySolid,
                    isLoading: _isLoading,
                    onPressed: _submitBudget,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
