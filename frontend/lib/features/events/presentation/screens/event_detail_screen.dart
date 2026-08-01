import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../providers/event_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final user = ref.watch(currentUserProvider);
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final permissionsAsync = ref.watch(myPermissionsProvider);
    final permissions = permissionsAsync.value ?? [];
    final hasEventEdit = isSuperAdmin || permissions.contains('event:edit') || permissions.contains('all');

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.moduleEvents)),
          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
          data: (events) {
            final event = events.firstWhere(
              (e) => e.id == eventId,
              orElse: () => throw Exception('Event not found'),
            );

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: AppColors.background.withOpacity(0.9),
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    if (hasEventEdit)
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.moduleEvents),
                        onPressed: () {
                          context.push('${RouteConstants.events}/${event.id}/edit', extra: event);
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (event.banner != null && event.banner!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: event.banner!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surface,
                              child: const Center(child: CircularProgressIndicator(color: AppColors.moduleEvents)),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholderBanner(),
                          )
                        else
                          _buildPlaceholderBanner(),
                        // Gradient Overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background.withOpacity(0.8),
                                AppColors.background,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      event.title,
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            NeonBadge(label: event.status.toUpperCase(), type: _getStatusType(event.status)),
                            const SizedBox(width: 8),
                            NeonBadge(label: event.type.toUpperCase(), type: NeonBadgeType.info),
                          ],
                        ),
                        const SizedBox(height: 24),
                        BrlGlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.calendar_today, 'Dates', '${event.startDate.toString().split(' ')[0]} to ${event.endDate.toString().split(' ')[0]}'),
                              const Divider(color: Colors.white24, height: 24),
                              _buildInfoRow(Icons.location_on, 'Venue', event.venue?.isNotEmpty == true ? event.venue! : 'TBA'),
                              const Divider(color: Colors.white24, height: 24),
                              _buildInfoRow(Icons.people, 'Capacity', event.capacity > 0 ? event.capacity.toString() : 'Unlimited'),
                              const Divider(color: Colors.white24, height: 24),
                              _buildInfoRow(Icons.qr_code_scanner, 'Attendance', event.isAttendanceOpen ? 'Open Now' : 'Closed'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('About this Event', style: AppTextStyles.headlineMd),
                        const SizedBox(height: 12),
                        Text(
                          event.description?.isNotEmpty == true ? event.description! : 'No description provided for this event.',
                          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted, height: 1.5),
                        ),
                        const SizedBox(height: 48), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: const Center(
        child: Icon(Icons.event, size: 64, color: Colors.white54),
      ),
    );
  }

  NeonBadgeType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming': return NeonBadgeType.warning;
      case 'ongoing': return NeonBadgeType.success;
      case 'completed': return NeonBadgeType.info;
      case 'cancelled': return NeonBadgeType.error;
      default: return NeonBadgeType.info;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.moduleEvents, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
