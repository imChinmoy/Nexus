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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _markAttendance(String studentId, String status) async {
    setState(() {
      _isMarking = true;
      _attendanceStatus[studentId] = status;
    });

    try {
      final attendanceRepo = ref.read(attendanceRepositoryProvider);
      final result = await attendanceRepo.markManual(
        eventId: widget.eventId,
        studentId: studentId,
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
          setState(() => _attendanceStatus.remove(studentId));
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance recorded: ${status.toUpperCase()}'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          ref.invalidate(eventAttendanceProvider(widget.eventId));
          ref.invalidate(studentsProvider);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
        setState(() => _attendanceStatus.remove(studentId));
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

    final studentsAsync = ref.watch(studentsProvider);
    final attendanceAsync = ref.watch(eventAttendanceProvider(widget.eventId));

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
                  ref.invalidate(studentsProvider);
                  ref.invalidate(eventAttendanceProvider(widget.eventId));
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: studentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (error, _) => Center(
                    child: Text(
                      'Error loading students: $error',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: isDark ? AppColors.errorDark : AppColors.error,
                      ),
                    ),
                  ),
                  data: (students) {
                    return attendanceAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (error, _) => Center(
                        child: Text(
                          'Error loading attendance: $error',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: isDark ? AppColors.errorDark : AppColors.error,
                          ),
                        ),
                      ),
                      data: (attendanceData) {
                        final remoteAttendanceMap = <String, String>{};
                        for (final att in attendanceData) {
                          final studentMap = att['student'] as Map<String, dynamic>?;
                          if (studentMap != null) {
                            final rollNumber = studentMap['rollNumber'] as String?;
                            if (rollNumber != null) {
                              remoteAttendanceMap[rollNumber] =
                                  att['status'] as String? ?? 'absent';
                            }
                          }
                        }

                        final query = _searchQuery.toLowerCase();
                        final filtered = students.where((s) {
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
                                    _searchQuery.isEmpty
                                        ? 'No students found'
                                        : 'No students matching "$_searchQuery"',
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
                                remoteAttendanceMap[student.rollNumber] ??
                                (student.isPresent ? 'present' : 'absent');

                            return BrlGlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: (isDark
                                            ? AppColors.darkAccent
                                            : AppColors.lightAccent)
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      student.name.isNotEmpty
                                          ? student.name.substring(0, 1).toUpperCase()
                                          : 'S',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkAccent
                                            : AppColors.lightAccent,
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
                                          style: AppTextStyles.bodyMd.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${student.rollNumber} • ${student.branch}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: textSecondary,
                                          ),
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
                                      color: isDark
                                          ? AppColors.darkElevatedSurface
                                          : AppColors.lightSecondaryBackground,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0x1AFFFFFF)
                                            : const Color(0x0F000000),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentStatus,
                                        dropdownColor: isDark
                                            ? AppColors.darkElevatedSurface
                                            : AppColors.lightSurface,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                        style: AppTextStyles.labelSm.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        items: [
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
                                            value: 'late',
                                            child: Text(
                                              'Late',
                                              style: TextStyle(
                                                color: isDark ? AppColors.warningDark : AppColors.warning,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null && value != currentStatus) {
                                            _markAttendance(student.id, value);
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
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
