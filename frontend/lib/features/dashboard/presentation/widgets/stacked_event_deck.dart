import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';

/// True 3D Layered Event Card Deck with crisp artwork and real cover images
class StackedEventDeck extends ConsumerStatefulWidget {
  final List<EventEntity> events;
  final int activeIndex;
  final bool isDark;
  final bool isAdmin;
  final ValueChanged<int> onIndexChanged;

  const StackedEventDeck({
    super.key,
    required this.events,
    required this.activeIndex,
    required this.isDark,
    required this.isAdmin,
    required this.onIndexChanged,
  });

  @override
  ConsumerState<StackedEventDeck> createState() => _StackedEventDeckState();
}

class _StackedEventDeckState extends ConsumerState<StackedEventDeck>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _dragAnimation;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  bool get isDragging => _isDragging;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animController.addListener(() {
      if (_dragAnimation != null) {
        setState(() {
          _dragOffset = _dragAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_animController.isAnimating) {
      _animController.stop();
    }
    setState(() {
      _isDragging = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta ?? 0.0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final count = widget.events.length;

    if (count <= 1) {
      _animateToRest();
      return;
    }

    // Swipe threshold
    if (_dragOffset < -65 || velocity < -280) {
      // Swipe left -> advance to next event
      HapticFeedback.selectionClick();
      final target = -screenWidth;
      _dragAnimation = Tween<double>(begin: _dragOffset, end: target).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0.0).then((_) {
        widget.onIndexChanged((widget.activeIndex + 1) % count);
        _dragOffset = 0.0;
        _animController.reset();
      });
    } else if (_dragOffset > 65 || velocity > 280) {
      // Swipe right -> return to previous event
      HapticFeedback.selectionClick();
      final target = screenWidth;
      _dragAnimation = Tween<double>(begin: _dragOffset, end: target).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0.0).then((_) {
        widget.onIndexChanged((widget.activeIndex - 1 + count) % count);
        _dragOffset = 0.0;
        _animController.reset();
      });
    } else {
      // Gesture cancelled -> spring back to resting state
      _animateToRest();
    }
  }

  void _animateToRest() {
    _dragAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward(from: 0.0).then((_) {
      _animController.reset();
      setState(() => _dragOffset = 0.0);
    });
  }

  String _calculateTimeBadge(EventEntity event) {
    if (event.isAttendanceOpen && !event.isPast) {
      return 'LIVE CHECK-IN OPEN';
    }
    final now = DateTime.now();
    if (event.effectiveStatus == 'upcoming') {
      final diff = event.startDate.difference(now);
      if (diff.inDays > 1) {
        return '${diff.inDays} DAYS LEFT';
      } else if (diff.inDays == 1) {
        return 'TOMORROW';
      } else if (diff.inHours > 0) {
        return 'STARTS IN ${diff.inHours}H';
      } else {
        return 'STARTING SOON';
      }
    }
    return event.effectiveStatus.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.events.length;
    if (count == 0) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    // Card width occupies ~86-88% of screen width (clamped for larger devices)
    final cardWidth = (screenWidth * 0.88).clamp(280.0, 420.0);
    const cardHeight = 305.0;

    final activeIdx = widget.activeIndex % count;
    final activeEvent = widget.events[activeIdx];

    if (count == 1) {
      return Column(
        children: [
          SizedBox(
            height: cardHeight,
            width: cardWidth,
            child: _buildForegroundCard(
              context,
              activeEvent,
              cardWidth,
              cardHeight,
            ),
          ),
        ],
      );
    }

    final prevIndex = (activeIdx - 1 + count) % count;
    final nextIndex = (activeIdx + 1) % count;
    final prevEvent = widget.events[prevIndex];
    final nextEvent = widget.events[nextIndex];

    // Drag progress (-1.0 to 1.0)
    final progress = (_dragOffset / cardWidth).clamp(-1.0, 1.0);

    final sideMargin = ((screenWidth - cardWidth) / 2).clamp(0.0, 100.0);

    return Column(
      children: [
        // 1. Genuine 3D Layered Card Stack (Left background, Right background, Foreground center)
        GestureDetector(
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: cardHeight + 20, // ample vertical room for subtle tilt
            width: screenWidth,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. LEFT BACKGROUND CARD (Rotated -6°, offset to left, softly blurred)
                _buildLeftBackgroundCard(
                  context,
                  prevEvent,
                  cardWidth,
                  cardHeight,
                  progress,
                  prevIndex,
                ),

                // 2. RIGHT BACKGROUND CARD (Rotated +6°, offset to right, softly blurred)
                _buildRightBackgroundCard(
                  context,
                  nextEvent,
                  cardWidth,
                  cardHeight,
                  progress,
                  nextIndex,
                ),

                // 3. CENTER ACTIVE CARD (Dominant foreground, straight resting, sharp content)
                _buildActiveForegroundCard(
                  context,
                  activeEvent,
                  cardWidth,
                  cardHeight,
                  progress,
                ),

                // 4. Dedicated Left Wing Tap Target (outside active card bounds)
                if (sideMargin > 10)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: sideMargin,
                    child: GestureDetector(
                      key: const ValueKey('deck_left_wing_tap'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onIndexChanged(prevIndex);
                      },
                    ),
                  ),

                // 5. Dedicated Right Wing Tap Target (outside active card bounds)
                if (sideMargin > 10)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: sideMargin,
                    child: GestureDetector(
                      key: const ValueKey('deck_right_wing_tap'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onIndexChanged(nextIndex);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Carousel Position Indicator Dots
        _buildPositionIndicator(count, activeIdx),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. LEFT BACKGROUND CARD
  // ---------------------------------------------------------------------------
  Widget _buildLeftBackgroundCard(
    BuildContext context,
    EventEntity event,
    double cardWidth,
    double cardHeight,
    double progress,
    int targetIndex,
  ) {
    // Resting state: translated left by 42px, rotated -0.10 rad (-5.7°), scale 0.90
    // Dragging right (progress > 0): moves toward center (0), rotates to 0, scales to 1.0
    // Dragging left (progress < 0): recedes further
    const double restingOffsetX = -40.0;
    final double currentOffsetX = progress > 0
        ? restingOffsetX + (40.0 * progress)
        : restingOffsetX + (20.0 * progress);

    const double restingRotation = -0.105; // -6°
    final double currentRotation =
        progress > 0 ? restingRotation + (0.105 * progress) : restingRotation;

    const double restingScale = 0.90;
    final double currentScale = progress > 0
        ? (restingScale + (0.10 * progress)).clamp(0.85, 1.0)
        : (restingScale + (0.05 * progress)).clamp(0.82, 0.95);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(currentOffsetX, 0.0, 0.0, 1.0)
        ..rotateZ(currentRotation)
        ..scaleByDouble(currentScale, currentScale, 1.0, 1.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onIndexChanged(targetIndex);
        },
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _buildBackgroundCardSurface(
            event: event,
            isLeft: true,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. RIGHT BACKGROUND CARD
  // ---------------------------------------------------------------------------
  Widget _buildRightBackgroundCard(
    BuildContext context,
    EventEntity event,
    double cardWidth,
    double cardHeight,
    double progress,
    int targetIndex,
  ) {
    // Resting state: translated right by 42px, rotated +0.10 rad (+5.7°), scale 0.90
    // Dragging left (progress < 0): moves toward center (0), rotates to 0, scales to 1.0
    // Dragging right (progress > 0): recedes further
    const double restingOffsetX = 40.0;
    final double currentOffsetX = progress < 0
        ? restingOffsetX + (40.0 * progress)
        : restingOffsetX + (20.0 * progress);

    const double restingRotation = 0.105; // +6°
    final double currentRotation =
        progress < 0 ? restingRotation + (0.105 * progress) : restingRotation;

    const double restingScale = 0.90;
    final double currentScale = progress < 0
        ? (restingScale + (0.10 * progress.abs())).clamp(0.85, 1.0)
        : (restingScale - (0.05 * progress)).clamp(0.82, 0.95);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(currentOffsetX, 0.0, 0.0, 1.0)
        ..rotateZ(currentRotation)
        ..scaleByDouble(currentScale, currentScale, 1.0, 1.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onIndexChanged(targetIndex);
        },
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _buildBackgroundCardSurface(
            event: event,
            isLeft: false,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. BACKGROUND CARD SURFACE (With soft blur and peeking content)
  // ---------------------------------------------------------------------------
  Widget _buildBackgroundCardSurface({
    required EventEntity event,
    required bool isLeft,
  }) {
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final timeBadge = _calculateTimeBadge(event);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0x33FFFFFF) : const Color(0x18000000),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Event Cover Image Layer (Sharp and unblurred)
            (event.banner != null && event.banner!.trim().isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: event.banner!.trim(),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    placeholder: (_, __) => _buildBannerFallback(isDark),
                    errorWidget: (_, __, ___) => _buildBannerFallback(isDark),
                  )
                : _buildBannerFallback(isDark),

            // 2. High-Tech Dark Scrim Overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.40, 1.0],
                ),
              ),
            ),

            // 3. Peeking Top Badges
            Positioned(
              top: 14,
              left: isLeft ? 14 : null,
              right: isLeft ? null : 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLeft
                      ? const Color(0xFF00E676).withValues(alpha: 0.25)
                      : accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLeft ? const Color(0xFF00E676) : accent,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isLeft ? timeBadge : event.type.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isLeft ? const Color(0xFF00E676) : accent,
                  ),
                ),
              ),
            ),

            // 4. Peeking Bottom Title
            Positioned(
              left: isLeft ? 14 : null,
              right: isLeft ? null : 14,
              bottom: 16,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  event.title.toUpperCase(),
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isLeft ? TextAlign.left : TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. ACTIVE FOREGROUND CARD
  // ---------------------------------------------------------------------------
  Widget _buildActiveForegroundCard(
    BuildContext context,
    EventEntity event,
    double cardWidth,
    double cardHeight,
    double progress,
  ) {
    // Dynamic interactive transformation during dragging
    final currentTranslationX = _dragOffset;
    final currentRotation = progress * 0.12;
    final currentScale = (1.0 - (progress.abs() * 0.05)).clamp(0.92, 1.0);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translateByDouble(currentTranslationX, 0.0, 0.0, 1.0)
        ..rotateZ(currentRotation)
        ..scaleByDouble(currentScale, currentScale, 1.0, 1.0),
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: _buildForegroundCard(
          context,
          event,
          cardWidth,
          cardHeight,
        ),
      ),
    );
  }

  Widget _buildForegroundCard(
    BuildContext context,
    EventEntity event,
    double cardWidth,
    double cardHeight,
  ) {
    final isDark = widget.isDark;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final dateFormatted =
        DateFormat('EEE, MMM d • h:mm a').format(event.startDate);
    final timeBadge = _calculateTimeBadge(event);

    return Semantics(
      label: 'Featured Event: ${event.title}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: (event.isAttendanceOpen && !event.isPast)
                ? successColor.withValues(alpha: isDark ? 0.65 : 0.75)
                : const Color(0xFF2997FF)
                    .withValues(alpha: isDark ? 0.45 : 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (event.isAttendanceOpen && !event.isPast)
                  ? successColor.withValues(alpha: isDark ? 0.25 : 0.14)
                  : const Color(0xFF2997FF)
                      .withValues(alpha: isDark ? 0.22 : 0.10),
              blurRadius: 26,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Event Cover Image Layer (Crisp, sharp, and high-fidelity)
              (event.banner != null && event.banner!.trim().isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: event.banner!.trim(),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      placeholder: (_, __) => _buildBannerFallback(isDark),
                      errorWidget: (_, __, ___) => _buildBannerFallback(isDark),
                    )
                  : _buildBannerFallback(isDark),

              // 2. High-Tech Scrim Gradients for text contrast
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.50),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.28, 0.62, 1.0],
                  ),
                ),
              ),

              // 3. Card Tap Surface (Navigates to Event Details)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (GoRouter.maybeOf(context) != null) {
                      context.push('${RouteConstants.events}/${event.id}');
                    }
                  },
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.white.withValues(alpha: 0.04),
                  child: const SizedBox.expand(),
                ),
              ),

              // 4. Top Operational Beacon Strip (Sharp foreground badges)
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Status Radar Beacon
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4.5),
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
                              color: (event.isAttendanceOpen && !event.isPast)
                                  ? successColor
                                  : Colors.white70,
                              shape: BoxShape.circle,
                              boxShadow: (event.isAttendanceOpen &&
                                      !event.isPast)
                                  ? [
                                      BoxShadow(
                                        color:
                                            successColor.withValues(alpha: 0.8),
                                        blurRadius: 7,
                                        spreadRadius: 1.5,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeBadge,
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: (event.isAttendanceOpen && !event.isPast)
                                  ? successColor
                                  : Colors.white,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xE6080B11),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF2997FF)
                                  .withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            event.type.toUpperCase(),
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: const Color(0xFF2997FF),
                            ),
                          ),
                        ),

                        // Admin Quick Toggle
                        if (widget.isAdmin) ...[
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
                                final nextState =
                                    !(event.isAttendanceOpen && !event.isPast);
                                final result = await ref
                                    .read(eventRepositoryProvider)
                                    .toggleAttendance(event.id, nextState);
                                result.fold(
                                  (failure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(failure.message),
                                        backgroundColor:
                                            AppColors.errorOf(context),
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
                                        duration:
                                            const Duration(milliseconds: 1500),
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

              // 5. Bottom Event Details & Action Region (Sharp foreground content)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title
                    Text(
                      event.title,
                      style: AppTextStyles.titleLg.copyWith(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.description != null &&
                        event.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.description!.trim().split('\n').first,
                        style: AppTextStyles.editorialSubtitle.copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Date & Venue Details
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateFormatted,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.venue != null && event.venue!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              event.venue!,
                              style: AppTextStyles.bodySm.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons Row (White Pill "View Event ->" & "Scan QR Pass")
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (GoRouter.maybeOf(context) != null) {
                                context.push(
                                    '${RouteConstants.events}/${event.id}');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF101012),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View Event',
                                  style: AppTextStyles.buttonSm.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF101012),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Color(0xFF101012),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (event.isAttendanceOpen && !event.isPast) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              if (GoRouter.maybeOf(context) != null) {
                                context.push(
                                    '${RouteConstants.attendance}/qr-scan?eventId=${event.id}');
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner_rounded,
                                size: 14),
                            label: Text(
                              'Scan QR Pass',
                              style: AppTextStyles.buttonSm.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: successColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
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
    );
  }

  // ---------------------------------------------------------------------------
  // 5. POSITION INDICATOR DOTS
  // ---------------------------------------------------------------------------
  Widget _buildPositionIndicator(int count, int activeIdx) {
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIdx;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onIndexChanged(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 22 : 6,
            height: 4.5,
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? Colors.white : accent)
                  : (isDark ? Colors.white24 : Colors.black12),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBannerFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF141720) : const Color(0xFFE5E7EB),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 48,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }
}
