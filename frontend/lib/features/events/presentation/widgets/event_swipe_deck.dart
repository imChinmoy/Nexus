import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/event_entity.dart';
import 'event_deck_card.dart';

class EventSwipeDeck extends StatefulWidget {
  final List<EventEntity> events;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<EventEntity>? onCardTap;
  final ValueChanged<EventEntity>? onScanAttendance;
  final ValueChanged<EventEntity>? onEdit;
  final double cardWidth;
  final double cardHeight;

  const EventSwipeDeck({
    super.key,
    required this.events,
    required this.currentIndex,
    required this.onIndexChanged,
    this.onCardTap,
    this.onScanAttendance,
    this.onEdit,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  State<EventSwipeDeck> createState() => EventSwipeDeckState();
}

class EventSwipeDeckState extends State<EventSwipeDeck>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<Offset>? _offsetAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimating = false;

  // Configuration constants
  static const double _rotationFactor = 0.0007; // subtle rotation per pixel
  static const double _maxRotation = 0.12; // ~6.8 degrees max rotation
  static const double _restingRotationNext = 0.040; // ~2.3 degrees for 2nd card
  static const double _restingRotationThird =
      -0.040; // ~ -2.3 degrees for 3rd card
  static const double _restingScaleNext = 0.955;
  static const double _restingScaleThird = 0.915;
  static const double _restingOffsetNextY = -14.0;
  static const double _restingOffsetThirdY = -26.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(EventSwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.events != widget.events) {
      _precacheAdjacentBanners();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAdjacentBanners();
  }

  void _precacheAdjacentBanners() {
    if (!mounted || widget.events.isEmpty) return;

    void precacheIfValid(int idx) {
      if (idx >= 0 && idx < widget.events.length) {
        final banner = widget.events[idx].banner;
        if (banner != null && banner.trim().isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(banner), context)
              .catchError((_) {});
        }
      }
    }

    precacheIfValid(widget.currentIndex + 1);
    precacheIfValid(widget.currentIndex - 1);
    precacheIfValid(widget.currentIndex + 2);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_offsetAnimation != null && _offsetAnimation!.value.dx.abs() > 10) {
        final swipedRight = _offsetAnimation!.value.dx > 0;
        final newIndex =
            swipedRight ? widget.currentIndex + 1 : widget.currentIndex - 1;
        if (newIndex >= 0 && newIndex < widget.events.length) {
          widget.onIndexChanged(newIndex);
          HapticFeedback.selectionClick();
        }
      }
      setState(() {
        _dragOffset = Offset.zero;
        _isAnimating = false;
        _offsetAnimation = null;
      });
    }
  }

  /// Programmatic swipe left (navigates to previous event)
  void swipeLeft() {
    if (_isAnimating || _isDragging) return;
    if (widget.currentIndex <= 0) {
      _triggerBoundaryFeedback(isLeft: true);
      return;
    }
    _runSwipeAnimation(isRight: false);
  }

  /// Programmatic swipe right (navigates to next event)
  void swipeRight() {
    if (_isAnimating || _isDragging) return;
    if (widget.currentIndex >= widget.events.length - 1) {
      _triggerBoundaryFeedback(isLeft: false);
      return;
    }
    _runSwipeAnimation(isRight: true);
  }

  void _triggerBoundaryFeedback({required bool isLeft}) {
    HapticFeedback.lightImpact();
    final targetX = isLeft ? -30.0 : 30.0;
    _isAnimating = true;
    _offsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset(targetX, 0))
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(targetX, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_animController);

    _animController.forward(from: 0.0);
  }

  void _runSwipeAnimation({required bool isRight}) {
    final targetX =
        isRight ? widget.cardWidth + 120.0 : -(widget.cardWidth + 120.0);
    _isAnimating = true;
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy * 0.4),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward(from: 0.0);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isAnimating) return;
    _isDragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    double nextDx = _dragOffset.dx + details.delta.dx;
    double nextDy =
        _dragOffset.dy + details.delta.dy * 0.25; // damp vertical drag

    // Boundary resistance: swipe left at index 0 or swipe right at end
    final isAtStart = widget.currentIndex == 0 && nextDx < 0;
    final isAtEnd =
        widget.currentIndex == widget.events.length - 1 && nextDx > 0;

    if (isAtStart || isAtEnd) {
      nextDx = _dragOffset.dx + details.delta.dx * 0.25; // 75% resistance
    }

    setState(() {
      _dragOffset = Offset(nextDx, nextDy);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    _isDragging = false;

    final threshold = widget.cardWidth * 0.28;
    final velocityX = details.velocity.pixelsPerSecond.dx;

    final crossedThreshold = _dragOffset.dx.abs() > threshold;
    final flicked = velocityX.abs() > 650;

    final wantsRight = _dragOffset.dx > 0 || (flicked && velocityX > 0);
    final wantsLeft = _dragOffset.dx < 0 || (flicked && velocityX < 0);

    // Swipe Right -> Next Event
    if (wantsRight &&
        (crossedThreshold || flicked) &&
        widget.currentIndex < widget.events.length - 1) {
      _runSwipeAnimation(isRight: true);
      return;
    }

    // Swipe Left -> Previous Event
    if (wantsLeft && (crossedThreshold || flicked) && widget.currentIndex > 0) {
      _runSwipeAnimation(isRight: false);
      return;
    }

    // Cancelled drag or boundary bounce back
    _isAnimating = true;
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const SizedBox.shrink();
    }

    final disableMotion = MediaQuery.of(context).disableAnimations;
    final currentOffset =
        _offsetAnimation != null ? _offsetAnimation!.value : _dragOffset;

    // Drag progress from 0.0 to 1.0 based on current translation
    final threshold = widget.cardWidth * 0.28;
    final dragProgress = (currentOffset.dx.abs() / threshold).clamp(0.0, 1.0);
    final isDraggingLeft = currentOffset.dx < 0;

    // Determine candidate indices for background cards based on drag direction
    final int nextCardIndex;
    final int thirdCardIndex;

    if (currentOffset.dx > 0) {
      // Swiping right reveals next chronological events
      nextCardIndex = widget.currentIndex + 1;
      thirdCardIndex = widget.currentIndex + 2;
    } else if (currentOffset.dx < 0) {
      // Swiping left reveals previous events
      nextCardIndex = widget.currentIndex - 1;
      thirdCardIndex = widget.currentIndex - 2;
    } else {
      // Resting state: show next events if available, else previous
      if (widget.currentIndex + 1 < widget.events.length) {
        nextCardIndex = widget.currentIndex + 1;
        thirdCardIndex = widget.currentIndex + 2;
      } else {
        nextCardIndex = widget.currentIndex - 1;
        thirdCardIndex = widget.currentIndex - 2;
      }
    }

    final hasNextCard =
        nextCardIndex >= 0 && nextCardIndex < widget.events.length;
    final hasThirdCard =
        thirdCardIndex >= 0 && thirdCardIndex < widget.events.length;

    // Interpolate transforms for background cards as top card moves
    final double card2Scale;
    final double card2Offset;
    final double card2Rotation;

    final double card3Scale;
    final double card3Offset;
    final double card3Rotation;

    if (disableMotion) {
      card2Scale = _restingScaleNext;
      card2Offset = _restingOffsetNextY;
      card2Rotation = 0.0;
      card3Scale = _restingScaleThird;
      card3Offset = _restingOffsetThirdY;
      card3Rotation = 0.0;
    } else {
      // Card 2 moves toward front (scale 1.0, offset 0, rotation 0)
      card2Scale = lerpDouble(_restingScaleNext, 1.0, dragProgress);
      card2Offset = lerpDouble(_restingOffsetNextY, 0.0, dragProgress);
      final signRotation2 = isDraggingLeft ? -1.0 : 1.0;
      card2Rotation =
          lerpDouble(_restingRotationNext * signRotation2, 0.0, dragProgress);

      // Card 3 moves toward Card 2 position
      card3Scale =
          lerpDouble(_restingScaleThird, _restingScaleNext, dragProgress);
      card3Offset =
          lerpDouble(_restingOffsetThirdY, _restingOffsetNextY, dragProgress);
      final signRotation3 = isDraggingLeft ? 1.0 : -1.0;
      card3Rotation = lerpDouble(_restingRotationThird * signRotation3,
          _restingRotationNext * signRotation2, dragProgress);
    }

    // Active top card rotation
    final double topRotation = disableMotion
        ? 0.0
        : (currentOffset.dx * _rotationFactor)
            .clamp(-_maxRotation, _maxRotation);

    return SizedBox(
      width: widget.cardWidth,
      height: widget.cardHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // --- 3rd Card in Stack ---
          if (hasThirdCard)
            Positioned(
              top: card3Offset,
              child: Transform.rotate(
                angle: card3Rotation,
                child: Transform.scale(
                  scale: card3Scale,
                  child: EventDeckCard(
                    event: widget.events[thirdCardIndex],
                    isActive: false,
                    stackDepth: 2,
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                  ),
                ),
              ),
            ),

          // --- 2nd Card in Stack ---
          if (hasNextCard)
            Positioned(
              top: card2Offset,
              child: Transform.rotate(
                angle: card2Rotation,
                child: Transform.scale(
                  scale: card2Scale,
                  child: EventDeckCard(
                    event: widget.events[nextCardIndex],
                    isActive: false,
                    stackDepth: 1,
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                  ),
                ),
              ),
            ),

          // --- Top Active Card (Fully Interactive) ---
          Positioned(
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: Transform.translate(
                offset: currentOffset,
                child: Transform.rotate(
                  angle: topRotation,
                  child: EventDeckCard(
                    event: widget.events[widget.currentIndex],
                    isActive: true,
                    stackDepth: 0,
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    onTap: () => widget.onCardTap
                        ?.call(widget.events[widget.currentIndex]),
                    onScanAttendance: widget.onScanAttendance != null
                        ? () => widget.onScanAttendance!(
                            widget.events[widget.currentIndex])
                        : null,
                    onEdit: widget.onEdit != null
                        ? () =>
                            widget.onEdit!(widget.events[widget.currentIndex])
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
