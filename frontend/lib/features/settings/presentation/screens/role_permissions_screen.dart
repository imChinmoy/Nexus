import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';

class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  ConsumerState<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen> {
  Map<String, dynamic> _rolePermissions = {};
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, List<String>> _permissionCategories = {
    'Attendance': ['attendance:mark', 'attendance:edit'],
    'Events': ['event:add', 'event:edit', 'event:delete'],
    'Members': ['member:add', 'member:edit', 'member:delete'],
  };

  List<String> get _allPermissions {
    return _permissionCategories.values.expand((e) => e).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchPermissions();
  }

  Future<void> _fetchPermissions() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/settings/role-permissions');
      if (response.statusCode == 200) {
        setState(() {
          _rolePermissions = response.data['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load permissions: $e'),
            backgroundColor: AppColors.errorOf(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.put('/settings/role_permissions', data: {'value': _rolePermissions});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissions saved successfully'),
            backgroundColor: AppColors.successOf(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save permissions: $e'),
            backgroundColor: AppColors.errorOf(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildRoleCard(String role, List<String> permissions) {
    final isAllSelected = permissions.contains('all') || _allPermissions.every((p) => permissions.contains(p));
    final accent = AppColors.accentOf(context);

    return BrlGlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Full Access',
                    style: AppTextStyles.caption.copyWith(
                      color: isAllSelected ? accent : AppColors.textSecondaryOf(context),
                      fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isAllSelected,
                    activeThumbColor: accent,
                    activeTrackColor: accent.withValues(alpha: 0.5),
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          _rolePermissions[role] = ['all', ..._allPermissions];
                        } else {
                          _rolePermissions[role] = <String>[];
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          Divider(color: AppColors.borderOf(context), height: 24),
          ..._permissionCategories.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((permission) {
                      final hasPermission = isAllSelected || permissions.contains(permission);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            List<String> currentPerms = List<String>.from(permissions);
                            if (currentPerms.contains('all')) {
                              currentPerms = List<String>.from(_allPermissions);
                            }

                            if (!hasPermission) {
                              currentPerms.add(permission);
                              if (_allPermissions.every((p) => currentPerms.contains(p))) {
                                currentPerms.add('all');
                              }
                            } else {
                              currentPerms.remove(permission);
                              currentPerms.remove('all');
                            }
                            _rolePermissions[role] = currentPerms.toSet().toList();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: hasPermission
                                ? accent.withValues(alpha: 0.14)
                                : AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasPermission ? accent : AppColors.borderOf(context),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasPermission ? Icons.check_circle : Icons.circle_outlined,
                                size: 14,
                                color: hasPermission ? accent : AppColors.textTertiaryOf(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                permission.split(':').last.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  color: hasPermission
                                      ? accent
                                      : AppColors.textSecondaryOf(context),
                                  fontWeight: hasPermission ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Role Permissions',
          showBack: true,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.accentOf(context), strokeWidth: 2.5))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  ..._rolePermissions.keys.where((role) => role != 'super_admin').map((role) {
                    final permissions = List<String>.from(_rolePermissions[role] ?? []);
                    return _buildRoleCard(role, permissions);
                  }),
                  const SizedBox(height: 16),
                  BrlButton(
                    label: 'Save Role Permissions',
                    icon: Icons.check,
                    isLoading: _isSaving,
                    onPressed: _savePermissions,
                  ),
                ],
              ),
      ),
    );
  }
}
