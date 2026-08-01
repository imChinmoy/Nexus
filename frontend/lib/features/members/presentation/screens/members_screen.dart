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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.accentPink.withOpacity(0.4), blurRadius: 16),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white),
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
                return BrlGlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.moduleMembers.withOpacity(0.2),
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                          style: const TextStyle(color: AppColors.moduleMembers),
                        ),
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
                );
              },
            ),
    );
  }
}
