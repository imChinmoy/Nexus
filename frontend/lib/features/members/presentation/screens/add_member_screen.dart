import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Add Member',
          showBack: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'MEMBER PROFILE',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            BrlGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  BrlTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    hintText: 'Member Name',
                  ),
                  const SizedBox(height: 12),
                  BrlTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    hintText: 'member@society.org',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            BrlButton(
              label: 'Save Member',
              icon: Icons.check,
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
