import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_heatmap_entity.dart';
import '../utils/heatmap_calendar_utils.dart';

class HeatmapCell extends StatelessWidget {
  final HeatmapCalendarDay? day;
  final HeatmapDayEntity? dayData;
  final int intensityLevel;
  final bool isSelected;
  final String metric;
  final VoidCallback? onTap;

  const HeatmapCell({
    super.key,
    required this.day,
    this.dayData,
    this.intensityLevel = 0,
    this.isSelected = false,
    required this.metric,
    this.onTap,
  });

  static const double cellSize = 12.0;
  static const double cellRadius = 2.5;

  Color _resolveCellColor(BuildContext context, bool isDark) {
    if (day == null) {
      return Colors.transparent;
    }

    if (isDark) {
      switch (intensityLevel) {
        case 1:
          return const Color(0xFF144A75); // visible cool blue
        case 2:
          return const Color(0xFF1E6EAE); // vibrant medium blue
        case 3:
          return const Color(0xFF268BDE); // vivid accent royal blue
        case 4:
          return const Color(0xFF5AB0FF); // bright luminous sky blue
        case 0:
        default:
          return const Color(0xFF26262E); // clearly visible cell against dark surface
      }
    } else {
      switch (intensityLevel) {
        case 1:
          return const Color(0xFFBAE6FD); // soft sky blue
        case 2:
          return const Color(0xFF60A5FA); // vibrant blue
        case 3:
          return const Color(0xFF2563EB); // strong brand royal blue
        case 4:
          return const Color(0xFF1D4ED8); // deep rich blue
        case 0:
        default:
          return const Color(0xFFE4E4EA); // neutral crisp light cell
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const SizedBox(width: cellSize, height: cellSize);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cellColor = _resolveCellColor(context, isDark);
    final count = dayData?.count ?? 0;
    final dateFormatted = DateFormat.yMMMMd().format(day!.date);
    final semanticLabel = '$dateFormatted: $count ${metric == 'events' ? 'events' : 'check-ins'}';

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(cellRadius),
            border: isSelected
                ? Border.all(
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    width: 1.6,
                  )
                : Border.all(
                    color: isDark
                        ? const Color(0x18FFFFFF)
                        : const Color(0x0C000000),
                    width: 0.6,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
