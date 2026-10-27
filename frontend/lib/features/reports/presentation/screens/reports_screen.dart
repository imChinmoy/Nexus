import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';
import '../../../members/providers/members_provider.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/providers/student_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final membersAsync = ref.watch(membersProvider);
    final accent = AppColors.accentOf(context);

    final students = studentsAsync.value ?? [];
    final events = eventsAsync.value ?? [];
    final members = membersAsync.value ?? [];

    final isLoading = studentsAsync.isLoading ||
        eventsAsync.isLoading ||
        membersAsync.isLoading;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Analytics & Reports',
        ),
        body: RefreshIndicator(
          color: accent,
          backgroundColor: AppColors.surfaceOf(context),
          onRefresh: () async {
            ref.invalidate(studentsProvider);
            ref.invalidate(eventsProvider);
            ref.invalidate(membersProvider);
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: isLoading && students.isEmpty && events.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                      color: accent, strokeWidth: 2.5),
                )
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Summary Metric Grid
                    _buildOverviewMetrics(context, students, events, members),
                    const SizedBox(height: 20),

                    // Chart Section with Segmented Toggle
                    _buildSectionHeader(context, 'ATTENDANCE DISTRIBUTION'),
                    const SizedBox(height: 8),
                    _buildBranchAttendanceChart(context, students),
                    const SizedBox(height: 20),

                    // Event Operations Breakdown
                    _buildSectionHeader(context, 'EVENT LIFECYCLE'),
                    const SizedBox(height: 8),
                    _buildEventStatusBreakdown(context, events),
                    const SizedBox(height: 20),

                    // Team Structure
                    _buildSectionHeader(context, 'TEAM COMPOSITION'),
                    const SizedBox(height: 8),
                    _buildTeamCompositionCard(context, members),
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiaryOf(context),
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics(
    BuildContext context,
    List<StudentEntity> students,
    List<EventEntity> events,
    List<UserEntity> members,
  ) {
    final totalStudents = students.length;
    final avgAttendance = students.isEmpty
        ? 0.0
        : students.map((s) => s.attendance).reduce((a, b) => a + b) /
            students.length;
    final activeEvents = events
        .where((e) => e.status.toLowerCase() == 'ongoing' || e.isAttendanceOpen)
        .length;
    final totalMembers = members.length;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildMetricCard(
                context,
                title: 'Students Registered',
                value: '$totalStudents',
                icon: Icons.school_outlined,
                accentColor: AppColors.accentOf(context),
              ),
              const SizedBox(height: 10),
              _buildMetricCard(
                context,
                title: 'Avg. Attendance',
                value: '${avgAttendance.toStringAsFixed(1)}%',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.successOf(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _buildMetricCard(
                context,
                title: 'Active Events',
                value: '$activeEvents',
                icon: Icons.event_available_outlined,
                accentColor: AppColors.warningOf(context),
              ),
              const SizedBox(height: 10),
              _buildMetricCard(
                context,
                title: 'Society Members',
                value: '$totalMembers',
                icon: Icons.groups_outlined,
                accentColor: AppColors.accentOf(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return BrlGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMd.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchAttendanceChart(
      BuildContext context, List<StudentEntity> students) {
    if (students.isEmpty) {
      return BrlGlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No student data available to chart',
            style: AppTextStyles.bodySm
                .copyWith(color: AppColors.textSecondaryOf(context)),
          ),
        ),
      );
    }

    // Aggregate by branch
    final branchAverages = <String, double>{};
    final branchCounts = <String, int>{};

    for (final s in students) {
      branchAverages[s.branch] =
          (branchAverages[s.branch] ?? 0.0) + s.attendance;
      branchCounts[s.branch] = (branchCounts[s.branch] ?? 0) + 1;
    }

    final branches = branchCounts.keys.toList()..sort();
    final topBranches = branches.take(6).toList();

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < topBranches.length; i++) {
      final b = topBranches[i];
      final avg = (branchAverages[b]! / branchCounts[b]!).clamp(0.0, 100.0);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avg,
              color: AppColors.accentOf(context),
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: AppColors.borderOf(context),
              ),
            ),
          ],
        ),
      );
    }

    return BrlGlassCard(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Attendance by Branch',
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Top Branches (%)',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondaryOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceOf(context),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final branch = topBranches[group.x.toInt()];
                      return BarTooltipItem(
                        '$branch\n${rod.toY.toStringAsFixed(1)}%',
                        AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= topBranches.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            topBranches[idx],
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondaryOf(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          '${val.toInt()}%',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            color: AppColors.textTertiaryOf(context),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderOf(context),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventStatusBreakdown(
      BuildContext context, List<EventEntity> events) {
    int upcoming = 0;
    int ongoing = 0;
    int completed = 0;
    int cancelled = 0;

    for (final e in events) {
      switch (e.status.toLowerCase()) {
        case 'upcoming':
          upcoming++;
          break;
        case 'ongoing':
          ongoing++;
          break;
        case 'completed':
          completed++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    final total = events.length;

    return BrlGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Events Overview',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(
                '$total Total Events',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(context, 'Ongoing & Open', ongoing, total,
              AppColors.successOf(context)),
          const SizedBox(height: 10),
          _buildStatusRow(context, 'Upcoming', upcoming, total,
              AppColors.warningOf(context)),
          const SizedBox(height: 10),
          _buildStatusRow(context, 'Completed', completed, total,
              AppColors.accentOf(context)),
          if (cancelled > 0) ...[
            const SizedBox(height: 10),
            _buildStatusRow(context, 'Cancelled', cancelled, total,
                AppColors.errorOf(context)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      BuildContext context, String label, int count, int total, Color color) {
    final double fraction = total == 0 ? 0 : (count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.bodySm),
              ],
            ),
            Text(
              '$count (${(fraction * 100).toStringAsFixed(0)}%)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOf(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.borderOf(context),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCompositionCard(
      BuildContext context, List<UserEntity> members) {
    final superAdmins = members
        .where((m) => m.role == UserRole.superAdmin || m.role == UserRole.admin)
        .length;
    final coordinators =
        members.where((m) => m.role == UserRole.coordinator).length;
    final volunteers =
        members.where((m) => m.role == UserRole.volunteer).length;
    final total = members.length;

    return BrlGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Staff & Volunteers',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(
                '$total Active Members',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRoleStatTile(
                  context,
                  role: 'Executive',
                  count: superAdmins,
                  color: AppColors.warningOf(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRoleStatTile(
                  context,
                  role: 'Coordinators',
                  count: coordinators,
                  color: AppColors.accentOf(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRoleStatTile(
                  context,
                  role: 'Volunteers',
                  count: volunteers,
                  color: AppColors.successOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleStatTile(BuildContext context,
      {required String role, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.6),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: AppTextStyles.headlineSm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
