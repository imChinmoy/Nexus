import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/providers/student_provider.dart';
import '../../../analytics/presentation/widgets/society_activity_heatmap_card.dart';
import '../../../analytics/providers/analytics_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final eventsAsync = ref.watch(eventsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: accent,
          backgroundColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(eventsProvider);
            ref.invalidate(studentsProvider);
            ref.invalidate(eventScopedStudentsFamilyProvider);
            ref.invalidate(activityHeatmapProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // 1. Minimal Header
              SliverToBoxAdapter(
                child: _buildMinimalHeader(context, user, isDark),
              ),

              // Events & Operations Stream
              eventsAsync.when(
                data: (events) {
                  final featuredEvent = _resolveFeaturedEvent(events);
                  final otherEvents = events.where((e) => e.id != featuredEvent?.id).toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // 2. Featured Event Hero Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                        child: _buildFeaturedEventCard(
                          context,
                          featuredEvent,
                          isDark,
                          isAdmin: user?.isAdmin ?? false,
                        ),
                      ),

                      // 3. Attendance Overview (Single Compact Horizontal Statistics Section)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildAttendanceOverview(context, featuredEvent, isDark),
                      ),

                      // 4. Recent Activity (Connected Timeline, hidden if no activity)
                      _buildRecentActivityTimeline(context, featuredEvent, isDark),

                      // 5. Upcoming Events (Image-Led Horizontal Carousel)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _buildUpcomingEventsCarousel(context, otherEvents, isDark),
                      ),
                    ]),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: _buildSkeletonLoading(isDark),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: _buildErrorState(context, error.toString(), isDark),
                ),
              ),

              // 6. Annual Society Activity Heatmap
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 36),
                  child: SocietyActivityHeatmapCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. MINIMAL HEADER
  // ---------------------------------------------------------------------------
  Widget _buildMinimalHeader(BuildContext context, dynamic user, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final displayName = user?.name.split(' ').first ?? 'Operator';
    final currentDateFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Nexus brand mark
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.16 : 0.09),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hub_rounded, size: 11, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            'NEXUS • OPS',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$greeting, $displayName',
                  style: GoogleFonts.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentDateFormatted,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),

          // Notification icon & Profile avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification icon button with subtle unread indicator
              Semantics(
                label: 'Notifications',
                button: true,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(RouteConstants.notifications);
                  },
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 19,
                          color: textPrimary,
                        ),
                        Positioned(
                          top: 9,
                          right: 9,
                          child: Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Settings icon button
              Semantics(
                label: 'Settings',
                button: true,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(RouteConstants.settings);
                  },
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Profile Avatar
              Semantics(
                label: 'Profile Settings',
                button: true,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(RouteConstants.profile);
                  },
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.45 : 0.28),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FEATURED EVENT (HERO WIDE CARD)
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedEventCard(
    BuildContext context,
    EventEntity? event,
    bool isDark, {
    bool isAdmin = false,
  }) {
    if (event == null) {
      return _buildEmptyFeaturedCard(context, isDark);
    }

    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final dateFormatted = DateFormat('EEE, MMM d • h:mm a').format(event.startDate);

    return Semantics(
      label: 'Featured Event: ${event.title}',
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: (event.isAttendanceOpen && !event.isPast)
                ? successColor.withValues(alpha: isDark ? 0.45 : 0.6)
                : (isDark ? const Color(0x2EFFFFFF) : const Color(0x18000000)),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (event.isAttendanceOpen && !event.isPast)
                  ? successColor.withValues(alpha: isDark ? 0.16 : 0.10)
                  : Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full-Bleed Artwork Viewport
              if (event.banner != null && event.banner!.trim().isNotEmpty)
                CachedNetworkImage(
                  imageUrl: event.banner!.trim(),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildBannerFallback(isDark),
                  errorWidget: (_, __, ___) => _buildBannerFallback(isDark),
                )
              else
                _buildBannerFallback(isDark),

              // 2. High-Tech Scrim Gradients (Top beacon contrast & bottom dock fade)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),

              // 3. Card Tap Surface (Navigates to Event Details)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('${RouteConstants.events}/${event.id}');
                  },
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.white.withValues(alpha: 0.04),
                  child: const SizedBox.expand(),
                ),
              ),

              // 4. Top Operational Beacon Strip
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Status Radar Beacon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xE6080B11),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (event.isAttendanceOpen && !event.isPast)
                              ? successColor.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.25),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: (event.isAttendanceOpen && !event.isPast) ? successColor : Colors.white70,
                              shape: BoxShape.circle,
                              boxShadow: (event.isAttendanceOpen && !event.isPast)
                                  ? [
                                      BoxShadow(
                                        color: successColor.withValues(alpha: 0.8),
                                        blurRadius: 7,
                                        spreadRadius: 1.5,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (event.isAttendanceOpen && !event.isPast)
                                ? 'LIVE CHECK-IN OPEN'
                                : event.effectiveStatus.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: (event.isAttendanceOpen && !event.isPast) ? successColor : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Actions: Type Tag & Admin Quick Toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Type Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xE6080B11),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            event.type.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Admin Quick Toggle
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: (event.isAttendanceOpen && !event.isPast)
                                  ? successColor.withValues(alpha: 0.22)
                                  : const Color(0xE6080B11),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (event.isAttendanceOpen && !event.isPast)
                                    ? successColor.withValues(alpha: 0.8)
                                    : Colors.white24,
                                width: 0.8,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                final nextState = !(event.isAttendanceOpen && !event.isPast);
                                final result = await ref
                                    .read(eventRepositoryProvider)
                                    .toggleAttendance(event.id, nextState);
                                result.fold(
                                  (failure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(failure.message),
                                        backgroundColor: AppColors.errorOf(context),
                                      ),
                                    );
                                  },
                                  (_) {
                                    ref.invalidate(eventsProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          nextState
                                              ? 'Attendance check-in opened'
                                              : 'Attendance check-in closed',
                                        ),
                                        backgroundColor: nextState
                                            ? successColor
                                            : AppColors.surfaceOf(context),
                                        duration: const Duration(milliseconds: 1500),
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: Icon(
                                (event.isAttendanceOpen && !event.isPast)
                                    ? Icons.how_to_reg_rounded
                                    : Icons.person_off_outlined,
                                size: 14,
                                color: (event.isAttendanceOpen && !event.isPast)
                                    ? successColor
                                    : Colors.white70,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: (event.isAttendanceOpen && !event.isPast)
                                  ? 'Close Attendance'
                                  : 'Open Attendance',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Floating Cyber HUD Command Dock (Compact micro-dock)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xD90B0E17)
                            : Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (event.isAttendanceOpen && !event.isPast)
                              ? successColor.withValues(alpha: 0.45)
                              : (isDark ? Colors.white12 : Colors.black12),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Title (Crisp, compact)
                          Text(
                            event.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),

                          // Compact Info & Action Strip
                          Row(
                            children: [
                              // Date & Venue Details
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 11,
                                      color: (event.isAttendanceOpen && !event.isPast)
                                          ? successColor
                                          : (isDark ? Colors.white60 : AppColors.lightTextSecondary),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        dateFormatted,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (event.venue != null && event.venue!.isNotEmpty) ...[
                                      const SizedBox(width: 5),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          color: isDark ? Colors.white30 : Colors.black26,
                                          fontSize: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        Icons.place_outlined,
                                        size: 11,
                                        color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          event.venue!,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Glowing "Scan QR Pass" Cyber Action Pill
                              ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  context.push('${RouteConstants.attendance}/qr-scan?eventId=${event.id}');
                                },
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 13.5),
                                label: Text(
                                  'Scan QR Pass',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (event.isAttendanceOpen && !event.isPast)
                                      ? successColor
                                      : accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerFallback(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E222D), const Color(0xFF13151B)]
              : [const Color(0xFF1D283A), const Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_seat_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _buildEmptyFeaturedCard(BuildContext context, bool isDark) {
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 36, color: textSecondary),
          const SizedBox(height: 10),
          Text(
            'No Active or Scheduled Events',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Events will appear here once configured',
            style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ATTENDANCE OVERVIEW (COMPACT HORIZONTAL STATISTICS SECTION)
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceOverview(BuildContext context, EventEntity? featuredEvent, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);

    // Dynamic metrics retrieval
    final allStudentsAsync = ref.watch(studentsProvider);
    final eventScopedAsync = featuredEvent != null
        ? ref.watch(eventScopedStudentsFamilyProvider(featuredEvent.id))
        : null;

    int totalRegistered = 0;
    int presentCount = 0;

    if (eventScopedAsync != null && eventScopedAsync.hasValue && eventScopedAsync.value != null) {
      totalRegistered = eventScopedAsync.value!.counts.total;
      presentCount = eventScopedAsync.value!.counts.present;
    } else if (featuredEvent == null && allStudentsAsync.hasValue && allStudentsAsync.value != null) {
      final students = allStudentsAsync.value!;
      totalRegistered = students.length;
      presentCount = students.where((s) => s.isPresent).length;
    }

    final double progress = totalRegistered > 0
        ? (presentCount / totalRegistered).clamp(0.0, 1.0)
        : 0.0;
    final int percentage = (progress * 100).round();
    final int remaining = totalRegistered >= presentCount ? (totalRegistered - presentCount) : 0;

    return Semantics(
      label: 'Attendance Operations Overview',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header: Title & Event Scope / Manage Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'ATTENDANCE OPERATIONS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (featuredEvent != null) {
                      ref.read(selectedEventIdProvider.notifier).state = featuredEvent.id;
                    }
                    context.push(RouteConstants.students);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          featuredEvent != null ? 'Event Scope' : 'All Students',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 14, color: accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Statistics Strip (Replaces separate metric cards)
            Row(
              children: [
                // 1. Present / Checked In
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: successColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Present',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical hairline divider
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
                ),

                // 2. Total Registered
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalRegistered.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Registered',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Vertical hairline divider
                Container(
                  width: 1,
                  height: 32,
                  color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
                ),

                // 3. Attendance Rate / Remaining
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$percentage%',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: accent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$remaining remaining',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Continuous Horizontal Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: isDark
                          ? const Color(0xFF26262B)
                          : const Color(0xFFE5E5EA),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        value >= 1.0 ? successColor : accent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. RECENT ACTIVITY (COMPACT CONNECTED TIMELINE)
  // ---------------------------------------------------------------------------
  Widget _buildRecentActivityTimeline(BuildContext context, EventEntity? featuredEvent, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);

    // Retrieve recent students (scoped to featured event if available, otherwise general)
    final allStudents = ref.watch(studentsProvider).value ?? [];
    final scopedStudents = featuredEvent != null
        ? (ref.watch(eventScopedStudentsFamilyProvider(featuredEvent.id)).value?.students ?? [])
        : <StudentEntity>[];

    final candidatePool = scopedStudents.isNotEmpty ? scopedStudents : allStudents;
    final presentStudents = candidatePool.where((s) => s.isPresent).toList();

    // Sort by most recently marked/updated
    presentStudents.sort((a, b) {
      final aDate = a.markedAt ?? a.updatedAt;
      final bDate = b.markedAt ?? b.updatedAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    final recentCheckIns = presentStudents.take(4).toList();

    // If no recent activity exists, hide the entire section completely
    if (recentCheckIns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ACTIVITY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(RouteConstants.recentAttendance);
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Single Continuous Timeline Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentCheckIns.length,
              itemBuilder: (context, index) {
                final student = recentCheckIns[index];
                final isLast = index == recentCheckIns.length - 1;
                return _buildTimelineRow(
                  context,
                  student: student,
                  isLast: isLast,
                  isDark: isDark,
                  accent: accent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context, {
    required StudentEntity student,
    required bool isLast,
    required bool isDark,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final timeDate = student.markedAt ?? student.updatedAt ?? DateTime.now();
    final timeStr = DateFormat('h:mm a').format(timeDate);

    // Initial letters for avatar
    final initial = student.name.trim().isNotEmpty
        ? student.name.trim()[0].toUpperCase()
        : 'S';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('${RouteConstants.students}/${student.id}');
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Node + Vertical Hairline Guide
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.40 : 0.25),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 1.5,
                          color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Middle: Name & Roll / Branch
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${student.rollNumber} • ${student.branch}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Right: Result Pill & Timestamp
            Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: successColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // 5. UPCOMING EVENTS (IMAGE-LED HORIZONTAL CAROUSEL)
  // ---------------------------------------------------------------------------
  Widget _buildUpcomingEventsCarousel(BuildContext context, List<EventEntity> events, bool isDark) {
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    // Filter upcoming or ongoing events
    final upcomingList = events
        .where((e) => e.status == 'upcoming' || e.status == 'ongoing')
        .toList();
    upcomingList.sort((a, b) => a.startDate.compareTo(b.startDate));
    final displayEvents = upcomingList.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'UPCOMING SCHEDULE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                if (displayEvents.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      displayEvents.length.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(RouteConstants.events);
              },
              child: Text(
                'See All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Carousel Container
        SizedBox(
          height: 172,
          child: displayEvents.isEmpty
              ? _buildEmptyEventsCarousel(isDark, textSecondary)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final event = displayEvents[index];
                    return _buildCarouselCard(context, event, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(BuildContext context, EventEntity event, bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final dateMonthDay = DateFormat('MMM d').format(event.startDate).toUpperCase();
    final timeStr = DateFormat('h:mm a').format(event.startDate);

    return Semantics(
      label: 'Event: ${event.title}',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('${RouteConstants.events}/${event.id}');
        },
        child: Container(
          width: 215,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Section (Banner or Fallback)
                SizedBox(
                  height: 94,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event.banner != null && event.banner!.trim().isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: event.banner!.trim(),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildBannerFallback(isDark),
                          errorWidget: (_, __, ___) => _buildBannerFallback(isDark),
                        )
                      else
                        _buildBannerFallback(isDark),

                      // Overlay gradient for date legibility
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6],
                          ),
                        ),
                      ),

                      // Floating Date & Status Chips
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: Text(
                            dateMonthDay,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.status.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Content Section
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 11, color: textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                          if (event.venue != null && event.venue!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Colors.grey, fontSize: 8)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                event.venue!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyEventsCarousel(bool isDark, Color textSecondary) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 28, color: textSecondary),
          const SizedBox(height: 6),
          Text(
            'No upcoming events scheduled',
            style: GoogleFonts.inter(fontSize: 12.5, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SKELETON LOADING & ERROR STATES
  // ---------------------------------------------------------------------------
  Widget _buildSkeletonLoading(bool isDark) {
    final baseColor = isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA);
    final highlightColor = isDark ? const Color(0xFF28282E) : const Color(0xFFF2F2F7);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 6),
            // Hero card skeleton
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            // Statistics overview skeleton
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 18),
            // Activity timeline skeleton
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 18),
            // Carousel skeleton
            Container(
              height: 165,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: isDark ? AppColors.errorDark : AppColors.error),
            const SizedBox(height: 10),
            Text(
              'Unable to load operations dashboard',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(eventsProvider);
                ref.invalidate(studentsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: FEATURED EVENT SELECTION
  // ---------------------------------------------------------------------------
  EventEntity? _resolveFeaturedEvent(List<EventEntity> events) {
    if (events.isEmpty) return null;
    final sorted = EventEntity.sortChronologically(events);
    // If an active event has attendance open, prioritize it
    final openEvent = sorted.where((e) => e.isAttendanceOpen && !e.isPast).firstOrNull;
    if (openEvent != null) return openEvent;
    return EventEntity.findDefaultEvent(sorted);
  }
}
