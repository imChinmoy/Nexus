import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../students/providers/student_provider.dart';

class RecentAttendanceScreen extends ConsumerWidget {
  const RecentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'RECENT ATTENDANCE',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history_rounded, size: 64, color: AppColors.onSurfaceMuted),
                    const SizedBox(height: 16),
                    Text(
                      'No recent attendance',
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                ref.invalidate(studentsProvider);
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: presentStudents.length,
                itemBuilder: (context, index) {
                  final student = presentStudents[index];
                  String timeString = '';
                  if (student.updatedAt != null) {
                    final time = student.updatedAt!;
                    timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }

                  return GestureDetector(
                    onTap: () => context.push('/students/${student.rollNumber}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGlass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.glassStroke),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassStroke),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.onSurfaceMuted,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student.rollNumber,
                                  style: AppTextStyles.labelSm,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const NeonBadge(
                                label: 'PRESENT',
                                type: NeonBadgeType.success,
                              ),
                              if (timeString.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  timeString,
                                  style: AppTextStyles.labelSm,
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.moduleAttendance),
          ),
          orElse: () => Center(
            child: Text(
              'Failed to load recent attendance',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}
