import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventsHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final int totalCount;
  final bool isSearching;
  final VoidCallback onToggleSearch;
  final VoidCallback onRefresh;
  final VoidCallback? onAddEvent;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const EventsHeaderBar({
    super.key,
    required this.totalCount,
    required this.isSearching,
    required this.onToggleSearch,
    required this.onRefresh,
    this.onAddEvent,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Size get preferredSize => Size.fromHeight(isSearching ? 120.0 : 72.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor =
        (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withValues(alpha: isDark ? 0.85 : 0.90);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
          ),
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 8, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Top Header Row: Branding, Title, Counter & Action Pills ---
              Row(
                children: [
                  // Title Group with Overline Branding
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NEXUS • EVENT DECK',
                              style: AppTextStyles.caption.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Events',
                              style: AppTextStyles.headlineMd.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                    alpha: isDark ? 0.16 : 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.25),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '$totalCount in deck',
                                style: AppTextStyles.caption.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions Group: Search, Refresh, and Add Event
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glass Search Toggle
                      _buildHeaderIconButton(
                        context: context,
                        icon: isSearching
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        tooltip: isSearching ? 'Close Search' : 'Search Events',
                        isActive: isSearching,
                        onTap: onToggleSearch,
                      ),
                      const SizedBox(width: 6),

                      // Glass Refresh Action
                      _buildHeaderIconButton(
                        context: context,
                        icon: Icons.refresh_rounded,
                        tooltip: 'Reload Events',
                        onTap: onRefresh,
                      ),

                      // Add Event Button for Admins
                      if (onAddEvent != null) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: onAddEvent,
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.darkAccent,
                                          const Color(0xFF0071E3)
                                        ]
                                      : [
                                          AppColors.lightAccent,
                                          const Color(0xFF005BB5)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Create',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // --- Animated Inline Search Field ---
              if (isSearching) ...[
                const SizedBox(height: 10),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkElevatedSurface.withValues(alpha: 0.9)
                        : AppColors.lightSecondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: onSearchChanged,
                    style: AppTextStyles.bodySm.copyWith(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by title, venue, or category...',
                      hintStyle:
                          AppTextStyles.bodySm.copyWith(color: textSecondary),
                      prefixIcon:
                          Icon(Icons.search_rounded, size: 18, color: accent),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                  : (isDark
                      ? AppColors.darkElevatedSurface.withValues(alpha: 0.7)
                      : AppColors.lightSecondaryBackground
                          .withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? accent.withValues(alpha: 0.5)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                width: 0.6,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive
                  ? accent
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
