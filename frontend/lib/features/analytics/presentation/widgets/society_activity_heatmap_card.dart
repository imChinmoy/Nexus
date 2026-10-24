import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_heatmap_entity.dart';
import '../../providers/analytics_provider.dart';
import 'heatmap_calendar_grid.dart';
import 'heatmap_day_details_sheet.dart';
import 'heatmap_legend.dart';

class SocietyActivityHeatmapCard extends ConsumerWidget {
  const SocietyActivityHeatmapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final cardBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000);

    final selectedYear = ref.watch(selectedHeatmapYearProvider);
    final selectedMetric = ref.watch(selectedHeatmapMetricProvider);
    final selectedDateKey = ref.watch(selectedHeatmapDateKeyProvider);

    final heatmapAsync = ref.watch(
      activityHeatmapProvider(
        ActivityHeatmapParams(year: selectedYear, metric: selectedMetric),
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Section Header & Controls
          _buildHeader(context, ref, selectedYear, selectedMetric, isDark, textPrimary, textSecondary, accent),
          const SizedBox(height: 12),

          // 2. Metric Selector Pill
          _buildMetricSelector(ref, selectedMetric, isDark, textPrimary, textSecondary, accent),
          const SizedBox(height: 14),

          // 3. Content: Async when
          heatmapAsync.when(
            data: (heatmap) => _buildHeatmapContent(
              context,
              ref,
              heatmap,
              selectedMetric,
              selectedDateKey,
              isDark,
              textPrimary,
              textSecondary,
              accent,
            ),
            loading: () => _buildLoadingSkeleton(isDark),
            error: (err, _) => _buildErrorState(context, ref, selectedYear, selectedMetric, err.toString(), isDark, textPrimary, textSecondary, accent),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER (Title, Subtitle, Year Selector)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    int selectedYear,
    String selectedMetric,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    final currentYear = DateTime.now().year;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Society Activity',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your year in events and attendance',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Year Selector: ‹ 2026 ›
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222228) : const Color(0xFFEBEBEF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: selectedYear > 2020
                    ? () {
                        HapticFeedback.lightImpact();
                        ref.read(selectedHeatmapDateKeyProvider.notifier).state = null;
                        ref.read(selectedHeatmapYearProvider.notifier).state = selectedYear - 1;
                      }
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: selectedYear > 2020 ? textPrimary : textSecondary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  selectedYear.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: selectedYear < currentYear + 1
                    ? () {
                        HapticFeedback.lightImpact();
                        ref.read(selectedHeatmapDateKeyProvider.notifier).state = null;
                        ref.read(selectedHeatmapYearProvider.notifier).state = selectedYear + 1;
                      }
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: selectedYear < currentYear + 1 ? textPrimary : textSecondary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. METRIC SELECTOR PILL [ Events | Attendance ]
  // ---------------------------------------------------------------------------
  Widget _buildMetricSelector(
    WidgetRef ref,
    String selectedMetric,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19191D) : const Color(0xFFEDEDF2),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricButton(
              label: 'Events',
              icon: Icons.event_note_rounded,
              isActive: selectedMetric == 'events',
              onTap: () {
                if (selectedMetric != 'events') {
                  HapticFeedback.lightImpact();
                  ref.read(selectedHeatmapDateKeyProvider.notifier).state = null;
                  ref.read(selectedHeatmapMetricProvider.notifier).state = 'events';
                }
              },
              isDark: isDark,
              accent: accent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _buildMetricButton(
              label: 'Attendance',
              icon: Icons.how_to_reg_rounded,
              isActive: selectedMetric == 'attendance',
              onTap: () {
                if (selectedMetric != 'attendance') {
                  HapticFeedback.lightImpact();
                  ref.read(selectedHeatmapDateKeyProvider.notifier).state = null;
                  ref.read(selectedHeatmapMetricProvider.notifier).state = 'attendance';
                }
              },
              isDark: isDark,
              accent: accent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF2B2B32) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? accent : textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. HEATMAP CONTENT (Summary stats, Grid, Legend)
  // ---------------------------------------------------------------------------
  Widget _buildHeatmapContent(
    BuildContext context,
    WidgetRef ref,
    ActivityHeatmapEntity heatmap,
    String metric,
    String? selectedDateKey,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    final isEvents = metric == 'events';
    final stats = heatmap.stats;

    // Peak day string
    String peakDayText = 'None';
    if (stats.busiestDay != null) {
      try {
        final d = DateFormat('MMM d').format(stats.busiestDay!.dateTime);
        peakDayText = '${stats.busiestDay!.count} on $d';
      } catch (_) {
        peakDayText = '${stats.busiestDay!.count}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Summary Stats Row
        Row(
          children: [
            _buildStatChip(
              title: isEvents ? 'Total Events' : 'Total Check-ins',
              value: stats.totalCount.toString(),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              title: 'Active Days',
              value: stats.activeDays.toString(),
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              title: 'Peak Day',
              value: peakDayText,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // If no recorded activity, show an informational banner while still rendering the zero grid
        if (stats.totalCount == 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F1F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No recorded activity for this year yet.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Calendar Grid
        HeatmapCalendarGrid(
          heatmap: heatmap,
          selectedDateKey: selectedDateKey,
          onDaySelected: (day, dayData) {
            ref.read(selectedHeatmapDateKeyProvider.notifier).state = day.dateKey;
            HeatmapDayDetailsSheet.show(
              context,
              day: day,
              dayData: dayData,
              metric: metric,
            );
          },
        ),
        const SizedBox(height: 12),

        // Bottom Bar: Timezone info on left, Legend on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                heatmap.timezone == 'Asia/Kolkata' ? 'IST (Asia/Kolkata)' : heatmap.timezone,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: textSecondary.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            HeatmapLegend(thresholds: heatmap.calculateThresholds()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String title,
    required String value,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181C) : const Color(0xFFF6F6F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LOADING SKELETON
  // ---------------------------------------------------------------------------
  Widget _buildLoadingSkeleton(bool isDark) {
    final baseColor = isDark ? const Color(0xFF1C1C22) : const Color(0xFFE5E5EA);
    final highlightColor = isDark ? const Color(0xFF282830) : const Color(0xFFF2F2F7);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ERROR STATE
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    int year,
    String metric,
    String error,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C22) : const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 28, color: textSecondary),
          const SizedBox(height: 8),
          Text(
            'Unable to load activity heatmap',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(activityHeatmapProvider(
                ActivityHeatmapParams(year: year, metric: metric),
              ));
            },
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text(
              'Retry',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
