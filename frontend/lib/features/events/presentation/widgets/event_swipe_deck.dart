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

class EventSwipeDeckState extends State<EventSwipeDeck> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late ValueNotifier<Offset> _dragNotifier;
  Animation<Offset>? _offsetAnimation;
  bool _isDragging = false;
  bool _isAnimating = false;
  int _activeDirection = 0; // -1 for left (previous), 1 for right (next), 0 for resting

  // Tangible deck aesthetic constants (smooth continuous rotation)
  static const double _rotationFactor = 0.00095;
  static const double _maxRotation = 0.18; // ~10.3 degrees max rotation during drag
  static const double _restingRotationNext = 0.088; // ~5.0 degrees for 2nd card
  static const double _restingRotationThird = -0.082; // ~ -4.7 degrees for 3rd card
  static const double _restingScaleNext = 0.94;
  static const double _restingScaleThird = 0.88;
  static const double _restingOffsetNextY = -18.0;
  static const double _restingOffsetThirdY = -34.0;

  @override
  void initState() {
    super.initState();
    _dragNotifier = ValueNotifier<Offset>(Offset.zero);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_onAnimationTick)
     ..addStatusListener(_handleAnimationStatus);
  }

  void _onAnimationTick() {
    if (_offsetAnimation != null) {
      _dragNotifier.value = _offsetAnimation!.value;
    }
  }

  @override
  void didUpdateWidget(EventSwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex || oldWidget.events != widget.events) {
      _precacheAdjacentBanners();
      if (!_isAnimating && !_isDragging) {
        _dragNotifier.value = Offset.zero;
        _activeDirection = 0;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAdjacentBanners();
  }

  void _precacheAdjacentBanners() {
    if (!mounted || widget.events.isEmpty) return;

    final targetWidth = (widget.cardWidth * 1.8).round().clamp(300, 1200);
    final targetHeight = (widget.cardHeight * 1.8).round().clamp(400, 1600);

    void precacheIfValid(int idx) {
      if (idx >= 0 && idx < widget.events.length) {
        final banner = widget.events[idx].banner;
        if (banner != null && banner.trim().isNotEmpty) {
          precacheImage(
            CachedNetworkImageProvider(
              banner,
              maxWidth: targetWidth,
              maxHeight: targetHeight,
            ),
            context,
          ).catchError((_) {});
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
    _dragNotifier.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final finalOffset = _offsetAnimation?.value ?? Offset.zero;
      final wasSwipeOut = finalOffset.dx.abs() > (widget.cardWidth * 0.4);

      if (wasSwipeOut) {
        final swipedRight = finalOffset.dx > 0;
        final newIndex = swipedRight ? widget.currentIndex + 1 : widget.currentIndex - 1;

        // Reset local state FIRST so when parent builds with new currentIndex,
        // the deck is cleanly resting at Offset.zero with zero-frame hitch!
        _dragNotifier.value = Offset.zero;
        _offsetAnimation = null;
        _isAnimating = false;
        _activeDirection = 0;

        if (newIndex >= 0 && newIndex < widget.events.length) {
          widget.onIndexChanged(newIndex);
          HapticFeedback.selectionClick();
        }
      } else {
        _dragNotifier.value = Offset.zero;
        _offsetAnimation = null;
        _isAnimating = false;
        _activeDirection = 0;
      }
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
    final targetX = isLeft ? -24.0 : 24.0;
    _isAnimating = true;
    _activeDirection = isLeft ? -1 : 1;
    _offsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset(targetX, 0))
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(targetX, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 55,
      ),
    ]).animate(_animController);

    _animController.duration = const Duration(milliseconds: 200);
    _animController.forward(from: 0.0);
  }

  void _runSwipeAnimation({required bool isRight, double velocityX = 0.0}) {
    final targetX = isRight ? widget.cardWidth + 140.0 : -(widget.cardWidth + 140.0);
    _isAnimating = true;
    _activeDirection = isRight ? 1 : -1;

    // Fluid velocity-adaptive duration
    final speed = velocityX.abs();
    final animMs = speed > 1000 ? 190 : (speed > 600 ? 220 : 250);

    _offsetAnimation = Tween<Offset>(
      begin: _dragNotifier.value,
      end: Offset(targetX, _dragNotifier.value.dy * 0.25),
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_animController);

    _animController.duration = Duration(milliseconds: animMs);
    _animController.forward(from: 0.0);
  }

  void _runSnapBackAnimation() {
    _isAnimating = true;
    _offsetAnimation = Tween<Offset>(
      begin: _dragNotifier.value,
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_animController);

    _animController.duration = const Duration(milliseconds: 220);
    _animController.forward(from: 0.0);
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isAnimating) {
      // If returning to center, smoothly catch the card without drop
      if (_offsetAnimation != null && _animController.isAnimating) {
        final isFlingingAway = _offsetAnimation!.value.dx.abs() > widget.cardWidth * 0.4;
        if (!isFlingingAway) {
          _animController.stop();
          _isAnimating = false;
        } else {
          return;
        }
      } else {
        return;
      }
    }
    _isDragging = true;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    double deltaX = details.delta.dx;
    final double currentDx = _dragNotifier.value.dx;

    // Fluid boundary resistance: only damp outward motion beyond deck boundaries
    final isTryingToSwipePastStart = widget.currentIndex == 0 && (currentDx + deltaX) < 0;
    final isTryingToSwipePastEnd =
        widget.currentIndex == widget.events.length - 1 && (currentDx + deltaX) > 0;

    if (isTryingToSwipePastStart && deltaX < 0) {
      deltaX *= 0.25;
    } else if (isTryingToSwipePastEnd && deltaX > 0) {
      deltaX *= 0.25;
    }

    final double nextDx = currentDx + deltaX;
    final double nextDy = _dragNotifier.value.dy + details.delta.dy * 0.18;

    // Lock active direction based on displacement once threshold passed
    if (nextDx > 3) {
      _activeDirection = 1;
    } else if (nextDx < -3) {
      _activeDirection = -1;
    }

    _dragNotifier.value = Offset(nextDx, nextDy);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    _isDragging = false;

    final threshold = widget.cardWidth * 0.22;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final currentDx = _dragNotifier.value.dx;

    final isFastFlickRight = velocityX > 450 && currentDx >= -30;
    final isFastFlickLeft = velocityX < -450 && currentDx <= 30;

    final isThresholdRight = currentDx > threshold && velocityX > -300;
    final isThresholdLeft = currentDx < -threshold && velocityX < 300;

    final shouldSwipeRight =
        (isThresholdRight || isFastFlickRight) && widget.currentIndex < widget.events.length - 1;
    final shouldSwipeLeft =
        (isThresholdLeft || isFastFlickLeft) && widget.currentIndex > 0;

    if (shouldSwipeRight) {
      _runSwipeAnimation(isRight: true, velocityX: velocityX);
      return;
    }

    if (shouldSwipeLeft) {
      _runSwipeAnimation(isRight: false, velocityX: velocityX);
      return;
    }

    // Cancel / smooth return to center
    _runSnapBackAnimation();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const SizedBox.shrink();
    }

    final disableMotion = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      width: widget.cardWidth,
      height: widget.cardHeight,
      child: ValueListenableBuilder<Offset>(
        valueListenable: _dragNotifier,
        builder: (context, currentOffset, _) {
          // Smooth progressive interpolation over 70% of card width
          final maxRange = widget.cardWidth * 0.70;
          final rawProgress = (currentOffset.dx.abs() / maxRange).clamp(0.0, 1.0);
          final dragProgress = Curves.easeOutCubic.transform(rawProgress);

          // Stable background card indexing with direction lock during snap-back
          final int nextCardIndex;
          final int thirdCardIndex;

          final effectiveDir = _activeDirection != 0
              ? _activeDirection
              : (currentOffset.dx > 2 ? 1 : (currentOffset.dx < -2 ? -1 : 0));

          if (effectiveDir < 0 && widget.currentIndex > 0) {
            nextCardIndex = widget.currentIndex - 1;
            thirdCardIndex = widget.currentIndex - 2;
          } else {
            nextCardIndex = widget.currentIndex + 1;
            thirdCardIndex = widget.currentIndex + 2;
          }

          final hasNextCard = nextCardIndex >= 0 && nextCardIndex < widget.events.length;
          final hasThirdCard = thirdCardIndex >= 0 && thirdCardIndex < widget.events.length;

          // Continuous interpolated transforms without jarring sign flips
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
            // Card 2 glides smoothly to active foreground position
            card2Scale = lerpDouble(_restingScaleNext, 1.0, dragProgress);
            card2Offset = lerpDouble(_restingOffsetNextY, 0.0, dragProgress);
            card2Rotation = lerpDouble(_restingRotationNext, 0.0, dragProgress);

            // Card 3 moves smoothly into Card 2's resting position
            card3Scale = lerpDouble(_restingScaleThird, _restingScaleNext, dragProgress);
            card3Offset = lerpDouble(_restingOffsetThirdY, _restingOffsetNextY, dragProgress);
            card3Rotation = lerpDouble(_restingRotationThird, _restingRotationNext, dragProgress);
          }

          // Active top card rotation
          final double topRotation = disableMotion
              ? 0.0
              : (currentOffset.dx * _rotationFactor).clamp(-_maxRotation, _maxRotation);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // --- 3rd Card in Stack (Deepest Layer, RepaintBoundary isolated) ---
              if (hasThirdCard)
                Positioned(
                  top: card3Offset,
                  child: RepaintBoundary(
                    child: Transform.rotate(
                      angle: card3Rotation,
                      child: Transform.scale(
                        scale: card3Scale,
                        child: EventDeckCard(
                          key: ValueKey('card-stack-3-${widget.events[thirdCardIndex].id}'),
                          event: widget.events[thirdCardIndex],
                          isActive: false,
                          stackDepth: 2,
                          width: widget.cardWidth,
                          height: widget.cardHeight,
                        ),
                      ),
                    ),
                  ),
                ),

              // --- 2nd Card in Stack (Intermediate Layer, RepaintBoundary isolated) ---
              if (hasNextCard)
                Positioned(
                  top: card2Offset,
                  child: RepaintBoundary(
                    child: Transform.rotate(
                      angle: card2Rotation,
                      child: Transform.scale(
                        scale: card2Scale,
                        child: EventDeckCard(
                          key: ValueKey('card-stack-2-${widget.events[nextCardIndex].id}'),
                          event: widget.events[nextCardIndex],
                          isActive: false,
                          stackDepth: 1,
                          width: widget.cardWidth,
                          height: widget.cardHeight,
                        ),
                      ),
                    ),
                  ),
                ),

              // --- Top Active Card (Interactive Layer, RepaintBoundary isolated) ---
              Positioned(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  child: RepaintBoundary(
                    child: Transform.translate(
                      offset: currentOffset,
                      child: Transform.rotate(
                        angle: topRotation,
                        child: EventDeckCard(
                          key: ValueKey('card-top-${widget.events[widget.currentIndex].id}'),
                          event: widget.events[widget.currentIndex],
                          isActive: true,
                          stackDepth: 0,
                          width: widget.cardWidth,
                          height: widget.cardHeight,
                          onTap: () => widget.onCardTap?.call(widget.events[widget.currentIndex]),
                          onScanAttendance: widget.onScanAttendance != null
                              ? () => widget.onScanAttendance!(widget.events[widget.currentIndex])
                              : null,
                          onEdit: widget.onEdit != null
                              ? () => widget.onEdit!(widget.events[widget.currentIndex])
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
