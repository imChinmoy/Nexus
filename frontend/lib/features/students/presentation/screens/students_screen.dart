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
        floatingActionButton: _buildFab(context),
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

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.addStudent),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.accentPink.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151929),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.glassStroke, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter by Year', style: AppTextStyles.headlineMd),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceSubtle),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.accent : null,
                          color: isSelected ? null : AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppColors.glassStroke,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: AppColors.accentPink.withOpacity(0.3), blurRadius: 8),
                          ] : null,
                        ),
                        child: Text(
                          year == 'All' ? 'All Years' : 'Year $year',
                          style: AppTextStyles.labelMd.copyWith(
                            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Apply Filter', style: AppTextStyles.buttonLg),
                  ),
                ),
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
    if (student.attendance >= 80) return AppColors.accentGreen;
    if (student.attendance >= 60) return AppColors.accentAmber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BrlGlassCard(
        borderColor: AppColors.moduleStudents.withOpacity(0.15),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  student.name.isNotEmpty
                      ? student.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                      : '?',
                  style: AppTextStyles.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(student.rollNumber, style: AppTextStyles.monoCode.copyWith(fontSize: 10)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.moduleStudents.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${student.branch} Y${student.year}',
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.moduleStudents),
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
                Text(
                  '${student.attendance}%',
                  style: AppTextStyles.labelLg.copyWith(color: _attendanceColor),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: student.attendance / 100),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: AppColors.surfaceGlass,
                          valueColor: AlwaysStoppedAnimation(_attendanceColor),
                          minHeight: 4,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}
