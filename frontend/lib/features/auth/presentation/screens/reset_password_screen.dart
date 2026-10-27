import 'package:flutter/material.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(title: 'Set New Password', showBack: true),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: BrlGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create New Password',
                          style: AppTextStyles.headlineSm,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your new password must be at least 6 characters.',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        BrlTextField(
                          label: 'New Password',
                          controller: _passwordController,
                          obscureText: true,
                          validator: Validators.password,
                          textInputAction: TextInputAction.next,
                          prefix: Icon(
                            Icons.lock_outline_rounded,
                            color: textSecondary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BrlTextField(
                          label: 'Confirm Password',
                          controller: _confirmController,
                          obscureText: true,
                          validator: (v) => Validators.confirmPassword(
                              v, _passwordController.text),
                          textInputAction: TextInputAction.done,
                          prefix: Icon(
                            Icons.lock_outline_rounded,
                            color: textSecondary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        BrlButton(
                          label: 'Update Password',
                          isLoading: _isLoading,
                          isFullWidth: true,
                          height: 48,
                          onPressed: _isLoading ? null : () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
