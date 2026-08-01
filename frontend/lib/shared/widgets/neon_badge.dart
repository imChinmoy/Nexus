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

  Color get _color => switch (type) {
        NeonBadgeType.success => AppColors.accentGreen,
        NeonBadgeType.error => AppColors.error,
        NeonBadgeType.warning => AppColors.accentAmber,
        NeonBadgeType.info => AppColors.primary,
        NeonBadgeType.neutral => AppColors.onSurfaceSubtle,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(color: _color),
      ),
    );
  }
}
