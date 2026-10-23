import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../providers/event_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['All', 'Upcoming', 'Ongoing', 'Completed', 'Archived'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Events',
        ),
        body: Column(
          children: [
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                unselectedLabelColor: textSecondary,
                labelStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w500),
                padding: const EdgeInsets.all(3),
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(null),
                  _buildEventList('upcoming'),
                  _buildEventList('ongoing'),
                  _buildEventList('completed'),
                  _buildEventList('archived'),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            final user = ref.watch(currentUserProvider);
            final isSuperAdmin = user?.isSuperAdmin ?? false;
            final permissions = ref.watch(myPermissionsProvider).value ?? [];
            final canAdd = isSuperAdmin || permissions.contains('event:add') || permissions.contains('all');

            if (!canAdd) return const SizedBox.shrink();

            return FloatingActionButton(
              onPressed: () => context.push(RouteConstants.createEvent),
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 24),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(String? statusFilter) {
    final eventsAsync = ref.watch(eventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return RefreshIndicator(
      color: accent,
      backgroundColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
      onRefresh: () async {
        ref.invalidate(eventsProvider);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, _) => Center(
          child: Text(
            'Error loading events: $error',
            style: AppTextStyles.bodyMd.copyWith(
              color: isDark ? AppColors.errorDark : AppColors.error,
            ),
          ),
        ),
        data: (events) {
          final filtered = statusFilter == null
              ? events
              : events.where((e) => e.status.toLowerCase() == statusFilter.toLowerCase()).toList();

          if (filtered.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note_outlined, size: 48, color: textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No Events Found',
                          style: AppTextStyles.headlineSm.copyWith(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = filtered[index];
              return _EventListItem(event: event);
            },
          );
        },
      ),
    );
  }
}

class _EventListItem extends StatelessWidget {
  final dynamic event;

  const _EventListItem({required this.event});

  NeonBadgeType _getStatusBadgeType(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return NeonBadgeType.success;
      case 'upcoming':
        return NeonBadgeType.warning;
      case 'completed':
        return NeonBadgeType.info;
      case 'cancelled':
      case 'archived':
        return NeonBadgeType.error;
      default:
        return NeonBadgeType.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BrlGlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/events/${event.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_outlined,
              color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeonBadge(
                      label: event.status.toUpperCase(),
                      type: _getStatusBadgeType(event.status),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${event.startDate.toString().split(' ').first} to ${event.endDate.toString().split(' ').first}',
                      style: AppTextStyles.caption.copyWith(color: textSecondary),
                    ),
                  ],
                ),
                if (event.venue != null && event.venue!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue!,
                          style: AppTextStyles.caption.copyWith(color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
