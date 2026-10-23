import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventsAsync = ref.watch(eventsProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Attendance Hub',
        ),
        body: RefreshIndicator(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          backgroundColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
          onRefresh: () async {
            ref.invalidate(eventsProvider);
          },
          child: eventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: BrlGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: isDark ? AppColors.errorDark : AppColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: 16),
                      Text('Error loading events', style: AppTextStyles.headlineSm),
                      const SizedBox(height: 6),
                      Text(
                        '$err',
                        style: AppTextStyles.bodySm.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      BrlButton(
                        label: 'Retry',
                        onPressed: () => ref.invalidate(eventsProvider),
                        variant: BrlButtonVariant.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (events) {
              if (events.isEmpty) {
                return _buildNoEventsFound(context);
              }

              final activeEvents = events
                  .where((e) => e.status != 'archived' && e.status != 'cancelled')
                  .toList();
              final availableEvents = activeEvents.isNotEmpty ? activeEvents : events;

              final selectedEvent = availableEvents.firstWhere(
                (e) => e.id == _selectedEventId,
                orElse: () {
                  final openEvent = availableEvents.where((e) => e.isAttendanceOpen).firstOrNull;
                  return openEvent ?? availableEvents.first;
                },
              );

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildEventSelectorCard(context, availableEvents, selectedEvent),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'ATTENDANCE MODES',
                      style: AppTextStyles.labelSm.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildActionCard(
                    context,
                    title: 'QR Code Scanner',
                    description: 'Continuous high-speed gate check-in using student QR codes',
                    icon: Icons.qr_code_scanner_rounded,
                    accentColor: isDark ? AppColors.successDark : AppColors.success,
                    badgeText: selectedEvent.isAttendanceOpen ? 'Ready' : 'Closed',
                    onTap: () {
                      context.push(
                        '${RouteConstants.attendance}/qr-scan?eventId=${selectedEvent.id}',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    title: 'Manual Attendance',
                    description: 'Search attendee by name, roll number, or student ID',
                    icon: Icons.edit_note_rounded,
                    accentColor: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    onTap: () {
                      context.push(
                        '${RouteConstants.attendance}/manual?eventId=${selectedEvent.id}',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    title: 'Recent Attendance Logs',
                    description: 'View chronological history of marked attendees',
                    icon: Icons.history_rounded,
                    accentColor: const Color(0xFF5E5CE6),
                    onTap: () {
                      context.push('${RouteConstants.attendance}/recent');
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventSelectorCard(
    BuildContext context,
    List<EventEntity> events,
    EventEntity selectedEvent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BrlGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECTED EVENT',
                style: AppTextStyles.labelSm.copyWith(
                  color: textSecondary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              NeonBadge(
                label: selectedEvent.isAttendanceOpen ? 'Attendance Open' : 'Attendance Closed',
                type: selectedEvent.isAttendanceOpen
                    ? NeonBadgeType.success
                    : NeonBadgeType.error,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                width: 0.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedEvent.id,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                items: events.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.id,
                    child: Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null) {
                    setState(() => _selectedEventId = newId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selectedEvent.venue?.isNotEmpty == true
                      ? selectedEvent.venue!
                      : 'Venue: To be announced',
                  style: AppTextStyles.caption.copyWith(color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 15, color: textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${selectedEvent.startDate.toString().split(' ').first} to ${selectedEvent.endDate.toString().split(' ').first}',
                  style: AppTextStyles.caption.copyWith(color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BrlGlassCard(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTextStyles.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildNoEventsFound(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  color: textSecondary,
                  size: 54,
                ),
                const SizedBox(height: 16),
                Text('No Events Available', style: AppTextStyles.headlineSm),
                const SizedBox(height: 8),
                Text(
                  'There are no active events yet. Create an event in the Events section before marking attendance.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: textSecondary),
                ),
                const SizedBox(height: 24),
                BrlButton(
                  label: 'Go to Events',
                  onPressed: () => context.go(RouteConstants.events),
                  variant: BrlButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
