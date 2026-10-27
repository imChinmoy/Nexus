import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/activity_heatmap_entity.dart';
import '../utils/heatmap_calendar_utils.dart';
import 'heatmap_cell.dart';

class HeatmapCalendarGrid extends StatefulWidget {
  final ActivityHeatmapEntity heatmap;
  final String? selectedDateKey;
  final void Function(HeatmapCalendarDay day, HeatmapDayEntity dayData)
      onDaySelected;

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
  late final ScrollController _monthChipsScrollController;
  late HeatmapCalendarGridData _gridData;
  late List<int> _thresholds;
  int _activeMonthIndex = 0;
  bool _isProgrammaticScrolling = false;

  static const double _cellSize = HeatmapCell.cellSize; // 12.0
  static const double _cellGap = 3.0;
  static const double _weekdayLabelWidth = 26.0;
  static const double _monthSeparatorWidth =
      17.0; // 8px left padding + 1px divider + 8px right padding

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _monthChipsScrollController = ScrollController();
    _gridData = HeatmapCalendarUtils.generateGrid(widget.heatmap.year);
    _thresholds = widget.heatmap.calculateThresholds();

    final now = DateTime.now();
    if (widget.heatmap.year == now.year) {
      _activeMonthIndex = (now.month - 1).clamp(0, 11);
    } else {
      _activeMonthIndex = 0;
    }

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAppropriatePosition();
      _scrollMonthChips(_activeMonthIndex);
    });
  }

  @override
  void didUpdateWidget(covariant HeatmapCalendarGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heatmap.year != widget.heatmap.year) {
      _gridData = HeatmapCalendarUtils.generateGrid(widget.heatmap.year);
      _thresholds = widget.heatmap.calculateThresholds();
      final now = DateTime.now();
      if (widget.heatmap.year == now.year) {
        _activeMonthIndex = (now.month - 1).clamp(0, 11);
      } else {
        _activeMonthIndex = 0;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAppropriatePosition();
        _scrollMonthChips(_activeMonthIndex);
      });
    } else if (oldWidget.heatmap != widget.heatmap) {
      _thresholds = widget.heatmap.calculateThresholds();
    }
  }

  double _calculateMonthOffset(int targetIndex) {
    double offset = 0.0;
    for (int i = 0; i < targetIndex && i < _gridData.months.length; i++) {
      final m = _gridData.months[i];
      final mWidth =
          (m.columns.length * _cellSize) + ((m.columns.length - 1) * _cellGap);
      offset += mWidth + _monthSeparatorWidth;
    }
    return offset;
  }

  void _scrollToMonth(int targetIndex, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = _calculateMonthOffset(targetIndex).clamp(0.0, maxScroll);
    if (animate) {
      _isProgrammaticScrolling = true;
      _scrollController
          .animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      )
          .then((_) {
        _isProgrammaticScrolling = false;
      });
    } else {
      _scrollController.jumpTo(target);
    }
  }

  void _scrollMonthChips(int index) {
    if (!_monthChipsScrollController.hasClients) return;
    final maxExtent = _monthChipsScrollController.position.maxScrollExtent;
    final target = (index * 54.0 - 60.0).clamp(0.0, maxExtent);
    _monthChipsScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _onScroll() {
    if (_isProgrammaticScrolling || !_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    int activeIndex = 0;
    for (int i = 0; i < _gridData.months.length; i++) {
      final start = _calculateMonthOffset(i) - 20.0;
      if (offset >= start) {
        activeIndex = i;
      }
    }
    if (activeIndex != _activeMonthIndex && mounted) {
      setState(() {
        _activeMonthIndex = activeIndex;
      });
      _scrollMonthChips(activeIndex);
    }
  }

  void _scrollToAppropriatePosition({int retries = 5}) {
    if (!_scrollController.hasClients || !mounted) return;

    if (!_scrollController.position.hasContentDimensions ||
        _scrollController.position.maxScrollExtent <= 0) {
      if (retries > 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToAppropriatePosition(retries: retries - 1);
          }
        });
      }
      return;
    }

    _scrollToMonth(_activeMonthIndex, animate: false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _monthChipsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sleek Month Quick-Jump Strip
        _buildMonthChips(context, isDark, textPrimary, textSecondary, accent),
        const SizedBox(height: 12.0),

        // 2. Horizontally scrollable calendar with properly segregated months
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday Guide (M, W, F)
            Padding(
              padding:
                  const EdgeInsets.only(top: 24.0), // 18px header + 6px gap
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

            // Scrollable Segregated Months Row
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      List.generate(_gridData.months.length, (monthIndex) {
                    final month = _gridData.months[monthIndex];
                    final isLast = monthIndex == _gridData.months.length - 1;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Block
                        _buildMonthSection(
                            month, isDark, textPrimary, textSecondary, accent),

                        // Month Segregation Divider
                        if (!isLast) _buildMonthSeparator(isDark),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthChips(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    final now = DateTime.now();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        controller: _monthChipsScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _gridData.months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final month = _gridData.months[index];
          final isActive = index == _activeMonthIndex;
          final isCurrentMonth =
              widget.heatmap.year == now.year && month.month == now.month;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _activeMonthIndex = index;
                });
                _scrollToMonth(index, animate: true);
                _scrollMonthChips(index);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? accent.withValues(alpha: isDark ? 0.25 : 0.15)
                      : isDark
                          ? const Color(0xFF1E1E24)
                          : const Color(0xFFEBEBEF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? accent.withValues(alpha: 0.7)
                        : isCurrentMonth
                            ? accent.withValues(alpha: 0.35)
                            : isDark
                                ? const Color(0x14FFFFFF)
                                : const Color(0x0C000000),
                    width: isActive ? 1.2 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      month.shortName,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? (isDark ? Colors.white : accent)
                            : textSecondary,
                      ),
                    ),
                    if (isCurrentMonth) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSection(
    HeatmapMonthData month,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Header
        _buildMonthHeader(month, isDark, textPrimary, textSecondary, accent),
        const SizedBox(height: 6.0),

        // Month Weekday Grid (7 rows x N columns for this month)
        SizedBox(
          height: (7 * _cellSize) + (6 * _cellGap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(month.columns.length, (colIndex) {
              final colDays = month.columns[colIndex];
              final isLastCol = colIndex == month.columns.length - 1;

              return Padding(
                padding: EdgeInsets.only(
                  right: isLastCol ? 0 : _cellGap,
                ),
                child: Column(
                  children: List.generate(7, (rowIndex) {
                    final day = colDays[rowIndex];
                    final isSelected =
                        day != null && day.dateKey == widget.selectedDateKey;
                    final dayData =
                        day != null ? widget.heatmap.getDay(day.dateKey) : null;
                    final count = dayData?.count ?? 0;
                    final level =
                        widget.heatmap.getIntensityLevel(count, _thresholds);

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
    );
  }

  Widget _buildMonthHeader(
    HeatmapMonthData month,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    final now = DateTime.now();
    final isCurrentMonth =
        widget.heatmap.year == now.year && month.month == now.month;

    int monthActivityCount = 0;
    for (final col in month.columns) {
      for (final day in col) {
        if (day != null) {
          monthActivityCount += widget.heatmap.getDay(day.dateKey).count;
        }
      }
    }

    return SizedBox(
      height: 18.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            month.shortName,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.0,
              fontWeight: isCurrentMonth ? FontWeight.w700 : FontWeight.w600,
              color: isCurrentMonth ? accent : textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          if (monthActivityCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$monthActivityCount',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthSeparator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        width: 1.0,
        height: (7 * _cellSize) + (6 * _cellGap) + 24.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.0),
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.14),
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayLabel(String label, bool isDark) {
    return SizedBox(
      height: _cellSize + _cellGap,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 9.0,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
      ),
    );
  }
}
