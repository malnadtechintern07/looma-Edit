import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor ?? effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: textColor ?? effectiveColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
