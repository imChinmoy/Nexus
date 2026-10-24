import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_heatmap_entity.dart';
import '../utils/heatmap_calendar_utils.dart';
import 'heatmap_cell.dart';

class HeatmapCalendarGrid extends StatefulWidget {
  final ActivityHeatmapEntity heatmap;
  final String? selectedDateKey;
  final void Function(HeatmapCalendarDay day, HeatmapDayEntity dayData) onDaySelected;

  const HeatmapCalendarGrid({
    super.key,
    required this.heatmap,
    this.selectedDateKey,
    required this.onDaySelected,
  });

  @override
  State<HeatmapCalendarGrid> createState() => _HeatmapCalendarGridState();
}

class _HeatmapCalendarGridState extends State<HeatmapCalendarGrid> {
  late final ScrollController _scrollController;
  late HeatmapCalendarGridData _gridData;
  late List<int> _thresholds;

  static const double _cellSize = HeatmapCell.cellSize; // 12.0
  static const double _cellGap = 3.0;
  static const double _columnStep = _cellSize + _cellGap; // 15.0
  static const double _weekdayLabelWidth = 26.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _gridData = HeatmapCalendarUtils.generateGrid(widget.heatmap.year);
    _thresholds = widget.heatmap.calculateThresholds();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAppropriatePosition();
    });
  }

  @override
  void didUpdateWidget(covariant HeatmapCalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heatmap.year != widget.heatmap.year) {
      _gridData = HeatmapCalendarUtils.generateGrid(widget.heatmap.year);
      _thresholds = widget.heatmap.calculateThresholds();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAppropriatePosition();
      });
    } else if (oldWidget.heatmap != widget.heatmap) {
      _thresholds = widget.heatmap.calculateThresholds();
    }
  }

  void _scrollToAppropriatePosition() {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    double targetOffset = 0.0;

    if (widget.heatmap.year == now.year) {
      // Find current week column
      final currentDayKey = HeatmapCalendarUtils.formatDateKey(now);
      int targetCol = 0;
      for (int c = 0; c < _gridData.columns.length; c++) {
        if (_gridData.columns[c].any((d) => d?.dateKey == currentDayKey)) {
          targetCol = c;
          break;
        }
      }
      targetOffset = (targetCol * _columnStep) - 120.0;
    } else if (widget.heatmap.year < now.year) {
      // Past year: scroll to end or keep at start
      targetOffset = _scrollController.position.maxScrollExtent;
    }

    targetOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(targetOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final gridWidth = _gridData.totalColumns * _columnStep;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Weekday Guide (M, W, F)
        Padding(
          padding: const EdgeInsets.only(top: 20.0), // Aligned with the cells under the month row
          child: SizedBox(
            width: _weekdayLabelWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeekdayLabel(' ', isDark), // Sun (0)
                _buildWeekdayLabel('Mon', isDark), // Mon (1)
                _buildWeekdayLabel(' ', isDark), // Tue (2)
                _buildWeekdayLabel('Wed', isDark), // Wed (3)
                _buildWeekdayLabel(' ', isDark), // Thu (4)
                _buildWeekdayLabel('Fri', isDark), // Fri (5)
                _buildWeekdayLabel(' ', isDark), // Sat (6)
              ],
            ),
          ),
        ),

        // 2. Horizontally scrollable calendar grid with month headers
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: gridWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Labels Row
                  SizedBox(
                    height: 16.0,
                    width: gridWidth,
                    child: Stack(
                      children: _buildMonthLabels(textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // The 7-row Weekday Grid
                  SizedBox(
                    height: (7 * _cellSize) + (6 * _cellGap),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_gridData.totalColumns, (colIndex) {
                        final colDays = _gridData.columns[colIndex];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: colIndex == _gridData.totalColumns - 1 ? 0 : _cellGap,
                          ),
                          child: Column(
                            children: List.generate(7, (rowIndex) {
                              final day = colDays[rowIndex];
                              final isSelected = day != null && day.dateKey == widget.selectedDateKey;
                              final dayData = day != null ? widget.heatmap.getDay(day.dateKey) : null;
                              final count = dayData?.count ?? 0;
                              final level = widget.heatmap.getIntensityLevel(count, _thresholds);

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: rowIndex == 6 ? 0 : _cellGap,
                                ),
                                child: HeatmapCell(
                                  day: day,
                                  dayData: dayData,
                                  intensityLevel: level,
                                  isSelected: isSelected,
                                  metric: widget.heatmap.metric,
                                  onTap: day != null
                                      ? () {
                                          HapticFeedback.selectionClick();
                                          widget.onDaySelected(day, dayData!);
                                        }
                                      : null,
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabel(String label, bool isDark) {
    return SizedBox(
      height: _cellSize + _cellGap,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.0,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMonthLabels(Color textColor) {
    final widgets = <Widget>[];
    int lastCol = -4;

    for (final header in _gridData.monthHeaders) {
      // Avoid overlapping if column spacing is too tight
      if (header.columnIndex - lastCol >= 3) {
        lastCol = header.columnIndex;
        widgets.add(
          Positioned(
            left: header.columnIndex * _columnStep,
            top: 0,
            child: Text(
              header.label,
              style: GoogleFonts.inter(
                fontSize: 10.0,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.1,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
