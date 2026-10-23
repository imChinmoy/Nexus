import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
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
    final accent = AppColors.accentOf(context);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrlAppBar(
          title: 'Students',
          actions: [
            IconButton(
              icon: Icon(
                _searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
                color: accent,
                size: 22,
              ),
              onPressed: () => setState(() => _searchVisible = !_searchVisible),
            ),
            IconButton(
              icon: Icon(Icons.tune_rounded, color: accent, size: 22),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_searchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: BrlTextField(
                  label: 'Search by name or roll number...',
                  controller: _searchController,
                  prefix: Icon(Icons.search, color: AppColors.textSecondaryOf(context), size: 18),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            _buildFilterChips(),
            const _BranchAnalyticsWidget(),
            Expanded(
              child: RefreshIndicator(
                color: accent,
                backgroundColor: AppColors.surfaceOf(context),
                onRefresh: () async {
                  ref.invalidate(studentsProvider);
                  await Future.delayed(const Duration(milliseconds: 600));
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
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _branchFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _branchFilters[i] == _selectedBranch;
          return GestureDetector(
            onTap: () => setState(() => _selectedBranch = _branchFilters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent
                    : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? accent : AppColors.borderOf(context),
                  width: 0.6,
                ),
              ),
              child: Center(
                child: Text(
                  _branchFilters[i],
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
                  ),
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
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.accentOf(context), strokeWidth: 2.5),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 44, color: AppColors.errorOf(context)),
              const SizedBox(height: 12),
              Text('Unable to load students', style: AppTextStyles.headlineSm),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
              ),
            ],
          ),
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
            message: 'Try adjusting your search query or filter options.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _StudentListItem(
            student: filtered[i],
            onTap: () => context.push('/students/${filtered[i].rollNumber}'),
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context).withValues(alpha: isDark ? 0.95 : 0.98),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: AppColors.borderOf(context), width: 0.6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiaryOf(context).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter Directory', style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: AppColors.textSecondaryOf(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ACADEMIC YEAR',
                      style: AppTextStyles.caption.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _yearFilters.map((year) {
                        final isSelected = _selectedYear == year;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => _selectedYear = year);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent
                                  : (isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? accent : AppColors.borderOf(context),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              year == 'All' ? 'All Years' : 'Year $year',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimaryOf(context),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    BrlButton(
                      label: 'Apply Filters',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    final percentage = student.attendance;
    final Color badgeColor;
    if (percentage >= 80) {
      badgeColor = AppColors.successOf(context);
    } else if (percentage >= 60) {
      badgeColor = AppColors.warningOf(context);
    } else {
      badgeColor = AppColors.errorOf(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = student.name.isNotEmpty
        ? student.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: BrlGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentOf(context).withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentOf(context).withValues(alpha: 0.3),
                      width: 0.6,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.accentOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (student.isPresent)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.successOf(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceOf(context), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        student.rollNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondaryOf(context),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
                      const SizedBox(width: 6),
                      Text(
                        '${student.branch} Y${student.year}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentOf(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Attendance Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${student.attendance}%',
                style: AppTextStyles.caption.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textTertiaryOf(context),
            ),
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
              padding: const EdgeInsets.fromLTRB(18, 6, 16, 4),
              child: Text(
                'DOMAIN ANALYTICS',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ),
            SizedBox(
              height: 84,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: sortedBranches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final branch = sortedBranches[index];
                  final total = stats[branch]![0];
                  final present = stats[branch]![1];
                  final averageAttendance = total == 0 ? 0.0 : (present / total);
                  final percentage = (averageAttendance / 100.0).clamp(0.0, 1.0);

                  final Color progressColor;
                  if (percentage >= 0.8) {
                    progressColor = AppColors.successOf(context);
                  } else if (percentage >= 0.6) {
                    progressColor = AppColors.warningOf(context);
                  } else {
                    progressColor = AppColors.errorOf(context);
                  }

                  return BrlGlassCard(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                branch,
                                style: AppTextStyles.labelMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: AppTextStyles.caption.copyWith(
                                  color: progressColor,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: AppColors.borderOf(context),
                              valueColor: AlwaysStoppedAnimation(progressColor),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$total students',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 10,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
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
