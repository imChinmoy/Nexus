import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/members_provider.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final UserEntity member;

  const MemberDetailsScreen({super.key, required this.member});

  @override
  ConsumerState<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  late UserEntity _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canEdit = currentUser?.isAdmin == true;
    final accent = AppColors.accentOf(context);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(
          title: 'Member Profile',
          showBack: true,
          actions: [
            if (canEdit)
              IconButton(
                icon: Icon(Icons.edit_outlined, color: accent, size: 20),
                onPressed: () => _showEditMemberDialog(context),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(context),
              const SizedBox(height: 16),
              Text(
                _member.name,
                style: AppTextStyles.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              NeonBadge(
                label: _member.role.displayName.toUpperCase(),
                type: _getRoleBadgeType(_member.role),
              ),
              const SizedBox(height: 24),
              _buildDetailsCard(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  NeonBadgeType _getRoleBadgeType(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return NeonBadgeType.warning;
      case UserRole.coordinator:
        return NeonBadgeType.info;
      case UserRole.volunteer:
        return NeonBadgeType.success;
      case UserRole.viewer:
        return NeonBadgeType.info;
    }
  }

  Widget _buildAvatar(BuildContext context) {
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _member.name.trim().isNotEmpty
        ? _member.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'M';

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Center(
        child: _member.avatar != null && _member.avatar!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(45),
                child: Image.network(_member.avatar!, width: 90, height: 90, fit: BoxFit.cover),
              )
            : Text(
                initials,
                style: AppTextStyles.headlineLg.copyWith(
                  color: accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_member.bio?.isNotEmpty == true) ...[
          _buildSectionHeader(context, 'ABOUT'),
          const SizedBox(height: 8),
          BrlGlassCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              _member.bio!,
              style: AppTextStyles.bodyMd.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],

        _buildSectionHeader(context, 'CONTACT INFORMATION'),
        const SizedBox(height: 8),
        BrlGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildInfoRow(context, Icons.email_outlined, 'Email', _member.email),
              if (_member.phone?.isNotEmpty == true) ...[
                Divider(color: AppColors.borderOf(context), height: 1),
                _buildInfoRow(context, Icons.phone_outlined, 'Phone', _member.phone!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_member.domain?.isNotEmpty == true || _member.year?.isNotEmpty == true) ...[
          _buildSectionHeader(context, 'ACADEMIC PROFILE'),
          const SizedBox(height: 8),
          BrlGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (_member.domain?.isNotEmpty == true)
                  _buildInfoRow(context, Icons.domain_outlined, 'Domain', _member.domain!),
                if (_member.domain?.isNotEmpty == true && _member.year?.isNotEmpty == true)
                  Divider(color: AppColors.borderOf(context), height: 1),
                if (_member.year?.isNotEmpty == true)
                  _buildInfoRow(context, Icons.school_outlined, 'Year', 'Year ${_member.year!}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (_member.github?.isNotEmpty == true || _member.linkedin?.isNotEmpty == true) ...[
          _buildSectionHeader(context, 'SOCIAL LINKS'),
          const SizedBox(height: 8),
          BrlGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (_member.github?.isNotEmpty == true)
                  _buildInfoRow(context, Icons.code_rounded, 'GitHub', _member.github!),
                if (_member.github?.isNotEmpty == true && _member.linkedin?.isNotEmpty == true)
                  Divider(color: AppColors.borderOf(context), height: 1),
                if (_member.linkedin?.isNotEmpty == true)
                  _buildInfoRow(context, Icons.open_in_new_rounded, 'LinkedIn', _member.linkedin!),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentOf(context), size: 18),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondaryOf(context))),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context) {
    final nameController = TextEditingController(text: _member.name);
    final emailController = TextEditingController(text: _member.email);
    final phoneController = TextEditingController(text: _member.phone ?? '');
    String? selectedDomain = _member.domain?.isNotEmpty == true ? _member.domain : null;
    final List<String> domainOptions = ['App Development', 'Frontend', 'Backend', 'Design', 'ML'];
    if (selectedDomain != null && !domainOptions.contains(selectedDomain)) {
      domainOptions.add(selectedDomain);
    }
    final yearController = TextEditingController(text: _member.year ?? '');
    final bioController = TextEditingController(text: _member.bio ?? '');
    final githubController = TextEditingController(text: _member.github ?? '');
    final linkedinController = TextEditingController(text: _member.linkedin ?? '');
    UserRole selectedRole = _member.role;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context).withValues(alpha: isDark ? 0.95 : 0.98),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.borderOf(context), width: 0.6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiaryOf(context).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Member Details', style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: AppColors.textSecondaryOf(context)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        BrlTextField(label: 'Name', controller: nameController),
                        const SizedBox(height: 12),
                        BrlTextField(label: 'Email', controller: emailController, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        BrlTextField(label: 'Phone', controller: phoneController, keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DOMAIN',
                              style: AppTextStyles.caption.copyWith(
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceOf(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderOf(context), width: 0.8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedDomain,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceOf(context),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('None', style: TextStyle(color: AppColors.textSecondaryOf(context))),
                                    ),
                                    ...domainOptions.map((domain) {
                                      return DropdownMenuItem<String>(
                                        value: domain,
                                        child: Text(domain, style: TextStyle(color: AppColors.textPrimaryOf(context))),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) {
                                    setSheetState(() => selectedDomain = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BrlTextField(label: 'Academic Year', controller: yearController),
                        const SizedBox(height: 12),
                        BrlTextField(label: 'GitHub URL', controller: githubController),
                        const SizedBox(height: 12),
                        BrlTextField(label: 'LinkedIn URL', controller: linkedinController),
                        const SizedBox(height: 12),
                        BrlTextField(label: 'Bio', controller: bioController, maxLines: 3),
                        const SizedBox(height: 12),
                        if (ref.read(currentUserProvider)?.isSuperAdmin == true) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ROLE',
                                style: AppTextStyles.caption.copyWith(
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceOf(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.borderOf(context), width: 0.8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<UserRole>(
                                    value: selectedRole,
                                    isExpanded: true,
                                    dropdownColor: AppColors.surfaceOf(context),
                                    items: UserRole.values.map((role) {
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(role.displayName, style: TextStyle(color: AppColors.textPrimaryOf(context))),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setSheetState(() => selectedRole = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrlButton(
                    label: 'Save Changes',
                    icon: Icons.check,
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Name and email are required'),
                            backgroundColor: AppColors.errorOf(context),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        return;
                      }
                      try {
                        final dio = ref.read(dioClientProvider);
                        final response = await dio.put('/members/${_member.id}', data: {
                          'name': nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                          'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                          'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          'domain': selectedDomain,
                          'year': yearController.text.trim().isEmpty ? null : yearController.text.trim(),
                          'github': githubController.text.trim().isEmpty ? null : githubController.text.trim(),
                          'linkedin': linkedinController.text.trim().isEmpty ? null : linkedinController.text.trim(),
                          'bio': bioController.text.trim().isEmpty ? null : bioController.text.trim(),
                          'role': selectedRole.backendValue,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ref.invalidate(membersProvider);

                          if (response.data != null && response.data['data'] != null) {
                            final updatedModel = UserModel.fromJson(response.data['data']);
                            setState(() {
                              _member = updatedModel.toEntity();
                            });
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Member updated successfully'),
                              backgroundColor: AppColors.successOf(context),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          String errMsg = 'Failed to update member';
                          if (e.toString().contains('403')) {
                            errMsg = 'Access Denied: You do not have permission to edit members';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errMsg),
                              backgroundColor: AppColors.errorOf(context),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
