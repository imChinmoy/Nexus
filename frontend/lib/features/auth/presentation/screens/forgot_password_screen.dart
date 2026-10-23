import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .forgotPassword(_emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(title: 'Password Recovery', showBack: true),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _sent
                    ? _SentConfirmation(email: _emailController.text.trim())
                    : BrlGlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Reset Your Password',
                                style: AppTextStyles.headlineSm,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your registered email address and we will send you a link to reset your password.',
                                style: AppTextStyles.bodyMd.copyWith(color: textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              BrlTextField(
                                label: 'Email Address',
                                hint: 'name@akgec.ac.in',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                validator: Validators.email,
                                onSubmitted: (_) => _submit(),
                                prefix: Icon(
                                  Icons.alternate_email_rounded,
                                  color: textSecondary,
                                  size: 18,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: errorColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: errorColor.withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded, color: errorColor, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: AppTextStyles.bodySm.copyWith(color: errorColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              BrlButton(
                                label: 'Send Recovery Link',
                                isLoading: _isLoading,
                                isFullWidth: true,
                                height: 48,
                                onPressed: _isLoading ? null : _submit,
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

class _SentConfirmation extends StatelessWidget {
  final String email;

  const _SentConfirmation({required this.email});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final successColor = isDark ? AppColors.successDark : AppColors.success;

    return BrlGlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              color: successColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Recovery Link Sent',
            style: AppTextStyles.headlineSm,
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a password reset link to $email. Please check your inbox.',
            style: AppTextStyles.bodyMd.copyWith(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BrlButton(
            label: 'Back to Sign In',
            variant: BrlButtonVariant.secondary,
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
