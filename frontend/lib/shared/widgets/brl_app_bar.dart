import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BrlAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? overline;
  final String? counterText;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;
  final Color? accentColor;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  const BrlAppBar({
    super.key,
    required this.title,
    this.overline,
    this.counterText,
    this.actions,
    this.showBack = false,
    this.leading,
    this.accentColor,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        72.0 + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        .withValues(alpha: isDark ? 0.85 : 0.90);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final accent = accentColor ?? (isDark ? AppColors.darkAccent : AppColors.lightAccent);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
          ),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (showBack) ...[
                    BrlHeaderIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 10),
                  ] else if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 10),
                  ],

                  // Title and Overline Branding (Matching Events Screen Signature Style)
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
                            Flexible(
                              child: Text(
                                overline ?? 'NEXUS • ${title.toUpperCase()}',
                                style: AppTextStyles.caption.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: AppTextStyles.headlineMd.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (counterText != null && counterText!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.25),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  counterText!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions Group
                  if (actions != null && actions!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < actions!.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          actions![i],
                        ],
                      ],
                    ),
                ],
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Apple-grade Frosted Glass Icon Button for Header Actions
class BrlHeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;
  final Color? iconColor;
  final Widget? badge;

  const BrlHeaderIconButton({
    super.key,
    this.icon,
    this.child,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    this.iconColor,
    this.badge,
  }) : assert(icon != null || child != null, 'Either icon or child must be provided');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isActive
                  ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? accent.withValues(alpha: 0.45)
                    : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.06)),
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                child ??
                    Icon(
                      icon!,
                      size: 19,
                      color: iconColor ?? (isActive ? accent : textPrimary.withValues(alpha: 0.82)),
                    ),
                if (badge != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: badge!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
