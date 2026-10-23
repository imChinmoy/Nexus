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
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/members_provider.dart';
import 'member_details_screen.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All', 'Executive', 'Core Team', 'Volunteers'];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canAddMember = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin;
    final accent = AppColors.accentOf(context);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(
          title: 'Society Team',
          actions: [
            if (canAddMember)
              IconButton(
                icon: Icon(Icons.person_add_outlined, color: accent, size: 22),
                onPressed: () => _showAddMemberDialog(context),
              ),
          ],
        ),
        body: Column(
          children: [
            _buildTabSelector(context),
            Expanded(
              child: ref.watch(membersProvider).when(
                    data: (members) {
                      final filtered = _getFilteredMembers(members);
                      return RefreshIndicator(
                        color: accent,
                        backgroundColor: AppColors.surfaceOf(context),
                        onRefresh: () async {
                          ref.invalidate(membersProvider);
                          await Future.delayed(const Duration(milliseconds: 600));
                        },
                        child: filtered.isEmpty
                            ? const EmptyStateWidget(
                                icon: Icons.group_outlined,
                                title: 'No Members in this Group',
                                message: 'There are no active society members matching this role.',
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final member = filtered[index];
                                  return _buildMemberCard(context, member);
                                },
                              ),
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(color: accent, strokeWidth: 2.5),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 44, color: AppColors.errorOf(context)),
                            const SizedBox(height: 12),
                            Text('Unable to load team members', style: AppTextStyles.headlineSm),
                            const SizedBox(height: 6),
                            Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<UserEntity> _getFilteredMembers(List<UserEntity> members) {
    switch (_selectedTabIndex) {
      case 1:
        return members.where((m) => m.role == UserRole.superAdmin || m.role == UserRole.admin).toList();
      case 2:
        return members.where((m) => m.role == UserRole.coordinator).toList();
      case 3:
        return members.where((m) => m.role == UserRole.volunteer).toList();
      default:
        return members;
    }
  }

  Widget _buildTabSelector(BuildContext context) {
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedTabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent
                    : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? accent : AppColors.borderOf(context),
                  width: 0.6,
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[i],
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, UserEntity member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);
    final initials = member.name.trim().isNotEmpty
        ? member.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'M';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberDetailsScreen(member: member),
          ),
        );
      },
      child: BrlGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: ClipOval(
                child: member.avatar != null && member.avatar!.isNotEmpty
                    ? Image.network(
                        member.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            initials,
                            style: AppTextStyles.labelMd.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.labelMd.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    member.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            NeonBadge(
              label: member.role.displayName.toUpperCase(),
              type: _getRoleBadgeType(member.role),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiaryOf(context)),
          ],
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

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.volunteer;
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                      Text('Add Team Member', style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: AppColors.textSecondaryOf(context)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BrlTextField(
                    label: 'Full Name',
                    controller: nameController,
                    hintText: 'e.g., Alex Johnson',
                  ),
                  const SizedBox(height: 12),
                  BrlTextField(
                    label: 'Email Address',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'alex@society.org',
                  ),
                  const SizedBox(height: 12),
                  BrlTextField(
                    label: 'Temporary Password',
                    controller: passwordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGNED ROLE',
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
                                child: Text(
                                  role.displayName,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.textPrimaryOf(context),
                                  ),
                                ),
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
                  const SizedBox(height: 24),
                  BrlButton(
                    label: 'Add Member',
                    icon: Icons.check,
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty ||
                          emailController.text.trim().isEmpty ||
                          passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please fill all required fields'),
                            backgroundColor: AppColors.errorOf(context),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        return;
                      }
                      try {
                        final dio = ref.read(dioClientProvider);
                        await dio.post('/members', data: {
                          'name': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'password': passwordController.text.trim(),
                          'role': selectedRole.name,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ref.invalidate(membersProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Member added successfully'),
                              backgroundColor: AppColors.successOf(context),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add member: $e'),
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
