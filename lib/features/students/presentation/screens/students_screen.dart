import 'dart:ui';
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
import '../../../../shared/widgets/neon_badge.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/brl_app_bar.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _searchVisible = false;

  final _filters = ['All', 'CSE', 'ECE', 'ME', 'EEE', 'Year 1', 'Year 2', 'Year 3', 'Year 4'];

  final _demoStudents = List.generate(12, (i) => _StudentData(
    name: ['Arjun Kumar', 'Priya Singh', 'Rahul Dev', 'Meena Nair', 'Vikram Patel', 'Sneha Rao',
           'Karthik M', 'Anitha S', 'Deepak J', 'Lakshmi P', 'Suresh K', 'Divya T'][i],
    roll: ['21CS001', '21CS042', '21EC018', '22ME007', '21CS099', '22CS034',
           '21EC077', '22CS011', '21ME045', '21CS067', '22EC009', '21CS088'][i],
    branch: ['CSE', 'CSE', 'ECE', 'ME', 'CSE', 'CSE', 'ECE', 'CSE', 'ME', 'CSE', 'ECE', 'CSE'][i],
    year: [3, 3, 3, 2, 3, 2, 3, 2, 3, 3, 2, 3][i],
    attendance: [92, 87, 65, 100, 78, 95, 43, 88, 71, 90, 56, 82][i],
  ));

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
              onPressed: () {},
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
                onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
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
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _filters[i] == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
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
                _filters[i],
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
    final filtered = _demoStudents.where((s) {
      final matchesSearch = _searchController.text.isEmpty ||
          s.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          s.roll.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || s.branch == _selectedFilter ||
          _selectedFilter == 'Year ${s.year}';
      return matchesSearch && matchesFilter;
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
        onTap: () => context.push('/students/${filtered[i].roll}'),
      ),
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
}

class _StudentData {
  final String name, roll, branch;
  final int year, attendance;
  const _StudentData({required this.name, required this.roll, required this.branch, required this.year, required this.attendance});
}

class _StudentListItem extends StatelessWidget {
  final _StudentData student;
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
                  student.name.split(' ').map((w) => w[0]).take(2).join(),
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
                      Text(student.roll, style: AppTextStyles.monoCode.copyWith(fontSize: 10)),
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
                    child: LinearProgressIndicator(
                      value: student.attendance / 100,
                      backgroundColor: AppColors.surfaceGlass,
                      valueColor: AlwaysStoppedAnimation(_attendanceColor),
                      minHeight: 4,
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
