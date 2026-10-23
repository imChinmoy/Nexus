import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum NeonBadgeType { success, error, warning, info, neutral }

class NeonBadge extends StatelessWidget {
  final String label;
  final NeonBadgeType type;
  final bool pulse;

  const NeonBadge({
    super.key,
    required this.label,
    this.type = NeonBadgeType.info,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = switch (type) {
      NeonBadgeType.success => isDark ? AppColors.successDark : AppColors.success,
      NeonBadgeType.error => isDark ? AppColors.errorDark : AppColors.error,
      NeonBadgeType.warning => isDark ? AppColors.warningDark : AppColors.warning,
      NeonBadgeType.info => isDark ? AppColors.darkAccent : AppColors.lightAccent,
      NeonBadgeType.neutral => isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
