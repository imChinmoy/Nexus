import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../students/providers/student_provider.dart';

class RecentAttendanceScreen extends ConsumerWidget {
  const RecentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final studentsAsync = ref.watch(studentsProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Recent Attendance',
          showBack: true,
        ),
        body: studentsAsync.maybeWhen(
          data: (students) {
            final presentStudents = students.where((s) => s.isPresent).toList();
            presentStudents.sort((a, b) {
              if (a.updatedAt == null && b.updatedAt == null) return 0;
              if (a.updatedAt == null) return 1;
              if (b.updatedAt == null) return -1;
              return b.updatedAt!.compareTo(a.updatedAt!);
            });

            if (presentStudents.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 54,
                        color: textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Recent Attendance',
                        style: AppTextStyles.headlineSm,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Students marked present at an event gate will appear here in chronological order.',
                        style: AppTextStyles.bodyMd.copyWith(color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: accent,
              backgroundColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
              onRefresh: () async {
                ref.invalidate(studentsProvider);
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: presentStudents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final student = presentStudents[index];
                  String timeString = '';
                  if (student.updatedAt != null) {
                    final time = student.updatedAt!;
                    timeString =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }

                  return BrlGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => context.push('/students/${student.rollNumber}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          child: Text(
                            student.name.isNotEmpty
                                ? student.name.substring(0, 1).toUpperCase()
                                : 'S',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${student.rollNumber} • ${student.branch}',
                                style: AppTextStyles.caption.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const NeonBadge(
                              label: 'Present',
                              type: NeonBadgeType.success,
                            ),
                            if (timeString.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                timeString,
                                style: AppTextStyles.caption.copyWith(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          orElse: () => Center(
            child: Text(
              'Failed to load recent attendance',
              style: AppTextStyles.bodyMd.copyWith(
                color: isDark ? AppColors.errorDark : AppColors.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
