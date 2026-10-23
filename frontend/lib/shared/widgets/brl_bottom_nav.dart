import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Minimalist, modern floating pill HomeBar inspired by @jsav.design.
/// Features a dark capsule with a smooth-sliding circular white indicator,
/// high-contrast monochrome iconography, and subtle floating drop shadows.
class BrlBottomNav extends StatelessWidget {
  final Widget child;

  const BrlBottomNav({super.key, required this.child});

  static const _items = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: RouteConstants.dashboard,
    ),
    _NavItem(
      label: 'Events',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      route: RouteConstants.events,
    ),
    _NavItem(
      label: 'Scan',
      icon: Icons.qr_code_scanner_rounded,
      activeIcon: Icons.qr_code_scanner_rounded,
      route: '${RouteConstants.attendance}/qr-scan',
      isScanner: true,
    ),
    _NavItem(
      label: 'Students',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      route: RouteConstants.students,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.tune_rounded,
      activeIcon: Icons.tune_rounded,
      route: RouteConstants.settings,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].route)) return i;
    }
    if (location.startsWith(RouteConstants.attendance)) return 2;
    if (location.startsWith(RouteConstants.members)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final bool shouldPop = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Exit App?', style: AppTextStyles.headlineSm),
                content: Text(
                  'Are you sure you want to exit Nexus?',
                  style: AppTextStyles.bodyMd,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Exit',
                      style: TextStyle(
                        color: isDark ? AppColors.errorDark : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: child,
        bottomNavigationBar: Container(
          color: bgColor,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom + 4
                : 14,
          ),
          child: SizedBox(
            height: 64,
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _ModernHomeBar(
                  items: _items,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                  onItemTapped: (index, item) {
                    if (item.isScanner) {
                      HapticFeedback.lightImpact();
                      context.push(item.route);
                    } else {
                      HapticFeedback.selectionClick();
                      context.go(item.route);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool isScanner;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.isScanner = false,
  });
}

class _ModernHomeBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool isDark;
  final void Function(int index, _NavItem item) onItemTapped;

  const _ModernHomeBar({
    required this.items,
    required this.selectedIndex,
    required this.isDark,
    required this.onItemTapped,
  });

  static const double _barHeight = 64.0;
  static const double _verticalPadding = 6.0;
  static const double _horizontalPadding = 6.0;

  @override
  Widget build(BuildContext context) {
    // Pill capsule styling matching @jsav.design mockup
    final barBgColor = isDark ? const Color(0xFF16161A) : const Color(0xFF101012);
    final borderColor = isDark ? const Color(0x2EFFFFFF) : const Color(0x1F000000);

    return Container(
      height: _barHeight,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.20),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final itemWidth = totalWidth / items.length;
          final indicatorSize = constraints.maxHeight; // 52.0 (64 - 12)
          final indicatorLeft = selectedIndex * itemWidth + (itemWidth - indicatorSize) / 2;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Sliding Circular Active Indicator (Smooth pure white bubble)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.fastOutSlowIn,
                left: indicatorLeft,
                top: 0,
                child: Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // 2. Interactive Row of Icons
              Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: _HomeBarItemWidget(
                      item: item,
                      isSelected: isSelected,
                      onTap: () => onItemTapped(index, item),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeBarItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _HomeBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // When selected: pitch dark icon inside white circle
    // When unselected: clean white outline icon
    final targetColor = isSelected ? const Color(0xFF101012) : Colors.white.withValues(alpha: 0.90);

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 600),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Center(
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: TweenAnimationBuilder<Color?>(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOut,
                  tween: ColorTween(end: targetColor),
                  builder: (context, color, child) {
                    return Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: color,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

