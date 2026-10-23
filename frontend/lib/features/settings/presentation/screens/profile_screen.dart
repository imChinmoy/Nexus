import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider);
    final nameChanged = user?.name != _nameController.text.trim();

    String? error;

    if (nameChanged) {
      error = await ref.read(authNotifierProvider.notifier).updateProfile(name: _nameController.text.trim());
    }

    if (error == null && _imageFile != null) {
      error = await ref.read(authNotifierProvider.notifier).updateAvatar(_imageFile!);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.errorOf(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.successOf(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = user?.name.isNotEmpty == true
        ? user!.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Edit Profile',
          showBack: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              const SizedBox(height: 12),
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: ClipOval(
                          child: _imageFile != null
                              ? Image.file(_imageFile!, width: 96, height: 96, fit: BoxFit.cover)
                              : (user?.avatar != null && user!.avatar!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: user.avatar!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Center(
                                        child: Text(
                                          initials,
                                          style: AppTextStyles.headlineLg.copyWith(color: accent, fontSize: 32),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: AppTextStyles.headlineLg.copyWith(color: accent, fontSize: 32),
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceOf(context), width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to change photo',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryOf(context)),
                ),
              ),
              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'ACCOUNT DETAILS',
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
                      controller: _nameController,
                      label: 'Full Name',
                      hintText: 'Enter your name',
                      prefix: Icon(Icons.person_outline, size: 18, color: AppColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 14),
                    BrlTextField(
                      controller: _emailController,
                      label: 'Email (Primary Identifier)',
                      hintText: 'Your registered email',
                      prefix: Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondaryOf(context)),
                      enabled: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              BrlButton(
                onPressed: _updateProfile,
                label: 'Save Changes',
                icon: Icons.check,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
