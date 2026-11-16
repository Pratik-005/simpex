import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/expenses/presentation/widgets/voice_assistant_bottom_sheet.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onVoiceTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 64.0;
    const double buttonOverflow = 18.0;
    const double totalHeight = barHeight + buttonOverflow;

    return SizedBox(
      height: totalHeight + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom Nav Bar Background & Items
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: buttonOverflow,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                border: const Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: barHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          index: 0,
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: 'Dashboard',
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 1,
                          icon: Icons.receipt_long_outlined,
                          activeIcon: Icons.receipt_long,
                          label: 'History',
                        ),
                      ),
                      // Spacer for the elevated center Voice AI button
                      const SizedBox(width: 64),
                      Expanded(
                        child: _buildNavItem(
                          index: 2,
                          icon: Icons.insights_outlined,
                          activeIcon: Icons.insights,
                          label: 'Reports',
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          index: 3,
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          label: 'Settings',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Elevated Center Voice AI Mic Button (partially on body, partially in navbar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _buildVoiceButton(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton(BuildContext context) {
    return GestureDetector(
      onTap: onVoiceTap ?? () => VoiceAssistantBottomSheet.show(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF34D399),
                  AppColors.primary,
                  Color(0xFF10B981),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.65),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.mic, size: 28, color: Color(0xFF003824)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Voice AI',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
