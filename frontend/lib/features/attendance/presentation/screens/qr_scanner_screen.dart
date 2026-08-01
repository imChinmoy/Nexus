import 'package:flutter/material.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_colors.dart';

class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(title: 'QR Scanner', showBack: true, accentColor: AppColors.moduleAttendance),
        body: EmptyStateWidget(
          icon: Icons.qr_code_scanner_rounded,
          title: 'QR Scanner',
          message: 'Scanner will appear here',
          iconColor: AppColors.moduleAttendance,
        ),
      ),
    );
  }
}
