import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonVariant {
  primaryGradient,
  primarySolid,
  secondary,
  outline,
  ghost,
  danger,
}

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isTrailingIcon;
  final bool iconInCircle;
  final AppButtonVariant variant;
  final double height;
  final bool isLoading;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isTrailingIcon = false,
    this.iconInCircle = false,
    this.variant = AppButtonVariant.primarySolid,
    this.height = 54,
    this.isLoading = false,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  Widget _buildIcon(Color color) {
    if (widget.icon == null) return const SizedBox.shrink();

    if (widget.iconInCircle) {
      return Container(
        width: 28,
        height: 28,
        margin: EdgeInsets.only(
          right: widget.isTrailingIcon ? 0 : 8,
          left: widget.isTrailingIcon ? 8 : 0,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
        ),
        child: Center(
          child: Icon(widget.icon, size: 16, color: color),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        right: widget.isTrailingIcon ? 0 : 8,
        left: widget.isTrailingIcon ? 8 : 0,
      ),
      child: Icon(widget.icon, size: 20, color: color),
    );
  }

  Color _getTextColor(bool isEnabled) {
    if (widget.textColor != null) return widget.textColor!;
    if (!isEnabled) return AppColors.outline.withValues(alpha: 0.6);

    switch (widget.variant) {
      case AppButtonVariant.primaryGradient:
      case AppButtonVariant.primarySolid:
        return AppColors.onPrimary;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return AppColors.textPrimary;
      case AppButtonVariant.danger:
        return AppColors.error;
    }
  }

  BoxDecoration _getBoxDecoration(bool isEnabled) {
    final radius = BorderRadius.circular(widget.borderRadius);

    if (widget.backgroundColor != null) {
      return BoxDecoration(
        borderRadius: radius,
        color: isEnabled
            ? widget.backgroundColor
            : widget.backgroundColor!.withValues(alpha: 0.4),
      );
    }

    if (!isEnabled) {
      return BoxDecoration(
        borderRadius: radius,
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
      );
    }

    switch (widget.variant) {
      case AppButtonVariant.primaryGradient:
        return BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6FFBBE),
              AppColors.primaryContainer,
              AppColors.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonVariant.primarySolid:
        return BoxDecoration(
          borderRadius: radius,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: AppColors.secondaryContainer.withValues(alpha: 0.22),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case AppButtonVariant.outline:
        return BoxDecoration(
          borderRadius: radius,
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.85),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        );
      case AppButtonVariant.danger:
        return BoxDecoration(
          borderRadius: radius,
          color: AppColors.errorContainer.withValues(alpha: 0.25),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.errorContainer.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case AppButtonVariant.ghost:
        return BoxDecoration(
          borderRadius: radius,
          color: Colors.transparent,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final textColor = _getTextColor(isEnabled);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: textColor,
            ),
          )
        else ...[
          if (widget.icon != null && !widget.isTrailingIcon)
            _buildIcon(textColor),
          Text(
            widget.label,
            style: AppTypography.titleMd.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          if (widget.icon != null && widget.isTrailingIcon)
            _buildIcon(textColor),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: textColor.withValues(alpha: 0.12),
            highlightColor: textColor.withValues(alpha: 0.06),
            child: Ink(
              decoration: _getBoxDecoration(isEnabled),
              child: Center(
                child: Padding(
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
