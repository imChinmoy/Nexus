import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../providers/attendance_provider.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/providers/student_provider.dart';

class ManualAttendanceScreen extends ConsumerStatefulWidget {
  final String eventId;
  const ManualAttendanceScreen({super.key, this.eventId = ''});

  @override
  ConsumerState<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends ConsumerState<ManualAttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _attendanceStatus = {};
  bool _isMarking = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.eventId.trim().isNotEmpty) {
      Future.microtask(() {
        if (mounted) {
          ref.read(selectedEventIdProvider.notifier).state = widget.eventId.trim();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _markAttendance(StudentEntity student, String status) async {
    final targetId = student.id.isNotEmpty ? student.id : student.rollNumber;
    setState(() {
      _isMarking = true;
      if (student.id.isNotEmpty) _attendanceStatus[student.id] = status;
      if (student.rollNumber.isNotEmpty) _attendanceStatus[student.rollNumber] = status;
    });

    try {
      final attendanceRepo = ref.read(attendanceRepositoryProvider);
      final result = await attendanceRepo.markManual(
        eventId: widget.eventId,
        studentId: targetId,
        status: status,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${failure.message}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            if (student.id.isNotEmpty) _attendanceStatus.remove(student.id);
            if (student.rollNumber.isNotEmpty) _attendanceStatus.remove(student.rollNumber);
          });
        },
        (_) {
          final displayStatus = status == 'not_scanned' ? 'NOT SCANNED' : status.toUpperCase();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance recorded: $displayStatus'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          ref.invalidate(eventAttendanceProvider(widget.eventId));
          ref.invalidate(eventScopedStudentsFamilyProvider(widget.eventId));
          ref.invalidate(eventStudentsProvider);
          ref.invalidate(studentsProvider);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
        setState(() {
          if (student.id.isNotEmpty) _attendanceStatus.remove(student.id);
          if (student.rollNumber.isNotEmpty) _attendanceStatus.remove(student.rollNumber);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isMarking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (widget.eventId.trim().isEmpty) {
      return AnimatedGradientBg(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const BrlAppBar(
            title: 'Manual Entry',
            showBack: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: BrlGlassCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy_outlined, color: AppColors.errorDark, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      'NO EVENT SELECTED',
                      style: AppTextStyles.headlineSm.copyWith(color: AppColors.errorDark),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please select an event from the Attendance Hub before recording manual attendance.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 24),
                    BrlButton(
                      label: 'GO TO ATTENDANCE HUB',
                      onPressed: () => context.go(RouteConstants.attendance),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final scopedAsync = ref.watch(eventScopedStudentsFamilyProvider(widget.eventId));
    final fallbackStudentsAsync = ref.watch(studentsProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Manual Entry',
          showBack: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: BrlTextField(
                controller: _searchController,
                label: 'Search students',
                hint: 'Search name, roll number, student ID...',
                prefix: Icon(Icons.search_rounded, color: textSecondary, size: 18),
                suffix: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            if (_isMarking)
              LinearProgressIndicator(
                minHeight: 2,
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                backgroundColor: Colors.transparent,
              ),
            Expanded(
              child: RefreshIndicator(
                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                backgroundColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
                onRefresh: () async {
                  ref.invalidate(eventScopedStudentsFamilyProvider(widget.eventId));
                  ref.invalidate(eventAttendanceProvider(widget.eventId));
                  ref.invalidate(studentsProvider);
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: scopedAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => _buildFallbackList(fallbackStudentsAsync, isDark, textSecondary),
                  data: (eventResult) {
                    final List<StudentEntity> candidateStudents;
                    if (eventResult != null && eventResult.students.isNotEmpty) {
                      candidateStudents = eventResult.students;
                    } else {
                      candidateStudents = fallbackStudentsAsync.valueOrNull ?? [];
                    }

                    if (candidateStudents.isEmpty && fallbackStudentsAsync.isLoading) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }

                    return _buildStudentsListView(candidateStudents, isDark, textSecondary);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackList(AsyncValue<List<StudentEntity>> fallbackAsync, bool isDark, Color textSecondary) {
    return fallbackAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, _) => Center(
        child: Text(
          'Error loading students: $err',
          style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.errorDark : AppColors.error),
        ),
      ),
      data: (students) => _buildStudentsListView(students, isDark, textSecondary),
    );
  }

  Widget _buildStudentsListView(List<StudentEntity> allStudents, bool isDark, Color textSecondary) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = allStudents.where((s) {
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.rollNumber.toLowerCase().contains(query) ||
          s.studentNo.toLowerCase().contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Text(
                _searchQuery.isEmpty ? 'No registered students found' : 'No students matching "$_searchQuery"',
                style: AppTextStyles.bodyMd.copyWith(color: textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = filtered[index];
        final currentStatus = _attendanceStatus[student.id] ??
            _attendanceStatus[student.rollNumber] ??
            student.attendanceStatus?.toLowerCase() ??
            'not_scanned';

        return BrlGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: (isDark ? AppColors.darkAccent : AppColors.lightAccent).withValues(alpha: 0.12),
                child: Text(
                  student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : 'S',
                  style: TextStyle(
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student.rollNumber} • ${student.branch.isNotEmpty ? student.branch : 'General'}',
                      style: AppTextStyles.caption.copyWith(color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevatedSurface : AppColors.lightSecondaryBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                    width: 0.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentStatus,
                    dropdownColor: isDark ? AppColors.darkElevatedSurface : AppColors.lightSurface,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w600),
                    items: [
                      DropdownMenuItem(
                        value: 'not_scanned',
                        child: Text(
                          'Not Scanned',
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'present',
                        child: Text(
                          'Present',
                          style: TextStyle(
                            color: isDark ? AppColors.successDark : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'absent',
                        child: Text(
                          'Absent',
                          style: TextStyle(
                            color: isDark ? AppColors.errorDark : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'late',
                        child: Text(
                          'Late',
                          style: TextStyle(
                            color: isDark ? AppColors.warningDark : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: 'excused',
                        child: Text(
                          'Excused',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != currentStatus) {
                        _markAttendance(student, value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
