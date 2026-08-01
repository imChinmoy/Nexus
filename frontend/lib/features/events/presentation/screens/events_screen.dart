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
                  _buildEventList(),
                  _buildEventList(),
                  _buildEventList(),
                  _buildEventList(),
                  _buildEventList(),
                ],
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
            onPressed: () => context.push(RouteConstants.createEvent),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => context.push('/events/event-$index'),
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
                            Text('Blockchain Hackathon', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                            const NeonBadge(label: 'UPCOMING', type: NeonBadgeType.info),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Aug 15 - Aug 16, 2026', style: AppTextStyles.bodySm),
                        const SizedBox(height: 4),
                        Text('Main Auditorium', style: AppTextStyles.bodySm),
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
  }
}
