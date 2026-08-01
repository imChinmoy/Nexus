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
                  Text('Aug 1, 2026', style: AppTextStyles.bodySm),
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
