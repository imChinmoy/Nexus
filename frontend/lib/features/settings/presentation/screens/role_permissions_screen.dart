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

  final List<String> availablePermissions = [
    'all',
    'attendance:mark',
    'attendance:edit',
    'event:add',
    'event:edit',
    'member:add',
  ];

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
                padding: const EdgeInsets.all(16),
                itemCount: _rolePermissions.keys.length,
                itemBuilder: (context, index) {
                  final role = _rolePermissions.keys.elementAt(index);
                  final permissions = List<String>.from(_rolePermissions[role] ?? []);
                  
                  if (role == 'super_admin') return const SizedBox.shrink();

                  return BrlGlassCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.toUpperCase(),
                          style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availablePermissions.map((permission) {
                            final hasPermission = permissions.contains(permission);
                            return FilterChip(
                              label: Text(permission),
                              selected: hasPermission,
                              selectedColor: AppColors.primary.withValues(alpha: 0.3),
                              checkmarkColor: AppColors.primary,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    permissions.add(permission);
                                  } else {
                                    permissions.remove(permission);
                                  }
                                  _rolePermissions[role] = permissions;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isLoading ? null : _savePermissions,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.save, color: Colors.white),
        ),
      ),
    );
  }
}
