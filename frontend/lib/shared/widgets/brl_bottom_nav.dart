import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BrlBottomNav extends StatelessWidget {
  final Widget child;

  const BrlBottomNav({super.key, required this.child});

  static const _items = [
    _NavItem(
      label: 'Ops',
      icon: Icons.space_dashboard_outlined,
      activeIcon: Icons.space_dashboard_rounded,
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
      icon: Icons.tune_outlined,
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
    final surfaceColor = (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        .withValues(alpha: isDark ? 0.90 : 0.95);
    final separatorColor = isDark ? AppColors.darkSeparator : AppColors.lightSeparator;

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
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(color: separatorColor, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 50,
                  child: Row(
                    children: List.generate(_items.length, (i) {
                      final item = _items[i];
                      final isSelected = i == selectedIndex;
                      return Expanded(
                        child: item.isScanner
                            ? _ScannerShortcutWidget(
                                item: item,
                                isSelected: isSelected,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push(item.route);
                                },
                              )
                            : _NavItemWidget(
                                item: item,
                                isSelected: isSelected,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  context.go(item.route);
                                },
                              ),
                      );
                    }),
                  ),
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

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final inactiveColor = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerShortcutWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScannerShortcutWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Semantics(
      label: 'Scan QR Shortcut',
      button: true,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  color: accent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Scan',
                  style: AppTextStyles.labelSm.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

