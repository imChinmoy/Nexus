import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../students/providers/student_provider.dart';
import '../../domain/entities/event_entity.dart';
import '../../providers/event_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  int _selectedTabIndex = 0;
  String _attendeeSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final user = ref.watch(currentUserProvider);
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final permissionsAsync = ref.watch(myPermissionsProvider);
    final permissions = permissionsAsync.value ?? [];
    final hasEventEdit = isSuperAdmin ||
        permissions.contains('event:edit') ||
        permissions.contains('all');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: eventsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: accent),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.errorOf(context)),
                const SizedBox(height: 12),
                Text('Failed to load event', style: AppTextStyles.headlineSm),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          data: (events) {
            final event = events.where((e) => e.id == widget.eventId).firstOrNull;
            if (event == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded,
                          size: 48, color: AppColors.errorOf(context)),
                      const SizedBox(height: 12),
                      Text('Event Not Found', style: AppTextStyles.headlineSm),
                      const SizedBox(height: 6),
                      Text(
                        'This event could not be found or has been removed.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (GoRouter.maybeOf(context)?.canPop() ?? false) {
                            context.pop();
                          } else {
                            context.go(RouteConstants.events);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Hero AppBar with Large Editorial Poster & Floating Glass Controls
                _buildEditorialHeroAppBar(context, event, hasEventEdit, isDark),

                // 2. Main Content Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary Operations Buttons (Scan QR Attendance & Manual Entry)
                        _buildPrimaryActionRow(context, event, isDark),
                        const SizedBox(height: 18),

                        // Segmented Navigation Bar: [Overview, Updates, Attendees, Gallery]
                        _buildSegmentedNavBar(context, isDark),
                        const SizedBox(height: 18),

                        // Tab View Content
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildCurrentTabContent(
                              context, event, hasEventEdit, isDark),
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

  // ---------------------------------------------------------------------------
  // 1. HERO SLIVER APP BAR
  // ---------------------------------------------------------------------------
  Widget _buildEditorialHeroAppBar(
    BuildContext context,
    EventEntity event,
    bool hasEventEdit,
    bool isDark,
  ) {
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final now = DateTime.now();
    final daysUntil = event.startDate.difference(now).inDays;

    final String statusLabel;
    if (event.isAttendanceOpen && !event.isPast) {
      statusLabel = 'LIVE CHECK-IN OPEN';
    } else if (daysUntil > 0) {
      statusLabel = '$daysUntil DAYS LEFT';
    } else if (event.effectiveStatus == 'ongoing') {
      statusLabel = 'HAPPENING TODAY';
    } else {
      statusLabel = event.effectiveStatus.toUpperCase();
    }

    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark
          ? const Color(0xFF0D0F14).withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.40),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.7,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Share Action Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.7,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined,
                      size: 18, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(
                      text:
                          '${event.title} - ${event.venue ?? "Blockchain Research Lab"}\nDates: ${_formatDate(event.startDate)} – ${_formatDate(event.endDate)}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event details copied to clipboard!'),
                        duration: Duration(milliseconds: 1500),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Edit / More Action Button
        if (hasEventEdit)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.7,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 19, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('${RouteConstants.events}/${event.id}/edit',
                          extra: event);
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
            // Event Cover Image
            if (event.banner != null && event.banner!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: event.banner!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark
                      ? const Color(0xFF14171E)
                      : const Color(0xFFE5E7EB),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _buildPlaceholderBanner(context),
              )
            else
              _buildPlaceholderBanner(context),

            // Top Scrim and Vignette
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                    isDark ? const Color(0xFF0B0D13) : const Color(0xFFF6F8FA),
                  ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),

            // Bottom Hero Content Info (Badges, Title, Date, Venue)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status & Type Pills
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00E676),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E676),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: const Color(0xFF00E676),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accent,
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          event.type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Large Event Title
                  Text(
                    event.title,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Event Tagline / Description subtitle
                  Text(
                    event.description?.isNotEmpty == true
                        ? event.description!.split('\n').first
                        : 'CODE • CREATE • CONNECT',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Date & Venue Details Row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: Colors.white.withValues(alpha: 0.75)),
                      const SizedBox(width: 5),
                      Text(
                        '${_formatDate(event.startDate)} – ${_formatDate(event.endDate)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.white.withValues(alpha: 0.75)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue?.isNotEmpty == true
                              ? event.venue!
                              : 'CSIT Block',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
  // 2. PRIMARY ACTION BUTTONS (Scan QR Attendance & Manual Entry)
  // ---------------------------------------------------------------------------
  Widget _buildPrimaryActionRow(
      BuildContext context, EventEntity event, bool isDark) {
    return Row(
      children: [
        // Big Prominent Blue Button: Scan QR Attendance
        Expanded(
          flex: 6,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2997FF), Color(0xFF0A84FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(
                      '${RouteConstants.attendance}/qr-scan?eventId=${event.id}');
                },
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Scan QR Attendance',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Secondary Button: Manual Entry
        Expanded(
          flex: 4,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141720) : const Color(0xFFF3F4F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0x24FFFFFF) : const Color(0x18000000),
                width: 0.9,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(
                      '${RouteConstants.attendance}/manual?eventId=${event.id}');
                },
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Manual Entry',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SEGMENTED NAVIGATION BAR: [Overview, Updates, Attendees, Gallery]
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedNavBar(BuildContext context, bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final tabs = ['Overview', 'Updates', 'Attendees', 'Gallery'];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0x18FFFFFF) : const Color(0x10000000),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = index);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      tabs[index],
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? accent : textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Animated bottom underline
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2.2,
                    decoration: BoxDecoration(
                      color: isSelected ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. TAB VIEWS ROUTER
  // ---------------------------------------------------------------------------
  Widget _buildCurrentTabContent(
    BuildContext context,
    EventEntity event,
    bool hasEventEdit,
    bool isDark,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(context, event, hasEventEdit, isDark);
      case 1:
        return _buildUpdatesTab(context, event, isDark);
      case 2:
        return _buildAttendeesTab(context, event, isDark);
      case 3:
        return _buildGalleryTab(context, event, isDark);
      default:
        return _buildOverviewTab(context, event, hasEventEdit, isDark);
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 1: OVERVIEW TAB (About Card, Tags, 3 Stat Pills, Media Highlights)
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(
    BuildContext context,
    EventEntity event,
    bool hasEventEdit,
    bool isDark,
  ) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final cardBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA);
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000);

    final daysDuration =
        event.endDate.difference(event.startDate).inDays.clamp(1, 90);

    return Column(
      key: const ValueKey('tab_overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "About This Event" Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'About This Event',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.description?.isNotEmpty == true
                    ? event.description!
                    : 'Join us for this exciting society session featuring deep-dive presentations, peer workshops, hands-on tasks, and networking with members and industry experts.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Keyword Tag Chips
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  'Blockchain',
                  'Web3',
                  event.type.capitalize(),
                  'Tech Fest',
                  if (event.venue?.isNotEmpty == true) event.venue!,
                ].map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C202C)
                          : const Color(0xFFEBEFF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x18FFFFFF)
                            : const Color(0x0C000000),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3 Key Stat Pills (Capacity, Event Type, Duration)
        Row(
          children: [
            // Pill 1: Capacity
            Expanded(
              child: _buildMetricPill(
                icon: Icons.groups_rounded,
                value: event.capacity > 0 ? '${event.capacity}' : '500',
                label: 'Capacity',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Pill 2: Event Type
            Expanded(
              child: _buildMetricPill(
                icon: Icons.local_activity_rounded,
                value: event.type.capitalize(),
                label: 'Event Type',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),

            // Pill 3: Duration
            Expanded(
              child: _buildMetricPill(
                icon: Icons.access_time_rounded,
                value: '$daysDuration Days',
                label: 'Duration',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Media Gallery Preview Section (Mockup Screen 2)
        Text(
          'Media Highlights',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141720) : const Color(0xFFE5E7EB),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (event.banner != null && event.banner!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: event.banner!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(),
                    errorWidget: (_, __, ___) =>
                        _buildPlaceholderBanner(context),
                  )
                else
                  _buildPlaceholderBanner(context),
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 26, color: Color(0xFF0B0D13)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Row of 4 mini media thumbnails
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 52,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark
                      ? const Color(0xFF141720)
                      : const Color(0xFFE5E7EB),
                  image: event.banner != null && event.banner!.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(event.banner!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Admin Operations Controls Card (Status update & Attendance toggle)
        if (hasEventEdit) ...[
          _buildAdminControlsCard(context, ref, event),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: UPDATES TAB (Milestone Timeline)
  // ---------------------------------------------------------------------------
  Widget _buildUpdatesTab(
      BuildContext context, EventEntity event, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final updates = [
      {
        'title': 'Live Check-in Open',
        'time': 'Today',
        'desc': 'QR attendance gateway has been opened for gate operations.',
        'active': event.isAttendanceOpen,
      },
      {
        'title': 'Event Scheduled',
        'time': _formatDate(event.startDate),
        'desc':
            'Dates locked: ${_formatDate(event.startDate)} to ${_formatDate(event.endDate)} at ${event.venue ?? "Campus Auditorium"}.',
        'active': true,
      },
      {
        'title': 'Curriculum & Workshops Finalized',
        'time': 'Recently',
        'desc':
            'Speaker track and interactive tasks prepared for registered attendees.',
        'active': true,
      },
    ];

    return Column(
      key: const ValueKey('tab_updates'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline & Announcements',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...updates.map((u) {
          final isActive = u['active'] as bool;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? accent : textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 48,
                      color: isDark
                          ? const Color(0x1FFFFFFF)
                          : const Color(0x0E000000),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF13161F)
                          : const Color(0xFFF6F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0E000000),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              u['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              u['time'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u['desc'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: ATTENDEES TAB (Real Event-Scoped Registrations)
  // ---------------------------------------------------------------------------
  Widget _buildAttendeesTab(
      BuildContext context, EventEntity event, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final successColor = isDark ? AppColors.successDark : AppColors.success;

    final scopedAsync =
        ref.watch(eventScopedStudentsFamilyProvider(event.id));

    return Column(
      key: const ValueKey('tab_attendees'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Real Backend Attendees Async Resolver
        scopedAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Unable to load attendees: $err',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.errorOf(context)),
              ),
            ),
          ),
          data: (result) {
            final total = result?.counts.total ?? 0;
            final present = result?.counts.present ?? 0;
            final notScanned = result?.counts.notMarked ?? 0;
            final students = result?.students ?? [];

            final filteredStudents = _attendeeSearchQuery.trim().isEmpty
                ? students
                : students.where((s) {
                    final query = _attendeeSearchQuery.toLowerCase();
                    return s.name.toLowerCase().contains(query) ||
                        s.studentNo.toLowerCase().contains(query) ||
                        s.rollNumber.toLowerCase().contains(query);
                  }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attendance Summary Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF13161F)
                        : const Color(0xFFF6F8FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x1FFFFFFF)
                          : const Color(0x0E000000),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttendeeCountBlock(
                          'Total', total.toString(), textPrimary),
                      Container(
                        width: 1,
                        height: 24,
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0E000000),
                      ),
                      _buildAttendeeCountBlock(
                          'Present', present.toString(), successColor),
                      Container(
                        width: 1,
                        height: 24,
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0E000000),
                      ),
                      _buildAttendeeCountBlock(
                          'Not Scanned', notScanned.toString(), accent),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Search field
                TextField(
                  onChanged: (val) =>
                      setState(() => _attendeeSearchQuery = val),
                  style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search attendee by name or roll no...',
                    hintStyle:
                        GoogleFonts.inter(fontSize: 12, color: textSecondary),
                    prefixIcon:
                        Icon(Icons.search_rounded, size: 18, color: textSecondary),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF13161F)
                        : const Color(0xFFF6F8FA),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0E000000),
                        width: 0.8,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0x0E000000),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                if (filteredStudents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No attendees match the criteria',
                        style: GoogleFonts.inter(
                            fontSize: 12.5, color: textSecondary),
                      ),
                    ),
                  )
                else
                  ...filteredStudents.take(20).map((s) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF13161F)
                            : const Color(0xFFF6F8FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0x1FFFFFFF)
                              : const Color(0x0E000000),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                accent.withValues(alpha: isDark ? 0.2 : 0.1),
                            child: Text(
                              s.name.isNotEmpty
                                  ? s.name[0].toUpperCase()
                                  : 'S',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${s.studentNo} • ${s.branch.isNotEmpty ? s.branch : "Member"}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (s.isPresent ? successColor : Colors.orange)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.isPresent ? 'Present' : 'Not Scanned',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: s.isPresent
                                    ? successColor
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendeeCountBlock(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: GALLERY TAB (Event Moments Grid)
  // ---------------------------------------------------------------------------
  Widget _buildGalleryTab(
      BuildContext context, EventEntity event, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      key: const ValueKey('tab_gallery'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moments & Snapshots',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),
          itemCount: 4,
          itemBuilder: (context, i) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141720)
                      : const Color(0xFFE5E7EB),
                ),
                child: event.banner != null && event.banner!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: event.banner!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(),
                        errorWidget: (_, __, ___) =>
                            _buildPlaceholderBanner(context),
                      )
                    : _buildPlaceholderBanner(context),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS & ADMIN CONTROLS
  // ---------------------------------------------------------------------------
  Widget _buildPlaceholderBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF141720) : const Color(0xFFE5E7EB),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 64,
          color: AppColors.textTertiaryOf(context),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildAdminControlsCard(
      BuildContext context, WidgetRef ref, EventEntity event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);
    final successColor = AppColors.successOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ADMIN OPERATIONS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            InkWell(
              onTap: () {
                context.push('${RouteConstants.events}/${event.id}/edit',
                    extra: event);
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 13, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      'Full Edit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BrlGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Attendance Check-In Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (event.isAttendanceOpen
                                  ? successColor
                                  : AppColors.textTertiaryOf(context))
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          event.isAttendanceOpen
                              ? Icons.how_to_reg_rounded
                              : Icons.person_off_outlined,
                          size: 18,
                          color: event.isAttendanceOpen
                              ? successColor
                              : AppColors.textTertiaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Attendance Check-In',
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.isAttendanceOpen
                                ? 'Status: OPEN for verification'
                                : 'Status: CLOSED',
                            style: AppTextStyles.caption.copyWith(
                              color: event.isAttendanceOpen
                                  ? successColor
                                  : AppColors.textSecondaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: event.isAttendanceOpen,
                    activeTrackColor: successColor,
                    onChanged: (val) async {
                      HapticFeedback.mediumImpact();
                      final result = await ref
                          .read(eventRepositoryProvider)
                          .toggleAttendance(event.id, val);
                      result.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(failure.message),
                              backgroundColor: AppColors.errorOf(context),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        (_) {
                          ref.invalidate(eventsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Attendance check-in ${val ? 'opened' : 'closed'}'),
                              backgroundColor: val
                                  ? successColor
                                  : AppColors.surfaceOf(context),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: AppColors.borderOf(context), height: 1),
              const SizedBox(height: 14),

              // 2. Status Quick Selector
              Text(
                'Lifecycle Status',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['upcoming', 'ongoing', 'completed', 'cancelled']
                    .map((statusKey) {
                  final isCurrent = event.status.toLowerCase() == statusKey;
                  final Color chipColor;
                  switch (statusKey) {
                    case 'ongoing':
                      chipColor = successColor;
                      break;
                    case 'completed':
                      chipColor = accent;
                      break;
                    case 'cancelled':
                      chipColor = AppColors.errorOf(context);
                      break;
                    default:
                      chipColor = AppColors.warningOf(context);
                  }

                  return ChoiceChip(
                    label: Text(
                      statusKey[0].toUpperCase() + statusKey.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent
                            ? Colors.white
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                    selected: isCurrent,
                    selectedColor: chipColor,
                    backgroundColor: isDark
                        ? const Color(0xFF242428)
                        : const Color(0xFFEBEBEF),
                    side: BorderSide(
                      color:
                          isCurrent ? chipColor : AppColors.borderOf(context),
                      width: 0.8,
                    ),
                    onSelected: (selected) async {
                      if (!selected || isCurrent) return;
                      HapticFeedback.selectionClick();
                      final result =
                          await ref.read(eventRepositoryProvider).updateEvent(
                                event.id,
                                status: statusKey,
                              );
                      result.fold(
                        (failure) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(failure.message),
                              backgroundColor: AppColors.errorOf(context),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        (_) {
                          ref.invalidate(eventsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Status updated to ${statusKey.toUpperCase()}'),
                              backgroundColor: chipColor,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
