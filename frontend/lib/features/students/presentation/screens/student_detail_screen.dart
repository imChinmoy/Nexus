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
import '../../../../shared/widgets/brl_stats_card.dart';
import '../../providers/student_provider.dart';

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
    final studentsAsync = ref.watch(studentsProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'STUDENT DETAIL',
          accentColor: AppColors.moduleStudents,
          showBack: true,
        ),
        body: studentsAsync.maybeWhen(
          data: (students) {
            final student = students.firstWhere(
              (s) => s.rollNumber == widget.studentId || s.id == widget.studentId,
              orElse: () => throw Exception('Student not found'),
            );
            return Column(
              children: [
                _buildHero(student.name, student.rollNumber, student.studentNo),
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
                      _buildOverviewTab(student),
                      _buildAttendanceTab(student),
                      _buildQrCardTab(student.rollNumber),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          orElse: () => const Center(child: Text('Failed to load student')),
        ),
      ),
    );
  }

  Widget _buildHero(String name, String rollNumber, String studentNo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Hero(
            tag: 'avatar_${widget.studentId}',
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'U',
                  style: AppTextStyles.headlineLg.copyWith(color: Colors.white, fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$rollNumber • $studentNo', style: AppTextStyles.bodyMdMuted),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(dynamic student) {
    return _buildTabContainer(
      child: BrlGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMinimalRow(Icons.email_outlined, 'Email', student.email),
            const Divider(color: AppColors.glassStroke, height: 24),
            _buildMinimalRow(Icons.account_balance_outlined, 'Branch', student.branch),
            const Divider(color: AppColors.glassStroke, height: 24),
            _buildMinimalRow(Icons.school_outlined, 'Year', '${student.year} Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyMdMuted),
        const Spacer(),
        Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAttendanceTab(dynamic student) {
    double attendanceVal = double.tryParse(student.attendance.toString()) ?? 0.0;
    Color attendanceColor = attendanceVal >= 75 ? AppColors.success : (attendanceVal >= 60 ? AppColors.warning : AppColors.error);
    
    return _buildTabContainer(
      child: BrlGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: attendanceVal / 100,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceDark,
                    valueColor: AlwaysStoppedAnimation<Color>(attendanceColor),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${student.attendance}%', style: AppTextStyles.headlineMd.copyWith(color: attendanceColor, fontWeight: FontWeight.bold)),
                      Text('Overall', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: student.isPresent ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: student.isPresent ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    student.isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: student.isPresent ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    student.isPresent ? 'Present Today' : 'Absent Today',
                    style: AppTextStyles.labelMd.copyWith(
                      color: student.isPresent ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCardTab(String data) {
    return _buildTabContainer(
      child: Center(
        child: BrlGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text('STUDENT QR CODE', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContainer({required Widget child}) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(studentsProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [child],
      ),
    );
  }
}
