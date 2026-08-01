import os

base_dir = r"D:\develop\college\attend\lib\features"

files = {
    r"dashboard\presentation\screens\dashboard_screen.dart": """
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
          children: const [
            BrlStatsCard(
              title: 'TOTAL STUDENTS',
              value: '342',
              icon: Icons.school_rounded,
              accentColor: AppColors.moduleStudents,
              changePercent: 8.2,
            ),
            BrlStatsCard(
              title: 'ACTIVE MEMBERS',
              value: '28',
              icon: Icons.group_rounded,
              accentColor: AppColors.moduleMembers,
              changePercent: 2.1,
            ),
            BrlStatsCard(
              title: 'EVENTS TODAY',
              value: '3',
              icon: Icons.event_rounded,
              accentColor: AppColors.moduleEvents,
            ),
            BrlStatsCard(
              title: 'ATTENDANCE RATE',
              value: '87%',
              icon: Icons.check_circle_outline_rounded,
              accentColor: AppColors.moduleAttendance,
              changePercent: 4.5,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('QR SCAN', Icons.qr_code_scanner_rounded, AppColors.accentGreen, RouteConstants.qrScanner),
      _QuickAction('MANUAL', Icons.edit_note_rounded, AppColors.primary, RouteConstants.manualAttendance),
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
        BrlGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(4, (i) => _AttendanceListItem(
              name: ['Arjun Kumar', 'Priya Singh', 'Rahul Dev', 'Meena Nair'][i],
              roll: ['21CS001', '21CS042', '21EC018', '22ME007'][i],
              status: [NeonBadgeType.success, NeonBadgeType.error, NeonBadgeType.warning, NeonBadgeType.success][i],
              statusLabel: ['PRESENT', 'ABSENT', 'LATE', 'PRESENT'][i],
              time: ['2m ago', '5m ago', '12m ago', '18m ago'][i],
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('UPCOMING EVENTS', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
            GestureDetector(
              onTap: () {},
              child: Text('View All', style: AppTextStyles.bodySm.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _EventCard(
              title: ['Blockchain Workshop', 'AI Seminar', 'Recruitment Drive'][i],
              date: ['Aug 5, 2026', 'Aug 8, 2026', 'Aug 15, 2026'][i],
              type: ['Workshop', 'Seminar', 'Recruitment'][i],
              color: [AppColors.secondary, AppColors.primary, AppColors.accentPink][i],
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
""",
    r"students\presentation\screens\students_screen.dart": """
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/brl_app_bar.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _searchVisible = false;

  final _filters = ['All', 'CSE', 'ECE', 'ME', 'EEE', 'Year 1', 'Year 2', 'Year 3', 'Year 4'];

  final _demoStudents = List.generate(12, (i) => _StudentData(
    name: ['Arjun Kumar', 'Priya Singh', 'Rahul Dev', 'Meena Nair', 'Vikram Patel', 'Sneha Rao',
           'Karthik M', 'Anitha S', 'Deepak J', 'Lakshmi P', 'Suresh K', 'Divya T'][i],
    roll: ['21CS001', '21CS042', '21EC018', '22ME007', '21CS099', '22CS034',
           '21EC077', '22CS011', '21ME045', '21CS067', '22EC009', '21CS088'][i],
    branch: ['CSE', 'CSE', 'ECE', 'ME', 'CSE', 'CSE', 'ECE', 'CSE', 'ME', 'CSE', 'ECE', 'CSE'][i],
    year: [3, 3, 3, 2, 3, 2, 3, 2, 3, 3, 2, 3][i],
    attendance: [92, 87, 65, 100, 78, 95, 43, 88, 71, 90, 56, 82][i],
  ));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(
          title: 'STUDENTS',
          accentColor: AppColors.moduleStudents,
          actions: [
            IconButton(
              icon: Icon(
                _searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
                color: AppColors.primary,
              ),
              onPressed: () => setState(() => _searchVisible = !_searchVisible),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            if (_searchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BrlTextField(
                  label: 'Search students...',
                  controller: _searchController,
                  prefix: const Icon(Icons.search, color: AppColors.onSurfaceSubtle, size: 18),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            _buildFilterChips(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                child: _buildStudentList(),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFab(context),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _filters[i] == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.primary : null,
                color: isSelected ? null : AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.glassStroke,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8),
                ] : null,
              ),
              child: Text(
                _filters[i],
                style: AppTextStyles.labelMd.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentList() {
    final filtered = _demoStudents.where((s) {
      final matchesSearch = _searchController.text.isEmpty ||
          s.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          s.roll.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || s.branch == _selectedFilter ||
          _selectedFilter == 'Year ${s.year}';
      return matchesSearch && matchesFilter;
    }).toList();

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.school_outlined,
        title: 'No Students Found',
        message: 'Try adjusting your search or filter criteria.',
        iconColor: AppColors.moduleStudents,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _StudentListItem(
        student: filtered[i],
        onTap: () => context.push('/students/${filtered[i].roll}'),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.addStudent),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.accentPink.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

class _StudentData {
  final String name, roll, branch;
  final int year, attendance;
  const _StudentData({required this.name, required this.roll, required this.branch, required this.year, required this.attendance});
}

class _StudentListItem extends StatelessWidget {
  final _StudentData student;
  final VoidCallback onTap;
  const _StudentListItem({required this.student, required this.onTap});

  Color get _attendanceColor {
    if (student.attendance >= 80) return AppColors.accentGreen;
    if (student.attendance >= 60) return AppColors.accentAmber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BrlGlassCard(
        borderColor: AppColors.moduleStudents.withOpacity(0.15),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  student.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: AppTextStyles.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(student.roll, style: AppTextStyles.monoCode.copyWith(fontSize: 10)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.moduleStudents.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${student.branch} Y${student.year}',
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.moduleStudents),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${student.attendance}%',
                  style: AppTextStyles.labelLg.copyWith(color: _attendanceColor),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: student.attendance / 100,
                      backgroundColor: AppColors.surfaceGlass,
                      valueColor: AlwaysStoppedAnimation(_attendanceColor),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}
""",
    r"students\presentation\screens\student_detail_screen.dart": """
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'STUDENT DETAIL',
          accentColor: AppColors.moduleStudents,
          showBack: true,
        ),
        body: Column(
          children: [
            _buildHero(),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              tabs: const [
                Tab(text: 'OVERVIEW'),
                Tab(text: 'ATTENDANCE'),
                Tab(text: 'QR CARD'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAttendanceTab(),
                  _buildQrCardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Hero(
            tag: 'avatar_${widget.studentId}',
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20),
                ],
              ),
              child: Center(
                child: Text(
                  'AK',
                  style: AppTextStyles.headlineLg.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Arjun Kumar', style: AppTextStyles.headlineMd),
          Text(widget.studentId, style: AppTextStyles.monoCode),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BrlGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow('Branch', 'Computer Science (CSE)'),
              const Divider(color: AppColors.glassStroke),
              _buildInfoRow('Year', '3rd Year'),
              const Divider(color: AppColors.glassStroke),
              _buildInfoRow('Email', 'arjun.k@college.edu'),
              const Divider(color: AppColors.glassStroke),
              _buildInfoRow('Phone', '+91 9876543210'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMdMuted),
          Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return BrlGlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Blockchain Workshop', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                  Text('Aug 1, 2026', style: AppTextStyles.bodySmMuted),
                ],
              ),
              const NeonBadge(label: 'PRESENT', type: NeonBadgeType.success),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrCardTab() {
    return Center(
      child: BrlGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 20),
                ],
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: widget.studentId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 24),
            Text('SCAN FOR ATTENDANCE', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
""",
    r"students\presentation\screens\add_student_screen.dart": """
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'ADD STUDENT',
          accentColor: AppColors.moduleStudents,
          showBack: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('PERSONAL INFO', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
              const SizedBox(height: 8),
              BrlGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BrlTextField(label: 'Full Name'),
                    const SizedBox(height: 12),
                    BrlTextField(label: 'Roll Number'),
                    const SizedBox(height: 12),
                    BrlTextField(label: 'Email Address'),
                    const SizedBox(height: 12),
                    BrlTextField(label: 'Phone Number'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('ACADEMIC INFO', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
              const SizedBox(height: 8),
              BrlGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BrlTextField(label: 'Branch'),
                    const SizedBox(height: 12),
                    BrlTextField(label: 'Year'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              BrlButton(
                label: 'SAVE STUDENT',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    r"attendance\presentation\screens\qr_scanner_screen.dart": """
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  bool _torchOn = false;
  bool _isProcessing = false;
  String? _result;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();
    // TODO: Call attendance service with QR token
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _success = true;
          _result = 'Attendance recorded!';
          _isProcessing = false;
        });
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() { _success = false; _result = null; });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _buildOverlay(),
          _buildTopBar(context),
          if (_result != null) _buildResultOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, _) {
        return CustomPaint(
          painter: _QrOverlayPainter(
            scanLineProgress: _scanLineAnimation.value,
            isSuccess: _success,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassStroke),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('QR SCANNER', style: AppTextStyles.labelLg.copyWith(color: AppColors.primary, letterSpacing: 2)),
                Text('ATTENDANCE MODE', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
            GestureDetector(
              onTap: () {
                _controller.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _torchOn ? AppColors.primaryGlow : Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _torchOn ? AppColors.primary : AppColors.glassStroke),
                ),
                child: Icon(
                  _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _torchOn ? AppColors.primary : AppColors.onSurfaceMuted,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    return Positioned(
      bottom: 80,
      left: 40,
      right: 40,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _success ? AppColors.accentGreen.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _success ? AppColors.accentGreen.withOpacity(0.5) : AppColors.error.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              _success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _success ? AppColors.accentGreen : AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_result!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface))),
          ],
        ),
      ),
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  final double scanLineProgress;
  final bool isSuccess;

  _QrOverlayPainter({required this.scanLineProgress, required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final scanBoxSize = size.width * 0.65;
    final scanBoxLeft = (size.width - scanBoxSize) / 2;
    final scanBoxTop = (size.height - scanBoxSize) / 2;
    final rect = Rect.fromLTWH(scanBoxLeft, scanBoxTop, scanBoxSize, scanBoxSize);

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    canvas.drawPath(Path.combine(PathOperation.difference, path, holePath), overlayPaint);

    final cornerColor = isSuccess ? AppColors.accentGreen : AppColors.primary;
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSuccess ? 4 : 2);

    const cornerLen = 24.0;
    const r = 20.0;
    canvas.drawLine(Offset(scanBoxLeft + r, scanBoxTop), Offset(scanBoxLeft + r + cornerLen, scanBoxTop), cornerPaint);
    canvas.drawLine(Offset(scanBoxLeft, scanBoxTop + r), Offset(scanBoxLeft, scanBoxTop + r + cornerLen), cornerPaint);
    canvas.drawLine(Offset(scanBoxLeft + scanBoxSize - r - cornerLen, scanBoxTop), Offset(scanBoxLeft + scanBoxSize - r, scanBoxTop), cornerPaint);
    canvas.drawLine(Offset(scanBoxLeft + scanBoxSize, scanBoxTop + r), Offset(scanBoxLeft + scanBoxSize, scanBoxTop + r + cornerLen), cornerPaint);
    canvas.drawLine(Offset(scanBoxLeft + r, scanBoxTop + scanBoxSize), Offset(scanBoxLeft + r + cornerLen, scanBoxTop + scanBoxSize), cornerPaint);
    canvas.drawLine(Offset(scanBoxLeft, scanBoxTop + scanBoxSize - r - cornerLen), Offset(scanBoxLeft, scanBoxTop + scanBoxSize - r), cornerPaint);
    canvas.drawLine(Offset(scanBoxLeft + scanBoxSize - r - cornerLen, scanBoxTop + scanBoxSize), Offset(scanBoxLeft + scanBoxSize - r, scanBoxTop + scanBoxSize), cornerPaint);
    canvas.drawLine(Offset(scanBoxLeft + scanBoxSize, scanBoxTop + scanBoxSize - r - cornerLen), Offset(scanBoxLeft + scanBoxSize, scanBoxTop + scanBoxSize - r), cornerPaint);

    if (!isSuccess) {
      final scanY = scanBoxTop + scanBoxSize * scanLineProgress;
      final scanLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, AppColors.primary, Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(Offset(scanBoxLeft + 4, scanY), Offset(scanBoxLeft + scanBoxSize - 4, scanY), scanLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QrOverlayPainter old) =>
      old.scanLineProgress != scanLineProgress || old.isSuccess != isSuccess;
}
"""
}
for path, content in files.items():
    full_path = os.path.join(base_dir, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content.strip())
