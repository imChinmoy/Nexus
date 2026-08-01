import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../core/network/dio_client.dart';

class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  ConsumerState<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen> {
  Map<String, dynamic> _rolePermissions = {};
  bool _isLoading = true;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load permissions: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePermissions() async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.put('/settings/role_permissions', data: {'value': _rolePermissions});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save permissions: $e')));
      }
    }
  }

  Widget _buildRoleCard(String role, List<String> permissions) {
    bool isAllSelected = permissions.contains('all') || _allPermissions.every((p) => permissions.contains(p));

    return BrlGlassCard(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.headlineSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Select All',
                    style: TextStyle(
                      color: isAllSelected ? AppColors.primary : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isAllSelected,
                    activeColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.white12,
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
          const Divider(color: Colors.white12, height: 32),
          ..._permissionCategories.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: AppTextStyles.labelLg.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: entry.value.map((permission) {
                      final hasPermission = isAllSelected || permissions.contains(permission);
                      return FilterChip(
                        label: Text(permission.split(':').last.toUpperCase()),
                        labelStyle: TextStyle(
                          color: hasPermission ? Colors.white : Colors.white54,
                          fontWeight: hasPermission ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        selected: hasPermission,
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(
                          color: hasPermission ? AppColors.primary : Colors.white12,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (selected) {
                          setState(() {
                            List<String> currentPerms = List<String>.from(permissions);
                            if (currentPerms.contains('all')) {
                              // If 'all' was selected, expand it to individual permissions so we can unselect one
                              currentPerms = List<String>.from(_allPermissions);
                            }
                            
                            if (selected) {
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
          title: 'ROLE PERMISSIONS',
          accentColor: AppColors.primary,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _rolePermissions.keys.length,
                itemBuilder: (context, index) {
                  final role = _rolePermissions.keys.elementAt(index);
                  if (role == 'super_admin') return const SizedBox.shrink();

                  final permissions = List<String>.from(_rolePermissions[role] ?? []);
                  return _buildRoleCard(role, permissions);
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _savePermissions,
          backgroundColor: AppColors.primary,
          elevation: 8,
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text('SAVE PERMISSIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
