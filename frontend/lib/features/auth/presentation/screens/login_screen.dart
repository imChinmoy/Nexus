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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
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

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CyberLogo(size: 80),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'BRL NEXUS',
                          style: AppTextStyles.displayLg.copyWith(
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'BLOCKCHAIN RESEARCH LAB',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSurfaceMuted,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 40),
                      BrlGlassCard(
                        borderColor: AppColors.glassStroke,
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'INITIALIZE ACCESS',
                                style: AppTextStyles.labelLg.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              BrlTextField(
                                label: 'Email Address',
                                hint: 'admin@brl.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                                prefix: const Icon(
                                  Icons.alternate_email_rounded,
                                  color: AppColors.onSurfaceSubtle,
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
                                prefix: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.onSurfaceSubtle,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => context.push(RouteConstants.forgotPassword),
                                  child: Text(
                                    'Forgot Password?',
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              if (errorMessage != null) ...
                                [
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      errorMessage,
                                      style: AppTextStyles.bodySm
                                          .copyWith(color: AppColors.error),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              const SizedBox(height: 24),
                              BrlButton(
                                label: 'LOGIN',
                                isLoading: isLoading,
                                isFullWidth: true,
                                onPressed: isLoading ? null : _handleLogin,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'v${AppConstants.appVersion} • NODE ACTIVE',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceSubtle,
                          letterSpacing: 2,
                        ),
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
