import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  // Hardcoded event ID for Reload 26 Recruitment Drive
  static const String hardcodedEventId = '6a6dc76d77dff0bef5d29082';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'ATTENDANCE HUB',
          accentColor: AppColors.moduleAttendance,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {
                  context.push('${RouteConstants.attendance}/qr-scan?eventId=$hardcodedEventId');
                },
                child: BrlGlassCard(
                  padding: const EdgeInsets.all(24),
                  borderColor: AppColors.accentGreen,
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.accentGreen),
                      const SizedBox(height: 16),
                      Text('QR SCANNER', style: AppTextStyles.headlineMd.copyWith(color: AppColors.accentGreen)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  context.push('${RouteConstants.attendance}/manual?eventId=$hardcodedEventId');
                },
                child: BrlGlassCard(
                  padding: const EdgeInsets.all(24),
                  borderColor: AppColors.primary,
                  child: Column(
                    children: [
                      const Icon(Icons.edit_note, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('MANUAL ENTRY', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
