import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/constants/route_constants.dart';

class BrlBottomNav extends StatelessWidget {
  final Widget child;

  const BrlBottomNav({super.key, required this.child});

  static const _items = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.grid_view_rounded,
      route: RouteConstants.dashboard,
      gradient: AppGradients.primary,
    ),
    _NavItem(
      label: 'Students',
      icon: Icons.school_rounded,
      route: RouteConstants.students,
      gradient: AppGradients.primary,
    ),
    _NavItem(
      label: 'Members',
      icon: Icons.group_rounded,
      route: RouteConstants.members,
      gradient: AppGradients.secondary,
    ),
    _NavItem(
      label: 'Events',
      icon: Icons.event_rounded,
      route: RouteConstants.events,
      gradient: AppGradients.accent,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_rounded,
      route: RouteConstants.settings,
      gradient: AppGradients.primary,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final bool shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1F32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.glassStroke, width: 1),
                ),
                title: const Text(
                  'Exit App?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: const Text(
                  'Are you sure you want to exit Nexus?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.onSurfaceSubtle),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
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
              color: const Color(0x1A0A0F1E),
              border: Border(
                top: BorderSide(color: AppColors.glassStroke, width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 60,
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
  final String route;
  final LinearGradient gradient;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.gradient,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradient.colors.first.withOpacity(0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 8),
            isSelected
                ? ShaderMask(
                    shaderCallback: (bounds) => item.gradient.createShader(bounds),
                    child: Icon(item.icon, color: Colors.white, size: 22),
                  )
                : Icon(item.icon, color: AppColors.onSurfaceSubtle, size: 22),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? item.gradient.colors.first
                    : AppColors.onSurfaceSubtle,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
