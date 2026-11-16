import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/expenses/domain/models/expense.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;
  final bool isFullWidth;

  const SyncStatusBadge({
    super.key,
    this.status = SyncStatus.synced,
    this.pendingCount = 0,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSynced = status == SyncStatus.synced;

    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done : Icons.cloud_sync,
            size: 16,
            color: isSynced ? AppColors.primary : AppColors.tertiary,
          ),
          const SizedBox(width: 8),
          Flexible(
            fit: isFullWidth ? FlexFit.tight : FlexFit.loose,
            child: Text(
              isSynced
                  ? 'All synced with cloud • 100%'
                  : '$pendingCount pending sync (offline queue)',
              style: AppTypography.labelSm.copyWith(
                color: isSynced ? AppColors.onSurface : AppColors.tertiary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isFullWidth) ...[
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSynced ? AppColors.primary : AppColors.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
