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
