import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../domain/entities/event_entity.dart';

class EventDeckCard extends StatelessWidget {
  final EventEntity event;
  final bool isActive;
  final int stackDepth;
  final VoidCallback? onTap;
  final VoidCallback? onScanAttendance;
  final VoidCallback? onEdit;
  final double width;
  final double height;

  const EventDeckCard({
    super.key,
    required this.event,
    this.isActive = true,
    this.stackDepth = 0,
    this.onTap,
    this.onScanAttendance,
    this.onEdit,
    required this.width,
    required this.height,
  });

  NeonBadgeType _getStatusBadgeType(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return NeonBadgeType.success;
      case 'upcoming':
        return NeonBadgeType.warning;
      case 'completed':
      case 'ended':
        return NeonBadgeType.info;
      case 'cancelled':
      case 'archived':
        return NeonBadgeType.error;
      default:
        return NeonBadgeType.neutral;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'workshop':
        return Icons.terminal_rounded;
      case 'hackathon':
        return Icons.code_rounded;
      case 'seminar':
        return Icons.co_present_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      case 'recruitment':
        return Icons.person_search_rounded;
      case 'social':
        return Icons.celebration_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  List<Color> _getFallbackGradient(String type, bool isDark) {
    switch (type.toLowerCase()) {
      case 'workshop':
        return isDark
            ? const [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF1D3557)]
            : const [Color(0xFF1D3557), Color(0xFF457B9D), Color(0xFFA8DADC)];
      case 'hackathon':
        return isDark
            ? const [Color(0xFF0F172A), Color(0xFF023E8A), Color(0xFF0077B6)]
            : const [Color(0xFF023E8A), Color(0xFF0077B6), Color(0xFF0096C7)];
      case 'seminar':
        return isDark
            ? const [Color(0xFF1E1035), Color(0xFF2C1654), Color(0xFF3F1D78)]
            : const [Color(0xFF3F1D78), Color(0xFF5A2A9D), Color(0xFF7B2CBF)];
      case 'meeting':
        return isDark
            ? const [Color(0xFF111827), Color(0xFF1F2937), Color(0xFF374151)]
            : const [Color(0xFF1F2937), Color(0xFF374151), Color(0xFF4B5563)];
      case 'recruitment':
        return isDark
            ? const [Color(0xFF0B2545), Color(0xFF134074), Color(0xFF1D4E89)]
            : const [Color(0xFF134074), Color(0xFF1D4E89), Color(0xFF2E6F95)];
      case 'social':
        return isDark
            ? const [Color(0xFF2B0938), Color(0xFF481261), Color(0xFF6B1D73)]
            : const [Color(0xFF481261), Color(0xFF6B1D73), Color(0xFF912F85)];
      default:
        return isDark
            ? const [Color(0xFF141418), Color(0xFF1E1E24), Color(0xFF282830)]
            : const [Color(0xFF1E1E24), Color(0xFF2E2E38), Color(0xFF3E3E4C)];
    }
  }

  String _formatEventSchedule(DateTime start, DateTime end) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final isSameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final isDateOnly =
        EventEntity.isDateOnly(start) && EventEntity.isDateOnly(end);

    if (isDateOnly) {
      if (isSameDay) {
        return dateFormat.format(start);
      } else {
        return '${DateFormat('MMM d').format(start)} – ${dateFormat.format(end)}';
      }
    } else {
      if (isSameDay) {
        return '${dateFormat.format(start)} • ${timeFormat.format(start)} – ${timeFormat.format(end)}';
      } else {
        return '${DateFormat('MMM d, h:mm a').format(start)} – ${DateFormat('MMM d, h:mm a').format(end)}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveStatus = event.effectiveStatus;
    final hasValidBanner =
        event.banner != null && event.banner!.trim().isNotEmpty;

    // Elevation shadows depending on stack depth
    final List<BoxShadow> shadows = switch (stackDepth) {
      0 => [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: isDark
                ? AppColors.darkAccent.withValues(alpha: 0.08)
                : AppColors.lightAccent.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      1 => [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      _ => [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
    };

    return Semantics(
      label:
          'Event: ${event.title}, Status: $effectiveStatus, Category: ${event.type}',
      button: isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isActive ? onTap : null,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Imagery / Deterministic Fallback
                if (hasValidBanner)
                  CachedNetworkImage(
                    imageUrl: event.banner!,
                    fit: BoxFit.cover,
                    memCacheWidth: (width * 1.8).round().clamp(300, 1200),
                    memCacheHeight: (height * 1.8).round().clamp(400, 1600),
                    placeholder: (context, url) =>
                        _buildFallbackBanner(context, isDark),
                    errorWidget: (context, url, error) =>
                        _buildFallbackBanner(context, isDark),
                  )
                else
                  _buildFallbackBanner(context, isDark),

                // 2. High-Tech Glass & Shadow Vignettes for Maximum Readability
                // Top vignette
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 110,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.70),
                          Colors.black.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Bottom deep cinematic gradient scrim
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: height * 0.68,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.40),
                          Colors.black.withValues(alpha: 0.82),
                          Colors.black.withValues(alpha: 0.96),
                        ],
                        stops: const [0.0, 0.35, 0.70, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Subtle Atmospheric Dimming Overlay for Background Stack Cards
                if (stackDepth > 0)
                  Container(
                    color: Colors.black
                        .withValues(alpha: stackDepth == 1 ? 0.25 : 0.45),
                  ),

                // 4. Fine Metallic/Glass Perimeter Border
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: isDark ? 0.14 : 0.18),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),

                // 5. Card Foreground Content (Header, Meta, and Action Bar)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Row: Status, Event Type Pill, Attendance Status ---
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          NeonBadge(
                            label: effectiveStatus.toUpperCase(),
                            type: _getStatusBadgeType(effectiveStatus),
                          ),
                          // Type Pill with Icon
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getEventTypeIcon(event.type),
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.type.toUpperCase(),
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: Colors.white.withValues(alpha: 0.90),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Live Attendance Indicator
                          if (event.isAttendanceOpen && !event.isPast)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successDark
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.successDark
                                      .withValues(alpha: 0.45),
                                  width: 0.6,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.successDark,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'ATTENDANCE OPEN',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.successDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const Spacer(),

                      // --- Title and Description ---
                      Text(
                        event.title,
                        style: AppTextStyles.headlineMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.description != null &&
                          event.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description!.trim(),
                          style: AppTextStyles.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // --- Metadata Row: Date & Schedule ---
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatEventSchedule(
                                  event.startDate, event.endDate),
                              style: AppTextStyles.bodySm.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // --- Metadata Row: Venue & Capacity ---
                      if (event.venue != null &&
                          event.venue!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.venue!.trim(),
                                style: AppTextStyles.bodySm.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (event.capacity > 0) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.people_alt_outlined,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.capacity} seats',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // --- Bottom Action Controls ---
                      if (isActive)
                        Row(
                          children: [
                            // Primary View Details Button
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: onTap,
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.22),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Explore Event',
                                            style:
                                                AppTextStyles.bodySm.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Attendance Scan Button (if open)
                            if (event.isAttendanceOpen &&
                                !event.isPast &&
                                onScanAttendance != null) ...[
                              const SizedBox(width: 10),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: onScanAttendance,
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: AppColors.successDark,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.successDark
                                              .withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.qr_code_scanner_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Scan',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Quick Edit Button for Admins
                            if (onEdit != null) ...[
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: onEdit,
                                  child: Ink(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.18),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(BuildContext context, bool isDark) {
    final gradientColors = _getFallbackGradient(event.type, isDark);
    final icon = _getEventTypeIcon(event.type);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient decorative circles
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: 40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Central thematic watermark
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 38,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.type.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
