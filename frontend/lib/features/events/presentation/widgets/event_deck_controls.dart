import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EventDeckControls extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const EventDeckControls({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final canPrev = currentIndex > 0;
    final canNext = currentIndex < totalCount - 1;

    final formattedIndex = (currentIndex + 1).toString().padLeft(2, '0');
    final formattedTotal = totalCount.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Accessible Previous Button
          Semantics(
            label: 'Previous Event Card',
            button: true,
            enabled: canPrev,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: canPrev ? onPrevious : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: canPrev
                        ? (isDark
                            ? AppColors.darkElevatedSurface
                                .withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: canPrev
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08))
                          : Colors.transparent,
                      width: 0.8,
                    ),
                    boxShadow: canPrev
                        ? [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.25 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 26,
                    color: canPrev
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                  ),
                ),
              ),
            ),
          ),

          // Central Counter & Subtle Swipe Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkElevatedSurface.withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedIndex,
                  style: AppTextStyles.labelMd.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  ' / $formattedTotal',
                  style: AppTextStyles.labelMd.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe Deck',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Accessible Next Button
          Semantics(
            label: 'Next Event Card',
            button: true,
            enabled: canNext,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: canNext ? onNext : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: canNext
                        ? (isDark
                            ? AppColors.darkElevatedSurface
                                .withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: canNext
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08))
                          : Colors.transparent,
                      width: 0.8,
                    ),
                    boxShadow: canNext
                        ? [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.25 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 26,
                    color: canNext
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
