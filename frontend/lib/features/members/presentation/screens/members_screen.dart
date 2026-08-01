import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../providers/members_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/network/dio_client.dart';
import 'member_details_screen.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'MEMBERS',
          accentColor: AppColors.moduleMembers,
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.moduleMembers,
              labelColor: AppColors.moduleMembers,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'EXECUTIVE COMMITTEE'),
                Tab(text: 'CORE TEAM'),
                Tab(text: 'VOLUNTEERS'),
              ],
            ),
            Expanded(
              child: ref.watch(membersProvider).when(
                data: (members) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMembersList(members),
                      _buildMembersList(members.where((m) => m.role == UserRole.superAdmin || m.role == UserRole.admin).toList()),
                      _buildMembersList(members.where((m) => m.role == UserRole.coordinator).toList()),
                      _buildMembersList(members.where((m) => m.role == UserRole.volunteer).toList()),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.moduleMembers)),
                error: (error, stack) => Center(
                  child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: ref.watch(currentUserProvider)?.role == UserRole.admin || ref.watch(currentUserProvider)?.role == UserRole.superAdmin ? Container(
          decoration: BoxDecoration(
            gradient: AppGradients.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.accentPink.withOpacity(0.4), blurRadius: 16),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _showAddMemberDialog(context),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        ) : null,
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.volunteer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Member', style: AppTextStyles.headlineSm.copyWith(color: AppColors.moduleMembers)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.moduleMembers), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.moduleMembers), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.moduleMembers), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.moduleMembers), borderRadius: BorderRadius.circular(12)),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.moduleMembers,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    try {
                      final dio = ref.read(dioClientProvider);
                      await dio.post('/members', data: {
                        'name': nameController.text,
                        'email': emailController.text,
                        'password': passwordController.text,
                        'role': selectedRole.name,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ref.invalidate(membersProvider);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add member: $e')));
                      }
                    }
                  },
                  child: const Text('ADD MEMBER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList(List<UserEntity> members) {
    return RefreshIndicator(
      color: AppColors.moduleMembers,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(membersProvider);
      },
      child: members.isEmpty
          ? const Center(child: Text('No members found', style: TextStyle(color: AppColors.onSurfaceMuted)))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
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
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.moduleMembers.withOpacity(0.2),
                          backgroundImage: member.avatar != null && member.avatar!.isNotEmpty
                              ? NetworkImage(member.avatar!)
                              : null,
                          child: member.avatar == null || member.avatar!.isEmpty
                              ? Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                                  style: const TextStyle(color: AppColors.moduleMembers),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              NeonBadge(label: member.role.displayName.toUpperCase(), type: NeonBadgeType.info),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
