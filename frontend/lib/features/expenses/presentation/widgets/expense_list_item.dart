import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/category_icon_badge.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/expense.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final bool showPaymentMethod;
  final bool isHistoryVariant;

  const ExpenseListItem({
    super.key,
    required this.expense,
    this.onTap,
    this.showPaymentMethod = false,
    this.isHistoryVariant = false,
  });

  @override
  Widget build(BuildContext context) {
    // Find matching category color/icon or default
    final category = Category.defaults.firstWhere(
      (c) =>
          c.id == expense.categoryId ||
          c.name.toLowerCase() == expense.categoryName.toLowerCase(),
      orElse: () => const Category(
        id: 'other',
        name: 'Other',
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      ),
    );

    final resolvedColor = expense.categoryColor ?? category.color;
    final resolvedIcon = expense.categoryIcon ?? category.icon;

    final timeStr = DateFormat('hh:mm a').format(expense.date);

    if (isHistoryVariant) {
      return BentoCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 14,
        backgroundColor: AppColors.surfaceContainerLow,
        child: Row(
          children: [
            CategoryIconBadge(
              icon: resolvedIcon,
              color: resolvedColor,
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          expense.merchant,
                          style: AppTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '-${CurrencyFormatter.formatPaise(expense.amountPaise)}',
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expense.categoryName,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.outline,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default compact/dashboard card variant
    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 14,
      backgroundColor: AppColors.surfaceContainerLow,
      child: Row(
        children: [
          CategoryIconBadge(
            icon: resolvedIcon,
            color: resolvedColor,
            size: 42,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        expense.merchant,
                        style: AppTypography.titleMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (expense.isVoiceRecorded == true) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.mic, size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  showPaymentMethod
                      ? '${expense.categoryName} • ${expense.paymentMethod}'
                      : expense.categoryName,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '-${CurrencyFormatter.formatPaise(expense.amountPaise)}',
                style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (expense.syncStatus != SyncStatus.synced) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync, size: 11, color: AppColors.tertiary),
                    const SizedBox(width: 3),
                    Text(
                      'Pending',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.tertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
