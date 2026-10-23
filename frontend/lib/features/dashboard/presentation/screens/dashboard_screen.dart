import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_stats_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';
import '../../../members/providers/members_provider.dart';
import '../../../students/providers/student_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: accent,
            backgroundColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
            onRefresh: () async {
              ref.invalidate(studentsProvider);
              ref.invalidate(eventsProvider);
              ref.invalidate(membersProvider);
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(child: _buildAttendanceBanner(context)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(child: _buildStatsGrid(context)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(child: _buildQuickActions(context)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(child: _buildRecentAttendance(context)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverToBoxAdapter(child: _buildUpcomingEvents(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final user = ref.watch(currentUserProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final displayName = user?.name.split(' ').first ?? 'Member';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $displayName',
                style: AppTextStyles.labelMd.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Nexus Overview',
                style: AppTextStyles.headlineLg.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.successDark : AppColors.success).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.successDark : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: AppTextStyles.labelSm.copyWith(
                        color: isDark ? AppColors.successDark : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBanner(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return eventsAsync.maybeWhen(
      data: (events) {
        final openEvent = events.where((e) => e.isAttendanceOpen).firstOrNull;
        if (openEvent == null) return const SizedBox.shrink();

        final successColor = isDark ? AppColors.successDark : AppColors.success;

        return BrlGlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: successColor.withValues(alpha: 0.3),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.qr_code_scanner_rounded, color: successColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ATTENDANCE ACTIVE',
                          style: AppTextStyles.labelSm.copyWith(
                            color: successColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      openEvent.title,
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  context.push('${RouteConstants.attendance}/qr-scan?eventId=${openEvent.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: successColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Scan QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final membersAsync = ref.watch(membersProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'KEY METRICS',
            style: AppTextStyles.labelSm.copyWith(
              color: textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            BrlStatsCard(
              title: 'Total Students',
              value: studentsAsync.maybeWhen(
                data: (s) => s.length.toString(),
                orElse: () => '—',
              ),
              icon: Icons.school_outlined,
              accentColor: const Color(0xFF0A84FF),
            ),
            BrlStatsCard(
              title: 'Active Members',
              value: membersAsync.maybeWhen(
                data: (m) => m.where((member) => member.isActive).length.toString(),
                orElse: () => '—',
              ),
              icon: Icons.group_outlined,
              accentColor: const Color(0xFF5E5CE6),
            ),
            BrlStatsCard(
              title: 'Events Today',
              value: eventsAsync.maybeWhen(
                data: (e) {
                  final now = DateTime.now();
                  return e.where((ev) =>
                      ev.startDate.year == now.year &&
                      ev.startDate.month == now.month &&
                      ev.startDate.day == now.day).length.toString();
                },
                orElse: () => '—',
              ),
              icon: Icons.calendar_today_outlined,
              accentColor: const Color(0xFFFF375F),
            ),
            BrlStatsCard(
              title: 'Attendance Rate',
              value: studentsAsync.maybeWhen(
                data: (students) {
                  if (students.isEmpty) return '0%';
                  final presentCount = students.where((s) => s.isPresent).length;
                  final rate = (presentCount / students.length) * 100;
                  return '${rate.toStringAsFixed(1)}%';
                },
                orElse: () => '—',
              ),
              icon: Icons.check_circle_outline_rounded,
              accentColor: isDark ? AppColors.successDark : AppColors.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final currentUser = ref.watch(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final permissions = ref.watch(myPermissionsProvider).value ?? [];

    final hasEventAdd = isSuperAdmin || permissions.contains('event:add') || permissions.contains('all');
    final hasAttendanceMark = isSuperAdmin || permissions.contains('attendance:mark') || permissions.contains('all');

    final actions = <_QuickAction>[
      if (hasAttendanceMark)
        _QuickAction(
          'QR Scanner',
          Icons.qr_code_scanner_rounded,
          isDark ? AppColors.successDark : AppColors.success,
          RouteConstants.attendance,
        ),
      if (hasAttendanceMark)
        _QuickAction(
          'Manual Entry',
          Icons.edit_note_rounded,
          isDark ? AppColors.darkAccent : AppColors.lightAccent,
          RouteConstants.attendance,
        ),
      if (hasEventAdd)
        const _QuickAction(
          'New Event',
          Icons.add_circle_outline_rounded,
          Color(0xFFFF375F),
          RouteConstants.createEvent,
        ),
      const _QuickAction(
        'Students',
        Icons.people_outline_rounded,
        Color(0xFF5E5CE6),
        RouteConstants.students,
      ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'QUICK ACTIONS',
            style: AppTextStyles.labelSm.copyWith(
              color: textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => context.push(a.route),
                  child: BrlGlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(a.icon, color: a.color, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.label,
                          style: AppTextStyles.labelSm.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentAttendance(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'RECENT ATTENDANCE',
                style: AppTextStyles.labelSm.copyWith(
                  color: textSecondary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(RouteConstants.recentAttendance),
              child: Text(
                'See All',
                style: AppTextStyles.bodySm.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        studentsAsync.maybeWhen(
          data: (students) {
            final presentStudents = students.where((s) => s.isPresent).toList();
            presentStudents.sort((a, b) {
              if (a.updatedAt == null && b.updatedAt == null) return 0;
              if (a.updatedAt == null) return 1;
              if (b.updatedAt == null) return -1;
              return b.updatedAt!.compareTo(a.updatedAt!);
            });
            final recent = presentStudents.take(3).toList();

            if (recent.isEmpty) {
              return BrlGlassCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No attendance marked yet today',
                    style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: recent.map((student) {
                String timeString = '';
                if (student.updatedAt != null) {
                  final time = student.updatedAt!;
                  timeString =
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BrlGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          child: Text(
                            student.name.isNotEmpty
                                ? student.name.substring(0, 1).toUpperCase()
                                : 'S',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                student.rollNumber,
                                style: AppTextStyles.caption.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const NeonBadge(label: 'Present', type: NeonBadgeType.success),
                        if (timeString.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeString,
                            style: AppTextStyles.caption.copyWith(color: textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          orElse: () => BrlGlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Loading attendance...',
                style: AppTextStyles.bodySm.copyWith(color: textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'EVENTS SCHEDULE',
                style: AppTextStyles.labelSm.copyWith(
                  color: textSecondary,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(RouteConstants.events),
              child: Text(
                'See All',
                style: AppTextStyles.bodySm.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 124,
          child: eventsAsync.maybeWhen(
            data: (events) {
              final upcoming = events
                  .where((e) => e.status == 'upcoming' || e.status == 'ongoing')
                  .toList();
              upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
              final displayEvents = upcoming.take(5).toList();

              if (displayEvents.isEmpty) {
                return BrlGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No upcoming events scheduled',
                      style: AppTextStyles.bodySm.copyWith(color: textSecondary),
                    ),
                  ),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: displayEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final ev = displayEvents[i];
                  return _EventCard(event: ev);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            orElse: () => Center(
              child: Text(
                'Failed to load events',
                style: AppTextStyles.bodySm.copyWith(color: textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}

class _EventCard extends StatelessWidget {
  final EventEntity event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: () => context.push('${RouteConstants.events}/${event.id}'),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NeonBadge(
                  label: event.type.toUpperCase(),
                  type: NeonBadgeType.info,
                ),
                if (event.isAttendanceOpen)
                  const NeonBadge(
                    label: 'Open',
                    type: NeonBadgeType.success,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.startDate.toString().split(' ').first,
                  style: AppTextStyles.caption.copyWith(color: textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
