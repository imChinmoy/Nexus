import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'heatmap_cell.dart';

class HeatmapLegend extends StatelessWidget {
  final List<int>? thresholds;

  const HeatmapLegend({
    super.key,
    this.thresholds,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Semantics(
      label: 'Activity Intensity Legend: Level 0 (None) to Level 4 (Highest activity)',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Less',
            style: GoogleFonts.inter(
              fontSize: 10.0,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(width: 6.0),
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _LegendCell(level: index, isDark: isDark),
            );
          }),
          const SizedBox(width: 6.0),
          Text(
            'More',
            style: GoogleFonts.inter(
              fontSize: 10.0,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendCell extends StatelessWidget {
  final int level;
  final bool isDark;

  const _LegendCell({required this.level, required this.isDark});

  Color _resolveColor() {
    if (isDark) {
      switch (level) {
        case 1:
          return const Color(0xFF0F3B5F);
        case 2:
          return const Color(0xFF1768A8);
        case 3:
          return const Color(0xFF268BDE);
        case 4:
          return const Color(0xFF5AB0FF);
        case 0:
        default:
          return const Color(0xFF1E1E24);
      }
    } else {
      switch (level) {
        case 1:
          return const Color(0xFFBAE6FD);
        case 2:
          return const Color(0xFF60A5FA);
        case 3:
          return const Color(0xFF2563EB);
        case 4:
          return const Color(0xFF1D4ED8);
        case 0:
        default:
          return const Color(0xFFE5E5EA);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HeatmapCell.cellSize,
      height: HeatmapCell.cellSize,
      decoration: BoxDecoration(
        color: _resolveColor(),
        borderRadius: BorderRadius.circular(HeatmapCell.cellRadius),
      ),
    );
  }
}
