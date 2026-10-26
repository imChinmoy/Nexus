import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_heatmap_entity.dart';
import '../utils/heatmap_calendar_utils.dart';

class HeatmapDayDetailsSheet extends StatelessWidget {
  final HeatmapCalendarDay day;
  final HeatmapDayEntity dayData;
  final String metric;

  const HeatmapDayDetailsSheet({
    super.key,
    required this.day,
    required this.dayData,
    required this.metric,
  });

  static Future<void> show(
    BuildContext context, {
    required HeatmapCalendarDay day,
    required HeatmapDayEntity dayData,
    required String metric,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HeatmapDayDetailsSheet(
        day: day,
        dayData: dayData,
        metric: metric,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final border = isDark ? AppColors.darkSeparator : AppColors.lightSeparator;

    final dateFormatted = DateFormat('EEEE, MMMM d, y').format(day.date);
    final isEvents = metric == 'events';
    final count = dayData.count;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Pill
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Header & Count Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormatted,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEvents ? 'Society Event Activity' : 'Society Check-in Operations',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: count > 0 ? accent.withValues(alpha: 0.12) : (isDark ? Colors.white10 : Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: count > 0 ? accent.withValues(alpha: 0.3) : Colors.transparent,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isEvents
                          ? (count > 0 ? '$count ${count == 1 ? 'Event' : 'Events'}' : 'No Events')
                          : (count > 0 ? '$count ${count == 1 ? 'Check-in' : 'Check-ins'}' : 'No Check-ins'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: count > 0 ? accent : textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: border),
              const SizedBox(height: 14),

              // List of Activities or Empty State
              Flexible(
                child: count == 0
                    ? _buildEmptyState(context, isDark, isEvents, textSecondary)
                    : isEvents
                        ? _buildEventsList(context, isDark, textPrimary, textSecondary, accent, border)
                        : _buildAttendanceList(context, isDark, textPrimary, textSecondary, accent, border),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isEvents, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEvents ? Icons.event_busy_rounded : Icons.person_off_rounded,
              size: 38,
              color: textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              isEvents
                  ? 'No events were active on this date'
                  : 'No attendance records were marked on this date',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
    Color border,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: dayData.events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final event = dayData.events[index];
        final typeLabel = (event.type ?? 'Event').toUpperCase();
        final statusLabel = (event.status ?? 'active').toUpperCase();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF19191D) : const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                event.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (event.venue != null && event.venue!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.venue!,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // Navigate to details button
              if (event.id.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final nav = Navigator.of(context);
                      final router = GoRouter.of(context);
                      nav.pop();
                      router.push('${RouteConstants.events}/${event.id}');
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text(
                      'View Event',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceList(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
    Color border,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: dayData.events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final ev = dayData.events[index];
        final eventCount = ev.count ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF19191D) : const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.7),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.how_to_reg_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ev.title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$eventCount verified check-ins',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (ev.id.isNotEmpty)
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final nav = Navigator.of(context);
                    final router = GoRouter.of(context);
                    nav.pop();
                    router.push('${RouteConstants.events}/${ev.id}');
                  },
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  color: textSecondary,
                  tooltip: 'View Event',
                ),
            ],
          ),
        );
      },
    );
  }
}
