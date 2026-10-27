import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Interactive draggable floating action button that morphs smoothly into the
/// Nexus Org Network control deck (title, member count, search, domain filters).
///
/// Supports:
/// - Smooth touch-tracking drag with edge-snapping on release
/// - Viewport & safe-area boundary constraints
/// - Seamless container morphing (interpolating rect, corner radius, surface elevation)
/// - Staggered fade/slide content reveal
/// - Scrim tap dismissal, close button dismissal, and system back support
/// - Light & Dark theme support
/// - Reduced-motion accessibility preferences
class DraggableOrgNetworkFab extends StatefulWidget {
  final int memberCount;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedDomain;
  final ValueChanged<String> onDomainChanged;
  final List<String> domains;
  final IconData Function(String domain) getDomainIcon;
  final bool isDark;
  final bool initialExpanded;

  const DraggableOrgNetworkFab({
    super.key,
    required this.memberCount,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedDomain,
    required this.onDomainChanged,
    required this.domains,
    required this.getDomainIcon,
    required this.isDark,
    this.initialExpanded = false,
  });

  @override
  State<DraggableOrgNetworkFab> createState() => DraggableOrgNetworkFabState();
}

class DraggableOrgNetworkFabState extends State<DraggableOrgNetworkFab>
    with TickerProviderStateMixin {
  // Collapsed Capsule Dimensions
  static const double collapsedWidth = 172.0;
  static const double collapsedHeight = 52.0;
  static const double collapsedRadius = 26.0;

  // Animation Controllers
  late final AnimationController _morphController;
  late final AnimationController _pressScaleController;
  late final AnimationController _snapController;
  late final AnimationController _pulseController;

  late Animation<Offset> _snapAnimation;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  // Position state (within parent Stack)
  Offset? _position;
  double _relativeX = 0.92;
  double _relativeY = 0.02;
  BoxConstraints? _lastConstraints;

  // Gesture tracking
  bool _isDragging = false;
  double _dragTotalDistance = 0.0;
  bool _isExpanded = false;

  bool get isExpanded => _isExpanded;
  bool get isDragging => _isDragging;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchFocusNode = FocusNode();

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _pressScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _snapAnimation = const AlwaysStoppedAnimation(Offset.zero);
    _snapController.addListener(_onSnapTick);

    if (widget.initialExpanded) {
      _isExpanded = true;
      _morphController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant DraggableOrgNetworkFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text &&
        !_searchFocusNode.hasFocus) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _snapController.removeListener(_onSnapTick);
    _snapController.dispose();
    _morphController.dispose();
    _pressScaleController.dispose();
    _pulseController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    setState(() {
      _position = _snapAnimation.value;
    });
  }

  void expand() {
    if (_isExpanded || _morphController.isAnimating) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = true;
    });

    final disableMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableMotion) {
      _morphController.value = 1.0;
    } else {
      _morphController.forward();
    }
  }

  void collapse() {
    if (!_isExpanded && _morphController.isDismissed) return;
    HapticFeedback.lightImpact();
    _searchFocusNode.unfocus();
    setState(() {
      _isExpanded = false;
    });

    final disableMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableMotion) {
      _morphController.value = 0.0;
    } else {
      _morphController.reverse();
    }
  }

  void _reconcilePosition(BoxConstraints constraints) {
    const minX = 14.0;
    final maxX = (constraints.maxWidth - collapsedWidth - 14.0)
        .clamp(minX, double.infinity);
    const minY = 10.0;
    final maxY = (constraints.maxHeight - collapsedHeight - 80.0)
        .clamp(minY, double.infinity);

    if (_position == null) {
      // Default to top-right corner with comfortable clearance
      _position = Offset(maxX, minY + 6.0);
      _relativeX =
          (maxX - minX) > 0 ? (_position!.dx - minX) / (maxX - minX) : 1.0;
      _relativeY =
          (maxY - minY) > 0 ? (_position!.dy - minY) / (maxY - minY) : 0.0;
    } else if (_lastConstraints != null &&
        (_lastConstraints!.maxWidth != constraints.maxWidth ||
            _lastConstraints!.maxHeight != constraints.maxHeight)) {
      final newX = (minX + _relativeX * (maxX - minX)).clamp(minX, maxX);
      final newY = (minY + _relativeY * (maxY - minY)).clamp(minY, maxY);
      _position = Offset(newX, newY);
    } else {
      final clampedX = _position!.dx.clamp(minX, maxX);
      final clampedY = _position!.dy.clamp(minY, maxY);
      _position = Offset(clampedX, clampedY);
    }
    _lastConstraints = constraints;
  }

  void _snapToEdge(BoxConstraints constraints) {
    const minX = 14.0;
    final maxX = (constraints.maxWidth - collapsedWidth - 14.0)
        .clamp(minX, double.infinity);
    const minY = 10.0;
    final maxY = (constraints.maxHeight - collapsedHeight - 80.0)
        .clamp(minY, double.infinity);

    final centerX = _position!.dx + (collapsedWidth / 2.0);
    final targetX = (centerX < constraints.maxWidth / 2.0) ? minX : maxX;
    var targetY = _position!.dy.clamp(minY, maxY);

    // Keep clear of floating zoom HUD at bottom-right (~220px tall)
    if (targetX == maxX && targetY > constraints.maxHeight - 240.0) {
      targetY = (constraints.maxHeight - 250.0).clamp(minY, maxY);
    }

    final target = Offset(targetX, targetY);
    final disableMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableMotion) {
      setState(() {
        _position = target;
        _relativeX =
            (maxX - minX) > 0 ? (target.dx - minX) / (maxX - minX) : 0.0;
        _relativeY =
            (maxY - minY) > 0 ? (target.dy - minY) / (maxY - minY) : 0.0;
      });
      return;
    }

    _snapAnimation = Tween<Offset>(begin: _position, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0.0).then((_) {
      if (mounted) {
        _relativeX =
            (maxX - minX) > 0 ? (target.dx - minX) / (maxX - minX) : 0.0;
        _relativeY =
            (maxY - minY) > 0 ? (target.dy - minY) / (maxY - minY) : 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        _reconcilePosition(constraints);

        final expandedWidth = (constraints.maxWidth - 28.0).clamp(320.0, 520.0);
        final expandedHeight = (170.0).clamp(140.0,
            (constraints.maxHeight - 24.0).clamp(140.0, double.infinity));
        const expandedRadius = 24.0;

        final collapsedRect = Rect.fromLTWH(
          _position!.dx,
          _position!.dy,
          collapsedWidth,
          collapsedHeight,
        );

        final expandedX = (constraints.maxWidth - expandedWidth) / 2.0;
        const expandedY = 10.0;
        final expandedRect = Rect.fromLTWH(
          expandedX,
          expandedY,
          expandedWidth,
          expandedHeight,
        );

        return PopScope(
          canPop: !_isExpanded && _morphController.isDismissed,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_isExpanded || _morphController.value > 0) {
              collapse();
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _morphController,
              _pressScaleController,
              _pulseController,
            ]),
            builder: (context, _) {
              final double t =
                  Curves.easeInOutCubic.transform(_morphController.value);
              final currentRect = Rect.lerp(collapsedRect, expandedRect, t)!;
              final currentRadius =
                  ui.lerpDouble(collapsedRadius, expandedRadius, t)!;

              // Scale feedback when pressed in collapsed mode
              final pressScale =
                  1.0 - (0.06 * _pressScaleController.value * (1.0 - t));

              final surfaceColor = widget.isDark
                  ? Color.lerp(
                      const Color(0xE6141420), const Color(0xD912121B), t)!
                  : Color.lerp(
                      const Color(0xF7FFFFFF), const Color(0xF5FFFFFF), t)!;

              final borderColor = widget.isDark
                  ? const Color(0x38FFFFFF)
                  : const Color(0x1F000000);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Dismissal Scrim (Fades in over graph when expanded)
                  if (_morphController.value > 0.0)
                    Positioned.fill(
                      child: GestureDetector(
                        key: const Key('org_fab_scrim'),
                        behavior: HitTestBehavior.opaque,
                        onTap: collapse,
                        child: Container(
                          color: Colors.black.withValues(
                            alpha: (widget.isDark ? 0.45 : 0.22) * t,
                          ),
                        ),
                      ),
                    ),

                  // 2. Morphing Container Card (Transforms between FAB & Network Deck)
                  Positioned.fromRect(
                    rect: currentRect,
                    child: Transform.scale(
                      scale: pressScale,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) {
                          if (!_isExpanded && _morphController.isDismissed) {
                            _pressScaleController.forward();
                          }
                        },
                        onTapUp: (_) {
                          _pressScaleController.reverse();
                        },
                        onTapCancel: () {
                          _pressScaleController.reverse();
                        },
                        onTap: () {
                          if (!_isExpanded && _morphController.isDismissed) {
                            expand();
                          }
                        },
                        onPanStart: (details) {
                          if (_isExpanded || _morphController.value > 0) return;
                          _snapController.stop();
                          _isDragging = true;
                          _dragTotalDistance = 0.0;
                        },
                        onPanUpdate: (details) {
                          if (_isExpanded || _morphController.value > 0) return;
                          _dragTotalDistance += details.delta.distance;
                          const minX = 14.0;
                          final maxX =
                              (constraints.maxWidth - collapsedWidth - 14.0)
                                  .clamp(minX, double.infinity);
                          const minY = 10.0;
                          final maxY =
                              (constraints.maxHeight - collapsedHeight - 80.0)
                                  .clamp(minY, double.infinity);

                          setState(() {
                            _position = Offset(
                              (_position!.dx + details.delta.dx)
                                  .clamp(minX, maxX),
                              (_position!.dy + details.delta.dy)
                                  .clamp(minY, maxY),
                            );
                            _relativeX = (maxX - minX) > 0
                                ? (_position!.dx - minX) / (maxX - minX)
                                : 0.0;
                            _relativeY = (maxY - minY) > 0
                                ? (_position!.dy - minY) / (maxY - minY)
                                : 0.0;
                          });
                        },
                        onPanEnd: (details) {
                          if (_isExpanded || _morphController.value > 0) return;
                          _isDragging = false;
                          _pressScaleController.reverse();
                          if (_dragTotalDistance > 7.0) {
                            _snapToEdge(constraints);
                          } else {
                            expand();
                          }
                        },
                        onPanCancel: () {
                          _isDragging = false;
                          _pressScaleController.reverse();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(currentRadius),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              width: currentRect.width,
                              height: currentRect.height,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius:
                                    BorderRadius.circular(currentRadius),
                                border:
                                    Border.all(color: borderColor, width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: widget.isDark
                                          ? (0.40 + 0.10 * t)
                                          : (0.10 + 0.05 * t),
                                    ),
                                    blurRadius: 20 + 8 * t,
                                    offset: Offset(0, 4 + 4 * t),
                                  ),
                                  if (widget.isDark)
                                    BoxShadow(
                                      color: accent.withValues(
                                          alpha: 0.12 * (1.0 - 0.5 * t)),
                                      blurRadius: 14,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                fit: StackFit.expand,
                                children: [
                                  // A. Collapsed Content (fades out during initial expansion)
                                  if (t < 0.38)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity:
                                            ((0.38 - t) / 0.38).clamp(0.0, 1.0),
                                        child: _buildCollapsedContent(
                                            accent, widget.isDark),
                                      ),
                                    ),

                                  // B. Expanded Deck Content (reveals smoothly with staggered slide)
                                  if (t > 0.12)
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      width: expandedWidth,
                                      height: expandedHeight,
                                      child: Opacity(
                                        opacity:
                                            ((t - 0.12) / 0.88).clamp(0.0, 1.0),
                                        child: Transform.translate(
                                          offset: Offset(
                                            0,
                                            (1.0 -
                                                    ((t - 0.12) / 0.88)
                                                        .clamp(0.0, 1.0)) *
                                                10.0,
                                          ),
                                          child: _buildExpandedContent(
                                              accent, widget.isDark),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
      },
    );
  }

  // ---------------------------------------------------------------------------
  // COLLAPSED NETWORK FAB
  // ---------------------------------------------------------------------------
  Widget _buildCollapsedContent(Color accent, bool isDark) {
    return Semantics(
      key: const Key('draggable_org_fab'),
      label:
          'Open organization network controls. ${widget.memberCount} members.',
      button: true,
      child: Tooltip(
        message: 'Open Org Network Controls',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Distinctive Network Hub Orb
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),

              // 2. Member Count Badge & Brand Label
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing live green indicator
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF34C759).withValues(
                                    alpha: 0.5 + 0.4 * _pulseController.value,
                                  ),
                                  blurRadius: 4 + 2 * _pulseController.value,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.memberCount > 0
                                ? '${widget.memberCount} Members'
                                : 'Org Network',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ORG NETWORK',
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 10,
                            color: accent.withValues(alpha: 0.85),
                          ),
                        ],
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

  // ---------------------------------------------------------------------------
  // EXPANDED CONTROL DECK
  // ---------------------------------------------------------------------------
  Widget _buildExpandedContent(Color accent, bool isDark) {
    return Semantics(
      label: 'Organization network controls',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Branding, Live Metric, and Integrated Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, const Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.hub_rounded,
                            size: 17, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXUS ORG NETWORK',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              'Interactive Society Hierarchy Graph',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x38222234)
                            : const Color(0x1F000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0x2EFFFFFF)
                              : const Color(0x14000000),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Color(0xFF34C759),
                                    blurRadius: 4,
                                    spreadRadius: 1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.memberCount} Members',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Integrated Close Action
                    Semantics(
                      label: 'Close network controls',
                      button: true,
                      child: Tooltip(
                        message: 'Close network controls',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const Key('close_org_network_panel'),
                            onTap: collapse,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x33FFFFFF)
                                    : const Color(0x14000000),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.lightTextPrimary,
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
            const SizedBox(height: 10),

            // 2. Search Field
            Container(
              height: 38,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0x551E1E2C) : const Color(0x73F0F0F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0x26FFFFFF)
                      : const Color(0x1A000000),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 17, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (val) {
                        widget.onSearchChanged(val.trim());
                      },
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search members, roles, or domains...',
                        hintStyle: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (widget.searchQuery.isNotEmpty)
                    GestureDetector(
                      key: const Key('clear_search_button'),
                      onTap: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.clear_rounded,
                          size: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Domain Filters Strip
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.domains.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (context, i) {
                  final d = widget.domains[i];
                  final isSelected = widget.selectedDomain == d;
                  final icon = widget.getDomainIcon(d);

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onDomainChanged(d);
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [accent, const Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark
                                ? const Color(0x38222234)
                                : const Color(0x1FEEEEF4)),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? accent.withValues(alpha: 0.9)
                              : (isDark
                                  ? const Color(0x1FFFFFFF)
                                  : const Color(0x14000000)),
                          width: 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 12,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white60
                                    : AppColors.lightTextSecondary),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            d,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
