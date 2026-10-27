import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/providers/student_provider.dart';
import '../../../analytics/presentation/widgets/society_activity_heatmap_card.dart';
import '../../../analytics/providers/analytics_provider.dart';
import '../widgets/stacked_event_deck.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _activeStageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final eventsAsync = ref.watch(eventsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: accent,
          backgroundColor:
              isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.read(authNotifierProvider.notifier).refreshCurrentUser();
            ref.invalidate(eventsProvider);
            ref.invalidate(studentsProvider);
            ref.invalidate(eventScopedStudentsFamilyProvider);
            ref.invalidate(activityHeatmapProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // 1. Minimal Personalized Header
              SliverToBoxAdapter(
                child: _buildMinimalHeader(context, user, isDark),
              ),

              // Events & Operations Stream
              eventsAsync.when(
                data: (events) {
                  final featuredEvent = _resolveFeaturedEvent(events);
                  final featuredList = <EventEntity>[];
                  if (featuredEvent != null) {
                    featuredList.add(featuredEvent);
                    for (final e in events) {
                      if (e.id != featuredEvent.id && featuredList.length < 5) {
                        featuredList.add(e);
                      }
                    }
                  }
                  if (_activeStageIndex >= featuredList.length &&
                      featuredList.isNotEmpty) {
                    _activeStageIndex = 0;
                  }
                  final currentStageEvent = featuredList.isNotEmpty
                      ? featuredList[_activeStageIndex % featuredList.length]
                      : null;
                  final otherEvents = events
                      .where((e) =>
                          e.id != (currentStageEvent ?? featuredEvent)?.id)
                      .toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // 2. Featured Event Stage (3D layered card deck with peeking cards & indicator dots)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
                        child: _buildFeaturedEventStage(
                          context,
                          featuredList: featuredList,
                          activeIndex: _activeStageIndex,
                          isDark: isDark,
                          isAdmin: user?.isAdmin ?? false,
                          onStageIndexChanged: (newIdx) {
                            setState(() => _activeStageIndex = newIdx);
                          },
                        ),
                      ),

                      // 3. Quick Operations Row (Scan, Create, Manage, Members)
                      if (featuredList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                          child: _buildQuickOperationsRow(
                            context,
                            currentEvent: currentStageEvent ?? featuredEvent,
                            isDark: isDark,
                            canCreate: user?.isAdmin ?? false,
                          ),
                        ),

                      // 4. Today at a Glance (Compact Operational Pulse)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildAttendanceOverview(context,
                            currentStageEvent ?? featuredEvent, isDark),
                      ),

                      // 5. Upcoming Highlights (Image-Led Horizontal Highlights)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: _buildUpcomingEventsCarousel(
                            context, otherEvents, isDark),
                      ),

                      // 6. Recent Activity (Connected Timeline, hidden if no activity)
                      _buildRecentActivityTimeline(
                          context, currentStageEvent ?? featuredEvent, isDark),
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
  Widget _buildMinimalHeader(
      BuildContext context, UserEntity? user, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim().split(RegExp(r'\s+')).first
        : 'Operator';
    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N';
    final avatarUrl = user?.avatar?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final fullAvatarUrl = hasAvatar
        ? ((avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'))
            ? avatarUrl
            : '${ApiConstants.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl')
        : '';
    final currentDateFormatted =
        DateFormat('EEEE, MMM d').format(DateTime.now());

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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
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
                            style: AppTextStyles.labelSm.copyWith(
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
                  style: AppTextStyles.headlineMd.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '$currentDateFormatted • '),
                      const TextSpan(
                        text: 'Let\'s make today count.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  style: AppTextStyles.bodySm.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Notification icon, Insights icon & Profile avatar
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
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0F000000),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.04),
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

              // Analytics / Insights icon button
              Semantics(
                label: 'Analytics and Reports',
                button: true,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push(RouteConstants.reports);
                  },
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0F000000),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: textPrimary,
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
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0F000000),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.04),
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
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.45 : 0.28),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: hasAvatar
                        ? CachedNetworkImage(
                            imageUrl: fullAvatarUrl,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            placeholder: (_, __) => Center(
                              child: Text(
                                avatarLetter,
                                style: AppTextStyles.labelLg.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                avatarLetter,
                                style: AppTextStyles.labelLg.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              avatarLetter,
                              style: AppTextStyles.labelLg.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
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
  // ---------------------------------------------------------------------------
  // 2. FEATURED EVENT STAGE (3D LAYERED DECK CENTERPIECE)
  // ---------------------------------------------------------------------------
  Widget _buildFeaturedEventStage(
    BuildContext context, {
    required List<EventEntity> featuredList,
    required int activeIndex,
    required bool isDark,
    required bool isAdmin,
    required ValueChanged<int> onStageIndexChanged,
  }) {
    if (featuredList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildFeaturedEventCard(context, null, isDark, isAdmin: isAdmin),
      );
    }

    return StackedEventDeck(
      events: featuredList,
      activeIndex: activeIndex,
      isDark: isDark,
      isAdmin: isAdmin,
      onIndexChanged: onStageIndexChanged,
    );
  }

  // Backward compatibility alias for tests
  Widget _buildFeaturedEventCard(
    BuildContext context,
    EventEntity? event,
    bool isDark, {
    bool isAdmin = false,
  }) {
    if (event == null) {
      return _buildEmptyFeaturedCard(context, isDark);
    }
    return StackedEventDeck(
      events: [event],
      activeIndex: 0,
      isDark: isDark,
      isAdmin: isAdmin,
      onIndexChanged: (_) {},
    );
  }

  // ---------------------------------------------------------------------------
  // 3. QUICK OPERATIONS ROW (COMPACT COMMAND DOCK)
  // ---------------------------------------------------------------------------
  Widget _buildQuickOperationsRow(
    BuildContext context, {
    required EventEntity? currentEvent,
    required bool isDark,
    required bool canCreate,
  }) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final actions = [
      (
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan',
        onTap: () {
          HapticFeedback.lightImpact();
          final eventId = currentEvent?.id ?? '';
          context.push('${RouteConstants.attendance}/qr-scan?eventId=$eventId');
        },
      ),
      (
        icon: Icons.add_circle_outline_rounded,
        label: 'Create',
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(RouteConstants.createEvent);
        },
      ),
      (
        icon: Icons.calendar_today_outlined,
        label: 'Manage',
        onTap: () {
          HapticFeedback.lightImpact();
          context.go(RouteConstants.events);
        },
      ),
      (
        icon: Icons.people_outline_rounded,
        label: 'Members',
        onTap: () {
          HapticFeedback.lightImpact();
          context.go(RouteConstants.members);
        },
      ),
    ];

    return Row(
      children: actions.map((act) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: act.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(act.icon, size: 22, color: accent),
                    const SizedBox(height: 6),
                    Text(
                      act.label,
                      style: AppTextStyles.labelMd.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Events will appear here once configured',
            style: AppTextStyles.captionItalic.copyWith(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ATTENDANCE OVERVIEW (COMPACT HORIZONTAL STATISTICS SECTION)
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceOverview(
      BuildContext context, EventEntity? featuredEvent, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);

    // Dynamic metrics retrieval
    final allStudentsAsync = ref.watch(studentsProvider);
    final eventScopedAsync = featuredEvent != null
        ? ref.watch(eventScopedStudentsFamilyProvider(featuredEvent.id))
        : null;

    int totalRegistered = 0;
    int presentCount = 0;

    if (eventScopedAsync != null &&
        eventScopedAsync.hasValue &&
        eventScopedAsync.value != null) {
      totalRegistered = eventScopedAsync.value!.counts.total;
      presentCount = eventScopedAsync.value!.counts.present;
    } else if (featuredEvent == null &&
        allStudentsAsync.hasValue &&
        allStudentsAsync.value != null) {
      final students = allStudentsAsync.value!;
      totalRegistered = students.length;
      presentCount = students.where((s) => s.isPresent).length;
    }

    final double progress = totalRegistered > 0
        ? (presentCount / totalRegistered).clamp(0.0, 1.0)
        : 0.0;
    final int percentage = (progress * 100).round();
    final int remaining =
        totalRegistered >= presentCount ? (totalRegistered - presentCount) : 0;

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
            // Top Section Header: Title & Event Scope / Manage Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded,
                          size: 16, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'Today at a glance',
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'ATTENDANCE OPERATIONS',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (featuredEvent != null) {
                      ref.read(selectedEventIdProvider.notifier).state =
                          featuredEvent.id;
                    }
                    context.push(RouteConstants.students);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          featuredEvent != null
                              ? 'Event Scope'
                              : 'All Students',
                          style: AppTextStyles.labelMd.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded,
                            size: 14, color: accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3 Modern Operational Pulse Tiles (Mockup Screen 1)
            Row(
              children: [
                // 1. Live Check-In Pill
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14171E)
                          : const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x14FFFFFF)
                            : const Color(0x0A000000),
                        width: 0.6,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Check-in',
                          style: AppTextStyles.labelSm.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: BoxDecoration(
                                color:
                                    (featuredEvent?.isAttendanceOpen ?? false)
                                        ? successColor
                                        : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4.5),
                            Text(
                              (featuredEvent?.isAttendanceOpen ?? false)
                                  ? 'Open'
                                  : 'Standby',
                              style: AppTextStyles.labelSm.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color:
                                    (featuredEvent?.isAttendanceOpen ?? false)
                                        ? successColor
                                        : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Checked In / Present
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14171E)
                          : const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x14FFFFFF)
                            : const Color(0x0A000000),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded,
                            size: 19, color: successColor),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                presentCount.toString(),
                                style: AppTextStyles.metricMd.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: successColor,
                                ),
                              ),
                              Text(
                                'Present',
                                style: AppTextStyles.labelSm.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Registered / Attendance Rate
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF14171E)
                          : const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x14FFFFFF)
                            : const Color(0x0A000000),
                        width: 0.6,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.8,
                            backgroundColor: isDark
                                ? const Color(0xFF26262B)
                                : const Color(0xFFE5E5EA),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalRegistered.toString(),
                                style: AppTextStyles.metricMd.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Registered',
                                style: AppTextStyles.labelSm.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Continuous Horizontal Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: AppTextStyles.metricMd.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'rate',
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$remaining remaining',
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 4,
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
  Widget _buildRecentActivityTimeline(
      BuildContext context, EventEntity? featuredEvent, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);

    // Retrieve recent students (scoped to featured event if available, otherwise general)
    final allStudents = ref.watch(studentsProvider).value ?? [];
    final scopedStudents = featuredEvent != null
        ? (ref
                .watch(eventScopedStudentsFamilyProvider(featuredEvent.id))
                .value
                ?.students ??
            [])
        : <StudentEntity>[];

    final scopedPresent = scopedStudents.where((s) => s.isPresent).toList();
    final allPresent = allStudents.where((s) => s.isPresent).toList();
    final presentStudents =
        scopedPresent.isNotEmpty ? scopedPresent : allPresent;

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
                style: AppTextStyles.labelSm.copyWith(
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
                  style: AppTextStyles.labelMd.copyWith(
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
        final targetId =
            student.id.isNotEmpty ? student.id : student.rollNumber;
        context.push('${RouteConstants.students}/$targetId');
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
                      style: AppTextStyles.labelSm.copyWith(
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
                          color: isDark
                              ? AppColors.darkSeparator
                              : AppColors.lightSeparator,
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
                      style: AppTextStyles.bodyMd.copyWith(
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
                      style: AppTextStyles.bodySm.copyWith(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color:
                          successColor.withValues(alpha: isDark ? 0.16 : 0.10),
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
                          style: AppTextStyles.labelSm.copyWith(
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
                    style: AppTextStyles.caption.copyWith(
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
  Widget _buildUpcomingEventsCarousel(
      BuildContext context, List<EventEntity> events, bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Upcoming Highlights',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (displayEvents.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        displayEvents.length.toString(),
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Text(
                    '•',
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'UPCOMING SCHEDULE',
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(RouteConstants.events);
              },
              child: Text(
                'See All',
                style: AppTextStyles.labelMd.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Carousel Container (Image-Led Mini Cards matching Screen 1)
        SizedBox(
          height: 88,
          child: displayEvents.isEmpty
              ? _buildEmptyEventsCarousel(isDark, textSecondary)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final event = displayEvents[index];
                    return _buildCarouselCard(context, event, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(
      BuildContext context, EventEntity event, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final dateMonthDay = DateFormat('MMM d').format(event.startDate);
    final venueStr = (event.venue != null && event.venue!.trim().isNotEmpty)
        ? event.venue!.trim()
        : 'Campus';

    return Semantics(
      label: 'Event: ${event.title}',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('${RouteConstants.events}/${event.id}');
        },
        child: Container(
          width: 235,
          padding: const EdgeInsets.all(8),
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
          child: Row(
            children: [
              // Left: Rounded cover image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: (event.banner != null &&
                          event.banner!.trim().isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: event.banner!.trim(),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          placeholder: (_, __) => _buildBannerFallback(isDark),
                          errorWidget: (_, __, ___) =>
                              _buildBannerFallback(isDark),
                        )
                      : _buildBannerFallback(isDark),
                ),
              ),
              const SizedBox(width: 10),

              // Right: Title, Date & Venue, UPCOMING status pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateMonthDay • $venueStr',
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'UPCOMING',
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEventsCarousel(bool isDark, Color textSecondary) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000);

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
            style: AppTextStyles.captionItalic
                .copyWith(fontSize: 12.5, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SKELETON LOADING & ERROR STATES
  // ---------------------------------------------------------------------------
  Widget _buildSkeletonLoading(bool isDark) {
    final baseColor =
        isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA);
    final highlightColor =
        isDark ? const Color(0xFF28282E) : const Color(0xFFF2F2F7);

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
            Icon(Icons.error_outline_rounded,
                size: 40,
                color: isDark ? AppColors.errorDark : AppColors.error),
            const SizedBox(height: 10),
            Text(
              'Unable to load operations dashboard',
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: AppTextStyles.captionItalic.copyWith(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
    final openEvent =
        sorted.where((e) => e.isAttendanceOpen && !e.isPast).firstOrNull;
    if (openEvent != null) return openEvent;
    return EventEntity.findDefaultEvent(sorted);
  }
}
