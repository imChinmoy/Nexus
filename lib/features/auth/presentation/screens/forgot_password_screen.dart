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
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
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
    setState(() => _isLoading = false);
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(title: 'Password Recovery', showBack: true),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _sent
                  ? _SentConfirmation(email: _emailController.text)
                  : BrlGlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'RECOVERY PROTOCOL',
                              style: AppTextStyles.labelLg.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your registered email to receive a password reset link.',
                              style: AppTextStyles.bodyMdMuted,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            BrlTextField(
                              label: 'Email Address',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: Validators.email,
                              onSubmitted: (_) => _submit(),
                              prefix: const Icon(
                                Icons.alternate_email_rounded,
                                color: AppColors.onSurfaceSubtle,
                                size: 18,
                              ),
                            ),
                            if (_error != null) ...
                              [
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: AppTextStyles.bodySm
                                      .copyWith(color: AppColors.error),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            const SizedBox(height: 24),
                            BrlButton(
                              label: 'Send Reset Link',
                              isLoading: _isLoading,
                              isFullWidth: true,
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
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  final String email;

  const _SentConfirmation({required this.email});

  @override
  Widget build(BuildContext context) {
    return BrlGlassCard(
      borderColor: AppColors.glassStrokeGreen,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.accentGreen,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text('Recovery Link Sent!', style: AppTextStyles.headlineSm),
          const SizedBox(height: 8),
          Text(
            'Check your inbox at $email for the password reset link.',
            style: AppTextStyles.bodyMdMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
