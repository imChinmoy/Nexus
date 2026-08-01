import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_stats_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../students/providers/student_provider.dart';
import '../../../events/providers/event_provider.dart';
import '../../../members/providers/members_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(studentsProvider);
              ref.invalidate(eventsProvider);
              ref.invalidate(membersProvider);
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverToBoxAdapter(child: _buildStatsGrid()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(child: _buildQuickActions(context)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverToBoxAdapter(child: _buildRecentAttendance()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverToBoxAdapter(child: _buildUpcomingEvents()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'GOOD MORNING' : hour < 17 ? 'GOOD AFTERNOON' : 'GOOD EVENING';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => AppGradients.primary.createShader(bounds),
                child: Text(
                  'BRL NEXUS',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'Blockchain Research Lab',
                style: AppTextStyles.bodyMdMuted,
              ),
            ],
          ),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGreen.withOpacity(_pulseAnimation.value),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push(RouteConstants.notifications),
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGlass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassStroke),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.onSurface, size: 22),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentPink,
                          boxShadow: [
                            BoxShadow(color: AppColors.accentPink.withOpacity(0.6), blurRadius: 4),
                          ],
                        ),
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

  Widget _buildStatsGrid() {
    final studentsAsync = ref.watch(studentsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final membersAsync = ref.watch(membersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OVERVIEW', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            BrlStatsCard(
              title: 'TOTAL STUDENTS',
              value: studentsAsync.maybeWhen(data: (s) => s.length.toString(), orElse: () => '-'),
              icon: Icons.school_rounded,
              accentColor: AppColors.moduleStudents,
            ),
            BrlStatsCard(
              title: 'ACTIVE MEMBERS',
              value: membersAsync.maybeWhen(
                data: (m) => m.where((member) => member.isActive).length.toString(),
                orElse: () => '-',
              ),
              icon: Icons.group_rounded,
              accentColor: AppColors.moduleMembers,
            ),
            BrlStatsCard(
              title: 'EVENTS TODAY',
              value: eventsAsync.maybeWhen(
                data: (e) => e.where((ev) => ev.startDate.year == DateTime.now().year && ev.startDate.month == DateTime.now().month && ev.startDate.day == DateTime.now().day).length.toString(),
                orElse: () => '-',
              ),
              icon: Icons.event_rounded,
              accentColor: AppColors.moduleEvents,
            ),
            const BrlStatsCard(
              title: 'ATTENDANCE RATE',
              value: '-',
              icon: Icons.check_circle_outline_rounded,
              accentColor: AppColors.moduleAttendance,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    const hardcodedEventId = '6a6dc76d77dff0bef5d29082';
    final actions = [
      _QuickAction('QR SCAN', Icons.qr_code_scanner_rounded, AppColors.accentGreen, '${RouteConstants.attendance}/qr-scan?eventId=$hardcodedEventId'),
      _QuickAction('MANUAL', Icons.edit_note_rounded, AppColors.primary, '${RouteConstants.attendance}/manual?eventId=$hardcodedEventId'),
      _QuickAction('NEW EVENT', Icons.add_circle_outline_rounded, AppColors.accentPink, RouteConstants.createEvent),
      _QuickAction('ADD STUDENT', Icons.person_add_rounded, AppColors.secondary, RouteConstants.addStudent),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACTIONS', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => context.push(a.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: a.color.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(color: a.color.withOpacity(0.15), blurRadius: 12),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.icon, color: a.color, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        style: AppTextStyles.labelSm.copyWith(color: a.color),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentAttendance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT ATTENDANCE', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
            GestureDetector(
              onTap: () {},
              child: Text('View All', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Center(child: Text('No recent attendance', style: TextStyle(color: AppColors.onSurfaceMuted))),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    final eventsAsync = ref.watch(eventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('UPCOMING EVENTS', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
            GestureDetector(
              onTap: () => context.push(RouteConstants.events),
              child: Text('View All', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: eventsAsync.maybeWhen(
            data: (events) {
              final upcoming = events.where((e) => e.status == 'upcoming').take(5).toList();
              if (upcoming.isEmpty) {
                return const Center(child: Text('No upcoming events', style: TextStyle(color: AppColors.onSurfaceMuted)));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _EventCard(
                  title: upcoming[i].title,
                  date: upcoming[i].startDate.toString().split(' ')[0],
                  type: upcoming[i].type,
                  color: [AppColors.secondary, AppColors.primary, AppColors.accentPink][i % 3],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.moduleEvents)),
            orElse: () => const Center(child: Text('Failed to load events')),
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

class _AttendanceListItem extends StatelessWidget {
  final String name, roll, statusLabel, time;
  final NeonBadgeType status;
  const _AttendanceListItem({required this.name, required this.roll, required this.status, required this.statusLabel, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.surfaceGlass, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.glassStroke)),
            child: const Icon(Icons.person_rounded, color: AppColors.onSurfaceMuted, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                Text(roll, style: AppTextStyles.labelSm),
              ],
            ),
          ),
          NeonBadge(label: statusLabel, type: status),
          const SizedBox(width: 8),
          Text(time, style: AppTextStyles.labelSm),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title, date, type;
  final Color color;
  const _EventCard({required this.title, required this.date, required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(type, style: AppTextStyles.labelSm.copyWith(color: color)),
          ),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(date, style: AppTextStyles.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}
