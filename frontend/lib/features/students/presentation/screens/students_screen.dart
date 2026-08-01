import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../domain/entities/student_entity.dart';
import '../../providers/student_provider.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();
  String _selectedBranch = 'All';
  String _selectedYear = 'All';
  bool _searchVisible = false;

  final _branchFilters = ['All', 'CSE', 'CSE(DS)', 'CSE(AIML)', 'CSIT', 'ECE', 'CS(H)', 'ME', 'AIML', 'CE', 'IT', 'EN', 'CS'];
  final _yearFilters = ['All', '1', '2', '3', '4'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(
          title: 'STUDENTS',
          accentColor: AppColors.moduleStudents,
          actions: [
            IconButton(
              icon: Icon(
                _searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
                color: AppColors.primary,
              ),
              onPressed: () => setState(() => _searchVisible = !_searchVisible),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_searchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BrlTextField(
                  label: 'Search students...',
                  controller: _searchController,
                  prefix: const Icon(Icons.search, color: AppColors.onSurfaceSubtle, size: 18),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            _buildFilterChips(),
            const _BranchAnalyticsWidget(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  ref.invalidate(studentsProvider);
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: _buildStudentList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _branchFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _branchFilters[i] == _selectedBranch;
          return GestureDetector(
            onTap: () => setState(() => _selectedBranch = _branchFilters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.primary : null,
                color: isSelected ? null : AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.glassStroke,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8),
                ] : null,
              ),
              child: Text(
                _branchFilters[i],
                style: AppTextStyles.labelMd.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentList() {
    final studentsAsyncValue = ref.watch(studentsProvider);

    return studentsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) => Center(
        child: Text(
          'Error loading students: $error',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
        ),
      ),
      data: (students) {
        final filtered = students.where((s) {
          final matchesSearch = _searchController.text.isEmpty ||
              s.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              s.rollNumber.toLowerCase().contains(_searchController.text.toLowerCase());
          final matchesBranch = _selectedBranch == 'All' || s.branch == _selectedBranch;
          final matchesYear = _selectedYear == 'All' || s.year.toString() == _selectedYear;
          return matchesSearch && matchesBranch && matchesYear;
        }).toList();

        if (filtered.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.school_outlined,
            title: 'No Students Found',
            message: 'Try adjusting your search or filter criteria.',
            iconColor: AppColors.moduleStudents,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _StudentListItem(
            student: filtered[i],
            onTap: () => context.push('/students/${filtered[i].rollNumber}'),
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151929).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.glassStroke, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Students', style: AppTextStyles.headlineMd),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceSubtle),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Year', style: AppTextStyles.labelLg.copyWith(color: AppColors.onSurfaceMuted)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _yearFilters.map((year) {
                    final isSelected = _selectedYear == year;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => _selectedYear = year);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.accent : null,
                          color: isSelected ? null : AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppColors.glassStroke,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: AppColors.accentPink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ] : null,
                        ),
                        child: Text(
                          year == 'All' ? 'All Years' : 'Year $year',
                          style: AppTextStyles.labelMd.copyWith(
                            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Apply Filter', style: AppTextStyles.buttonLg.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentListItem extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onTap;
  const _StudentListItem({required this.student, required this.onTap});

  Color get _attendanceColor {
    final percentage = student.attendance;
    if (percentage >= 80) return AppColors.accentGreen;
    if (percentage >= 60) return AppColors.accentAmber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BrlGlassCard(
        borderColor: AppColors.glassStroke,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                          : '?',
                      style: AppTextStyles.labelLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (student.isPresent)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.glassStroke),
                        ),
                        child: Text(
                          student.rollNumber,
                          style: AppTextStyles.monoCode.copyWith(fontSize: 10, color: AppColors.onSurfaceMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.moduleStudents.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.moduleStudents.withOpacity(0.2)),
                        ),
                        child: Text(
                          '${student.branch} Y${student.year}',
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.moduleStudents, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _attendanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${student.attendance}%',
                    style: AppTextStyles.labelMd.copyWith(
                      color: _attendanceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _BranchAnalyticsWidget extends ConsumerWidget {
  const _BranchAnalyticsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsyncValue = ref.watch(studentsProvider);
    
    return studentsAsyncValue.when(
      data: (students) {
        if (students.isEmpty) return const SizedBox.shrink();

        final stats = <String, List<int>>{};
        for (final s in students) {
          if (!stats.containsKey(s.branch)) {
            stats[s.branch] = [0, 0];
          }
          stats[s.branch]![0] += 1;
          stats[s.branch]![1] += s.attendance;
        }

        final sortedBranches = stats.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                'Domain Analytics',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(
              height: 90,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: sortedBranches.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final branch = sortedBranches[index];
                  final total = stats[branch]![0];
                  final present = stats[branch]![1];
                  final averageAttendance = total == 0 ? 0.0 : (present / total);
                  final percentage = averageAttendance / 100.0;

                  Color progressColor = AppColors.error;
                  if (percentage >= 0.8) progressColor = AppColors.accentGreen;
                  else if (percentage >= 0.6) progressColor = AppColors.accentAmber;

                  return Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              branch,
                              style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                            ),
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: AppTextStyles.labelSm.copyWith(color: progressColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: percentage),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: AppColors.surface.withOpacity(0.5),
                                valueColor: AlwaysStoppedAnimation(progressColor),
                                minHeight: 6,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$total Students',
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted, fontSize: 10),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
