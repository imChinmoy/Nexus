import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';

class ManualAttendanceScreen extends ConsumerStatefulWidget {
  final String eventId;
  const ManualAttendanceScreen({super.key, this.eventId = ''});

  @override
  ConsumerState<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends ConsumerState<ManualAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'MANUAL ENTRY',
          accentColor: AppColors.moduleAttendance,
          showBack: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BrlTextField(label: 'Search Student Roll No...'),
            const SizedBox(height: 24),
            BrlGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mark Status', style: AppTextStyles.bodyLg),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(label: const Text('PRESENT'), backgroundColor: AppColors.accentGreen.withOpacity(0.2), onPressed: (){}),
                      ActionChip(label: const Text('ABSENT'), backgroundColor: AppColors.error.withOpacity(0.2), onPressed: (){}),
                      ActionChip(label: const Text('LATE'), backgroundColor: AppColors.accentAmber.withOpacity(0.2), onPressed: (){}),
                      ActionChip(label: const Text('EXCUSED'), backgroundColor: AppColors.moduleMembers.withOpacity(0.2), onPressed: (){}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            BrlButton(
              label: 'SUBMIT',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
