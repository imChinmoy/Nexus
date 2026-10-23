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
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
      activeIcon: Icons.grid_view_rounded,
      route: RouteConstants.dashboard,
    ),
    _NavItem(
      label: 'Students',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      route: RouteConstants.students,
    ),
    _NavItem(
      label: 'Members',
      icon: Icons.group_outlined,
      activeIcon: Icons.group_rounded,
      route: RouteConstants.members,
    ),
    _NavItem(
      label: 'Events',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      route: RouteConstants.events,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      route: RouteConstants.settings,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        .withValues(alpha: isDark ? 0.85 : 0.92);
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
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                  height: 54,
                  child: Row(
                    children: List.generate(_items.length, (i) {
                      final isSelected = i == selectedIndex;
                      return Expanded(
                        child: _NavItemWidget(
                          item: _items[i],
                          isSelected: isSelected,
                          onTap: () => context.go(_items[i].route),
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

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
