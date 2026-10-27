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
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();

  String? _selectedYear;
  String? _selectedDomain;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Alumni',
  ];

  final List<String> _domains = [
    'Technical & Architecture',
    'Web & Mobile Dev',
    'UI/UX & Brand Design',
    'Events & Logistics',
    'PR & Outreach',
    'General Member',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
        _bioController.text = user.bio ?? '';
        _githubController.text = user.github ?? '';
        _linkedinController.text = user.linkedin ?? '';
        setState(() {
          _selectedYear = user.year;
          _selectedDomain = user.domain;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
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

    final error = await ref.read(authNotifierProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          year: _selectedYear,
          domain: _selectedDomain,
          phone: _phoneController.text.trim(),
          bio: _bioController.text.trim(),
          github: _githubController.text.trim(),
          linkedin: _linkedinController.text.trim(),
        );

    String? avatarError;
    if (error == null && _imageFile != null) {
      avatarError = await ref
          .read(authNotifierProvider.notifier)
          .updateAvatar(_imageFile!);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      final finalError = error ?? avatarError;
      if (finalError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(finalError),
            backgroundColor: AppColors.errorOf(context),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.successOf(context),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        ? user!.name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    final dropdownBg = isDark ? const Color(0xFF1E212E) : Colors.white;
    final dropdownBorder =
        isDark ? const Color(0x2EFFFFFF) : const Color(0x1F000000);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Edit Profile',
          overline: 'NEXUS • IDENTITY & PROFILE',
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
                          border: Border.all(
                              color: accent.withValues(alpha: 0.35),
                              width: 1.5),
                        ),
                        child: ClipOval(
                          child: _imageFile != null
                              ? Image.file(_imageFile!,
                                  width: 96, height: 96, fit: BoxFit.cover)
                              : (user?.avatar != null &&
                                      user!.avatar!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: user.avatar!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Center(
                                        child: Text(
                                          initials,
                                          style: AppTextStyles.headlineLg
                                              .copyWith(
                                                  color: accent, fontSize: 32),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: AppTextStyles.headlineLg
                                            .copyWith(
                                                color: accent, fontSize: 32),
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
                            border: Border.all(
                                color: AppColors.surfaceOf(context), width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 15),
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
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondaryOf(context)),
                ),
              ),
              const SizedBox(height: 24),

              // 1. ACCOUNT DETAILS
              _buildSectionTitle('ACCOUNT DETAILS'),
              const SizedBox(height: 8),
              BrlGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BrlTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hintText: 'Enter your name',
                      prefix: Icon(Icons.person_outline,
                          size: 18, color: AppColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 14),
                    BrlTextField(
                      controller: _emailController,
                      label: 'Email (Primary Identifier)',
                      hintText: 'Your registered email',
                      prefix: Icon(Icons.email_outlined,
                          size: 18, color: AppColors.textSecondaryOf(context)),
                      enabled: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. ACADEMIC & SOCIETY ROLE
              _buildSectionTitle('ACADEMIC & SOCIETY ROLE'),
              const SizedBox(height: 8),
              BrlGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue:
                          _years.contains(_selectedYear) ? _selectedYear : null,
                      dropdownColor: dropdownBg,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Academic Year',
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: isDark
                              ? Colors.white70
                              : AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(Icons.school_outlined,
                            size: 18,
                            color: AppColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dropdownBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dropdownBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5)),
                      ),
                      items: _years.map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedYear = val),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _domains.contains(_selectedDomain)
                          ? _selectedDomain
                          : null,
                      dropdownColor: dropdownBg,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Society Domain',
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: isDark
                              ? Colors.white70
                              : AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(Icons.hub_outlined,
                            size: 18,
                            color: AppColors.textSecondaryOf(context)),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dropdownBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: dropdownBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5)),
                      ),
                      items: _domains.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDomain = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. CONTACT & SOCIAL PROFILES
              _buildSectionTitle('CONTACT & SOCIAL PROFILES'),
              const SizedBox(height: 8),
              BrlGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BrlTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: '+91 98765 43210',
                      keyboardType: TextInputType.phone,
                      prefix: Icon(Icons.phone_outlined,
                          size: 18, color: AppColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 14),
                    BrlTextField(
                      controller: _githubController,
                      label: 'GitHub Profile',
                      hintText: 'https://github.com/username',
                      prefix: Icon(Icons.code_rounded,
                          size: 18, color: AppColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: 14),
                    BrlTextField(
                      controller: _linkedinController,
                      label: 'LinkedIn Profile',
                      hintText: 'https://linkedin.com/in/username',
                      prefix: Icon(Icons.link_rounded,
                          size: 18, color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. ABOUT & BIO
              _buildSectionTitle('ABOUT & BIO'),
              const SizedBox(height: 8),
              BrlGlassCard(
                padding: const EdgeInsets.all(16),
                child: BrlTextField(
                  controller: _bioController,
                  label: 'Short Bio',
                  hintText:
                      'Describe your background, technical interests, or role in BRL...',
                  maxLines: 3,
                  prefix: Icon(Icons.notes_rounded,
                      size: 18, color: AppColors.textSecondaryOf(context)),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiaryOf(context),
        ),
      ),
    );
  }
}
