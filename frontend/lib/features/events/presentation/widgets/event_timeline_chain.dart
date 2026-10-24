import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/event_entity.dart';

class EventTimelineChain extends StatefulWidget {
  final List<EventEntity> events;
  final int currentIndex;
  final ValueChanged<int> onNodeTap;

  const EventTimelineChain({
    super.key,
    required this.events,
    required this.currentIndex,
    required this.onNodeTap,
  });

  @override
  State<EventTimelineChain> createState() => _EventTimelineChainState();
}

class _EventTimelineChainState extends State<EventTimelineChain> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(EventTimelineChain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToActiveNode();
    }
  }

  void _scrollToActiveNode() {
    if (!_scrollController.hasClients || widget.events.isEmpty) return;
    const itemWidth = 92.0;
    final targetOffset = (widget.currentIndex * itemWidth) - 120.0;
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatNodeDate(DateTime date) {
    return DateFormat("MMM d, ''yy").format(date);
  }

  String _formatNodeTime(DateTime date) {
    if (EventEntity.isDateOnly(date)) {
      return 'All Day';
    }
    return DateFormat('h:mm a').format(date);
  }

  Color _getNodeStatusColor(EventEntity event, BuildContext context, bool isDark) {
    final status = event.effectiveStatus.toLowerCase();
    switch (status) {
      case 'ongoing':
        return isDark ? AppColors.successDark : AppColors.success;
      case 'upcoming':
        return isDark ? AppColors.warningDark : AppColors.warning;
      case 'completed':
      case 'ended':
        return isDark ? AppColors.darkAccent : AppColors.lightAccent;
      case 'cancelled':
      case 'archived':
        return isDark ? AppColors.errorDark : AppColors.error;
      default:
        return isDark ? AppColors.darkAccent : AppColors.lightAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final separatorColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkElevatedSurface.withValues(alpha: 0.45)
            : AppColors.lightSecondaryBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          width: 0.8,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.events.length, (index) {
              final event = widget.events[index];
              final isActive = index == widget.currentIndex;
              final isPast = index < widget.currentIndex;
              final statusColor = _getNodeStatusColor(event, context, isDark);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chain Node
                  Semantics(
                    label:
                        'Timeline node ${index + 1}: ${event.title}, date: ${_formatNodeDate(event.startDate)}, time: ${_formatNodeTime(event.startDate)}',
                    button: true,
                    selected: isActive,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (index != widget.currentIndex) {
                          HapticFeedback.selectionClick();
                          widget.onNodeTap(index);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? accent.withValues(alpha: isDark ? 0.20 : 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(
                                  color: accent.withValues(alpha: isDark ? 0.6 : 0.4),
                                  width: 1.0,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Node bead with outer glow when active
                            Container(
                              width: isActive ? 14 : 9,
                              height: isActive ? 14 : 9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? statusColor
                                    : (isPast
                                        ? statusColor.withValues(alpha: 0.6)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.25)
                                            : Colors.black.withValues(alpha: 0.22))),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: statusColor.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isActive
                                  ? Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 3),
                            // Date & Year
                            Text(
                              _formatNodeDate(event.startDate),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 9.5,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive
                                    ? (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary)
                                    : (isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary),
                              ),
                            ),
                            // Time
                            Text(
                              _formatNodeTime(event.startDate),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 8.5,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive
                                    ? (isDark ? accent : AppColors.lightAccent)
                                    : (isDark
                                        ? AppColors.darkTextTertiary.withValues(alpha: 0.7)
                                        : AppColors.lightTextTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Inter-node Chain Link
                  if (index < widget.events.length - 1)
                    Container(
                      width: 22,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: index < widget.currentIndex
                            ? accent.withValues(alpha: 0.55)
                            : separatorColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
