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
                _buildHero(student.name, student.rollNumber),
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
                      _buildAttendanceTab(),
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

  Widget _buildHero(String name, String rollNumber) {
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
                  name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'U',
                  style: AppTextStyles.headlineLg.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: AppTextStyles.headlineMd),
          Text(rollNumber, style: AppTextStyles.monoCode),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(dynamic student) {
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
        children: [
          BrlGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow('Branch', student.branch),
              const Divider(color: AppColors.glassStroke),
              _buildInfoRow('Year', '${student.year} Year'),
              const Divider(color: AppColors.glassStroke),
              _buildInfoRow('Email', student.email),
              const Divider(color: AppColors.glassStroke),
              _buildInfoRow('Attendance', '${student.attendance}%'),
            ],
          ),
        ),
      ],
    ),
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
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(studentsProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 300,
          child: const Center(child: Text('No attendance records', style: TextStyle(color: AppColors.onSurfaceMuted))),
        ),
      ),
    );
  }

  Widget _buildQrCardTab(String data) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(studentsProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
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
                      data: data,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('SCAN FOR ATTENDANCE', style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
