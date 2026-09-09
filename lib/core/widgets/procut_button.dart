import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum ProCutButtonType { primary, secondary, danger, ghost }

class ProCutButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ProCutButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const ProCutButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = ProCutButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: _getTextColor()),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: _getTextColor()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: _getBoxDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBoxDecoration() {
    switch (type) {
      case ProCutButtonType.primary:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case ProCutButtonType.secondary:
        return BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder, width: 1),
        );
      case ProCutButtonType.danger:
        return BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1),
        );
      case ProCutButtonType.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        );
    }
  }

  Color _getTextColor() {
    if (onPressed == null) return AppColors.textDisabled;
    switch (type) {
      case ProCutButtonType.primary:
        return Colors.white;
      case ProCutButtonType.secondary:
        return AppColors.textPrimary;
      case ProCutButtonType.danger:
        return AppColors.error;
      case ProCutButtonType.ghost:
        return AppColors.textSecondary;
    }
  }
}

/// Backward compatibility aliases
typedef LoomaButton = ProCutButton;
typedef LoomaButtonType = ProCutButtonType;
