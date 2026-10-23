import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BrlAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;
  final Color? accentColor;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const BrlAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.leading,
    this.accentColor,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        .withValues(alpha: isDark ? 0.82 : 0.88);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final separatorColor = isDark ? AppColors.darkSeparator : AppColors.lightSeparator;
    final accent = accentColor ?? (isDark ? AppColors.darkAccent : AppColors.lightAccent);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              bottom: BorderSide(color: separatorColor, width: 0.5),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: centerTitle,
            title: Text(
              title,
              style: AppTextStyles.headlineSm.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: showBack
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: accent,
                      size: 18,
                    ),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                : leading,
            actions: actions,
            bottom: bottom,
          ),
        ),
      ),
    );
  }
}
