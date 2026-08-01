import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          title: 'EVENTS',
          accentColor: AppColors.moduleEvents,
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.moduleEvents,
              labelColor: AppColors.moduleEvents,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'UPCOMING'),
                Tab(text: 'ONGOING'),
                Tab(text: 'COMPLETED'),
                Tab(text: 'ARCHIVED'),
              ],
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
            final permissionsAsync = ref.watch(myPermissionsProvider);
            return permissionsAsync.when(
              data: (permissions) {
                if (!permissions.contains('event:add') && !permissions.contains('all')) {
                  return const SizedBox.shrink();
                }
                return Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.accentPink.withValues(alpha: 0.4), blurRadius: 16),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () => context.push(RouteConstants.createEvent),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(String? statusFilter) {
    final eventsAsyncValue = ref.watch(eventsProvider);

    return RefreshIndicator(
      color: AppColors.moduleEvents,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(eventsProvider);
        await Future.delayed(const Duration(seconds: 1));
      },
      child: eventsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.moduleEvents)),
        error: (error, _) => Center(
          child: Text(
            'Error loading events: $error',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
          ),
        ),
        data: (events) {
          final filteredEvents = statusFilter == null
              ? events
              : events.where((e) => e.status.toLowerCase() == statusFilter.toLowerCase()).toList();

          if (filteredEvents.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Text(
                      'No Events Found',
                      style: TextStyle(color: AppColors.onSurfaceMuted),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              return GestureDetector(
                onTap: () => context.push('/events/${event.id}'),
                child: BrlGlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.accentPink,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(event.title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 8),
                                  NeonBadge(label: event.status.toUpperCase(), type: NeonBadgeType.info),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${event.startDate.toString().split(' ')[0]} - ${event.endDate.toString().split(' ')[0]}', style: AppTextStyles.bodySm),
                              const SizedBox(height: 4),
                              Text(event.type.toUpperCase(), style: AppTextStyles.bodySm),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
