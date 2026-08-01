import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'brl_glass_card.dart';

class BrlStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;
  final double? changePercent;
  final bool isPositive;

  const BrlStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
    this.changePercent,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return BrlGlassCard(
      borderColor: accentColor.withOpacity(0.2),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              if (changePercent != null)
                _ChangeIndicator(
                  value: changePercent!,
                  isPositive: isPositive,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.7)],
            ).createShader(bounds),
            child: Text(
              value,
              style: AppTextStyles.headlineLg.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...
            [
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTextStyles.labelSm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
        ],
      ),
    );
  }
}

class _ChangeIndicator extends StatelessWidget {
  final double value;
  final bool isPositive;

  const _ChangeIndicator({required this.value, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.accentGreen : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: AppTextStyles.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
