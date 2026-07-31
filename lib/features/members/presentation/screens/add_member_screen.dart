import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';

class AddMemberScreen extends ConsumerWidget {
  const AddMemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'ADD MEMBER',
          accentColor: AppColors.moduleMembers,
          showBack: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Search and add a student to the society team.', style: AppTextStyles.bodyMd),
            const SizedBox(height: 24),
            BrlButton(
              label: 'SAVE',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
