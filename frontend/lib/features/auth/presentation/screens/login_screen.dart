import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../widgets/cyber_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState.whenOrNull(error: (message) => message);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CyberLogo(size: 76),
                    const SizedBox(height: 20),
                    Text(
                      'Nexus',
                      style: AppTextStyles.displayLg.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to manage society and attendance',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    BrlGlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BrlTextField(
                              label: 'Email Address',
                              hint: 'name@akgec.ac.in',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                              prefix: Icon(
                                Icons.alternate_email_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 16),
                            BrlTextField(
                              label: 'Password',
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validator: Validators.password,
                              onSubmitted: (_) => _handleLogin(),
                              prefix: Icon(
                                Icons.lock_outline_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.push(RouteConstants.forgotPassword),
                                child: Text(
                                  'Forgot password?',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 16),
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
                                        errorMessage,
                                        style: AppTextStyles.bodySm.copyWith(color: errorColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            BrlButton(
                              label: 'Sign In',
                              isLoading: isLoading,
                              isFullWidth: true,
                              height: 48,
                              onPressed: isLoading ? null : _handleLogin,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'v${AppConstants.appVersion} • BRL AKGEC',
                      style: AppTextStyles.caption.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
