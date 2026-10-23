import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/event_provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: eventsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.accentOf(context)),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.errorOf(context)),
                const SizedBox(height: 12),
                Text('Failed to load event', style: AppTextStyles.headlineSm),
                const SizedBox(height: 6),
                Text(err.toString(), style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondaryOf(context))),
              ],
            ),
          ),
          data: (events) {
            final event = events.firstWhere(
              (e) => e.id == eventId,
              orElse: () => throw Exception('Event not found'),
            );

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.surfaceOf(context).withValues(alpha: 0.85),
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (hasEventEdit)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                                onPressed: () {
                                  context.push('${RouteConstants.events}/${event.id}/edit', extra: event);
                                },
                              ),
                            ),
                          ),
                        ),
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
                              color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.accentOf(context), strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholderBanner(context),
                          )
                        else
                          _buildPlaceholderBanner(context),
                        // Gradient Overlay for smooth transition
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                isDark
                                    ? const Color(0xFF111114).withValues(alpha: 0.95)
                                    : const Color(0xFFF5F5F7).withValues(alpha: 0.95),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & Type row
                        Row(
                          children: [
                            NeonBadge(
                              label: event.status.toUpperCase(),
                              type: _getStatusType(event.status),
                            ),
                            const SizedBox(width: 8),
                            NeonBadge(
                              label: event.type.toUpperCase(),
                              type: NeonBadgeType.info,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: event.isAttendanceOpen
                                    ? AppColors.successOf(context).withValues(alpha: 0.12)
                                    : AppColors.textTertiaryOf(context).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: event.isAttendanceOpen
                                          ? AppColors.successOf(context)
                                          : AppColors.textTertiaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    event.isAttendanceOpen ? 'Attendance Open' : 'Attendance Closed',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: event.isAttendanceOpen
                                          ? AppColors.successOf(context)
                                          : AppColors.textSecondaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Event Title
                        Text(
                          event.title,
                          style: AppTextStyles.headlineLg.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons: Scan QR and Manual
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: BrlButton(
                                label: 'Scan QR Attendance',
                                icon: Icons.qr_code_scanner,
                                onPressed: () {
                                  context.push('${RouteConstants.attendance}/qr-scan?eventId=${event.id}');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: BrlButton(
                                label: 'Manual',
                                variant: BrlButtonVariant.secondary,
                                icon: Icons.edit_note_rounded,
                                onPressed: () {
                                  context.push('${RouteConstants.attendance}/manual?eventId=${event.id}');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Event Meta Group
                        _buildSectionHeader(context, 'EVENT OVERVIEW'),
                        const SizedBox(height: 8),
                        BrlGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              _buildMetaRow(
                                context,
                                icon: Icons.calendar_today_rounded,
                                label: 'Dates',
                                value: '${_formatDate(event.startDate)} – ${_formatDate(event.endDate)}',
                              ),
                              Divider(color: AppColors.borderOf(context), height: 1),
                              _buildMetaRow(
                                context,
                                icon: Icons.location_on_outlined,
                                label: 'Venue',
                                value: event.venue?.isNotEmpty == true ? event.venue! : 'To Be Announced',
                              ),
                              Divider(color: AppColors.borderOf(context), height: 1),
                              _buildMetaRow(
                                context,
                                icon: Icons.groups_outlined,
                                label: 'Capacity',
                                value: event.capacity > 0 ? '${event.capacity} Attendees' : 'Unlimited Capacity',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description Section
                        _buildSectionHeader(context, 'ABOUT THIS EVENT'),
                        const SizedBox(height: 8),
                        BrlGlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            event.description?.isNotEmpty == true
                                ? event.description!
                                : 'No description provided for this event.',
                            style: AppTextStyles.bodyMd.copyWith(
                              height: 1.6,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiaryOf(context),
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentOf(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.accentOf(context)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 64,
          color: AppColors.textTertiaryOf(context),
        ),
      ),
    );
  }

  NeonBadgeType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return NeonBadgeType.warning;
      case 'ongoing':
        return NeonBadgeType.success;
      case 'completed':
        return NeonBadgeType.info;
      case 'cancelled':
        return NeonBadgeType.error;
      default:
        return NeonBadgeType.info;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
