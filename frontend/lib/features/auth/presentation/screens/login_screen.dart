import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../widgets/cyber_logo.dart';

enum _AuthMode { login, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.login;

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _regSecretKeyController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _regSecretKeyController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode newMode) {
    if (_mode == newMode) return;
    setState(() {
      _mode = newMode;
    });
    ref.read(authNotifierProvider.notifier).clearError();
  }

  Future<void> _handleLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).login(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        );
  }

  Future<void> _handleRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).register(
          name: _regNameController.text.trim(),
          email: _regEmailController.text.trim(),
          password: _regPasswordController.text,
          secretKey: _regSecretKeyController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState.whenOrNull(error: (message) => message);

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: Stack(
        children: [
          // Background artwork from assets/images/bg.png
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF090D1A));
              },
            ),
          ),

          // Deep atmospheric gradient overlays for high readability & glowing aesthetics
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD9070A14), // 85% opacity dark blue-gray
                    Color(0x9E0A1024), // 62% opacity
                    Color(0xF504060E), // 96% opacity near bottom
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Subtle radial glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.1,
                  colors: [
                    Color(0x2E2997FF),
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Society Branding & Cyber Logo
                      const CyberLogo(size: 68),
                      const SizedBox(height: 16),

                      // Society Portal Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0x1F2997FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0x402997FF),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF30D158),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'BRL NEXUS • SOCIETY PORTAL',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF64B5F6),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Main Title
                      Text(
                        'Nexus',
                        style: AppTextStyles.displayLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle with smooth transition
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _mode == _AuthMode.login
                              ? 'Sign in to access events, attendance & member hub'
                              : 'Create an account with your society member passkey',
                          key: ValueKey(_mode),
                          style: AppTextStyles.bodyMd.copyWith(
                            color: const Color(0xFFA1AAB9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mode Switcher (Sign In vs Register with sliding indicator)
                      _buildModeSwitcher(),
                      const SizedBox(height: 20),

                      // Glass Card Form with smooth height transition
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xCC0E1424),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0x334E80FF),
                                width: 0.8,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Color(0x142997FF),
                                  blurRadius: 30,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder: (currentChild, previousChildren) {
                                  return Stack(
                                    alignment: Alignment.topCenter,
                                    children: <Widget>[
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  );
                                },
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    ),
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.04),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _mode == _AuthMode.login
                                    ? _buildLoginForm(isLoading, errorMessage)
                                    : _buildRegisterForm(isLoading, errorMessage),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'v${AppConstants.appVersion} • Blockchain Research Lab AKGEC',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x80101726),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x264E80FF),
          width: 0.8,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Gliding Glow Pill Indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: _mode == _AuthMode.login
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: pillWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2997FF), Color(0xFF1E80E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x592997FF),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Interactive Triggers
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchMode(_AuthMode.login),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: _mode == _AuthMode.login
                                ? Colors.white
                                : const Color(0xFF8E9BB0),
                            fontWeight: _mode == _AuthMode.login
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchMode(_AuthMode.register),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: _mode == _AuthMode.register
                                ? Colors.white
                                : const Color(0xFF8E9BB0),
                            fontWeight: _mode == _AuthMode.register
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          child: const Text('Register'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading, String? errorMessage) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrlTextField(
            label: 'Email Address',
            hint: 'name@akgec.ac.in',
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            prefix: const Icon(
              Icons.alternate_email_rounded,
              color: Color(0xFF8E9BB0),
              size: 18,
            ),
          ),
          const SizedBox(height: 16),
          BrlTextField(
            label: 'Password',
            hint: '••••••••',
            controller: _loginPasswordController,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: Validators.password,
            onSubmitted: (_) => _handleLogin(),
            prefix: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF8E9BB0),
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
                  color: const Color(0xFF2997FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBox(errorMessage),
          ],
          const SizedBox(height: 24),
          BrlButton(
            label: 'Sign In to Nexus',
            isLoading: isLoading,
            isFullWidth: true,
            height: 48,
            onPressed: isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => _switchMode(_AuthMode.register),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF8E9BB0)),
                  children: [
                    const TextSpan(text: "Society member without account? "),
                    TextSpan(
                      text: 'Register here',
                      style: AppTextStyles.bodySm.copyWith(
                        color: const Color(0xFF2997FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isLoading, String? errorMessage) {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name
          BrlTextField(
            label: 'Full Name',
            hint: 'e.g. Chinmoy Anand',
            controller: _regNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
            prefix: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF8E9BB0),
              size: 18,
            ),
          ),
          const SizedBox(height: 14),

          // Email
          BrlTextField(
            label: 'Email Address',
            hint: 'name@akgec.ac.in',
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            prefix: const Icon(
              Icons.alternate_email_rounded,
              color: Color(0xFF8E9BB0),
              size: 18,
            ),
          ),
          const SizedBox(height: 14),

          // Password
          BrlTextField(
            label: 'Password',
            hint: 'Min. 8 characters',
            controller: _regPasswordController,
            isPassword: true,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
            prefix: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF8E9BB0),
              size: 18,
            ),
          ),
          const SizedBox(height: 14),

          // Confirm Password
          BrlTextField(
            label: 'Confirm Password',
            hint: 'Re-enter password',
            controller: _regConfirmPasswordController,
            isPassword: true,
            textInputAction: TextInputAction.next,
            validator: (val) => Validators.confirmPassword(val, _regPasswordController.text),
            prefix: const Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF8E9BB0),
              size: 18,
            ),
          ),
          const SizedBox(height: 14),

          // Society Secret Passkey
          BrlTextField(
            label: 'Society Secret Key',
            hint: 'Enter secret passkey',
            controller: _regSecretKeyController,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Society secret passkey is required';
              }
              return null;
            },
            onSubmitted: (_) => _handleRegister(),
            prefix: const Icon(
              Icons.key_rounded,
              color: Color(0xFF2997FF),
              size: 18,
            ),
          ),
          const SizedBox(height: 12),

          // Member verification info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x1A2997FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0x332997FF),
                width: 0.6,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF2997FF),
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Passkey verification ensures only BRL society members & associated team can register. New accounts will automatically be granted Viewer access.',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF90CAF9),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorBox(errorMessage),
          ],

          const SizedBox(height: 20),
          BrlButton(
            label: 'Create Member Account',
            isLoading: isLoading,
            isFullWidth: true,
            height: 48,
            onPressed: isLoading ? null : _handleRegister,
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => _switchMode(_AuthMode.login),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF8E9BB0)),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign in',
                      style: AppTextStyles.bodySm.copyWith(
                        color: const Color(0xFF2997FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x26FF3B30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x66FF3B30),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF453A),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(
                color: const Color(0xFFFF6961),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
