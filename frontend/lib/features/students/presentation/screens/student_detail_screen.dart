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
import '../../domain/entities/student_entity.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
                    Tab(text: 'QR CARD'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(student),
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

  Widget _buildOverviewTab(StudentEntity student) {
    return _buildTabContainer(
      child: Column(
        children: [
          BrlGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMinimalRow(Icons.email_outlined, 'Email', student.email),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.phone_outlined, 'Phone', student.phone ?? 'N/A'),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.account_balance_outlined, 'Branch', student.branch),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.school_outlined, 'Year', '${student.year} Year'),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.domain_outlined, 'Domain', student.domain ?? 'N/A'),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.person_outline, 'Gender', student.gender ?? 'N/A'),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.hotel_outlined, 'Hosteller', student.hosteller == true ? 'Yes' : (student.hosteller == false ? 'No' : 'N/A')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BrlGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coding Profiles', style: AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
                const SizedBox(height: 16),
                _buildMinimalRow(Icons.code_outlined, 'GitHub', student.github ?? 'N/A'),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.emoji_events_outlined, 'Unstop', student.unstop ?? 'N/A'),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.terminal_outlined, 'HackerRank', student.hackerrank ?? 'N/A'),
                if (student.codingProfiles != null && student.codingProfiles!.isNotEmpty) ...[
                  for (var profile in student.codingProfiles!) ...[
                    const Divider(color: AppColors.glassStroke, height: 16),
                    _buildMinimalRow(Icons.laptop_chromebook_outlined, profile.platform, profile.username),
                  ]
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          BrlGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Information', style: AppTextStyles.labelLg.copyWith(color: AppColors.primary)),
                const SizedBox(height: 16),
                _buildMinimalRow(Icons.calendar_today_outlined, 'Joined', student.createdAt != null ? '${student.createdAt!.toLocal()}'.split(' ')[0] : 'N/A'),
                const Divider(color: AppColors.glassStroke, height: 16),
                _buildMinimalRow(Icons.update_outlined, 'Last Updated', student.updatedAt != null ? '${student.updatedAt!.toLocal()}'.split(' ')[0] : 'N/A'),
              ],
            ),
          ),
        ],
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
