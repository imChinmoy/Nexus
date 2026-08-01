import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
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
  final Map<String, String> _attendanceStatus = {}; // studentId -> status
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

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${failure.message}')));
          setState(() => _attendanceStatus.remove(studentId)); // revert on fail
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked successfully')));
          ref.invalidate(eventAttendanceProvider(widget.eventId));
          ref.invalidate(studentsProvider);
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _attendanceStatus.remove(studentId)); // revert on fail
    } finally {
      setState(() => _isMarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final attendanceAsync = ref.watch(eventAttendanceProvider(widget.eventId));

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'MANUAL ENTRY',
          accentColor: AppColors.moduleAttendance,
          showBack: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: BrlTextField(
                controller: _searchController,
                label: 'Search Name, Roll No, Student No...',
                prefix: const Icon(Icons.search, color: AppColors.onSurfaceSubtle, size: 18),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            if (_isMarking)
              const LinearProgressIndicator(color: AppColors.moduleAttendance),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.moduleAttendance,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  ref.invalidate(studentsProvider);
                  ref.invalidate(eventAttendanceProvider(widget.eventId));
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: studentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.moduleAttendance)),
                  error: (error, _) => Center(
                    child: Text('Error loading students: $error', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
                  ),
                  data: (students) {
                    return attendanceAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.moduleAttendance)),
                      error: (error, _) => Center(
                        child: Text('Error loading attendance: $error', style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
                      ),
                      data: (attendanceData) {
                        final remoteAttendanceMap = <String, String>{};
                        for (final att in attendanceData) {
                          final studentMap = att['student'] as Map<String, dynamic>?;
                          if (studentMap != null) {
                            final rollNumber = studentMap['rollNumber'] as String?;
                            if (rollNumber != null) {
                              remoteAttendanceMap[rollNumber] = att['status'] as String? ?? 'absent';
                            }
                          }
                        }

                        final filtered = students.where((s) {
                          final query = _searchQuery.toLowerCase();
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
                                child: const Center(
                                  child: Text('No students found', style: TextStyle(color: AppColors.onSurfaceMuted)),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final student = filtered[index];
                            final currentStatus = _attendanceStatus[student.id] ?? remoteAttendanceMap[student.rollNumber] ?? (student.isPresent ? 'present' : 'absent');

                            return BrlGlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.moduleAttendance.withOpacity(0.2),
                                    child: Text(
                                      student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : 'U',
                                      style: const TextStyle(color: AppColors.moduleAttendance, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(student.name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text('${student.rollNumber} • ${student.studentNo}', style: AppTextStyles.labelSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceGlass,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.glassStroke),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentStatus,
                                        dropdownColor: AppColors.surface,
                                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.onSurface),
                                        style: AppTextStyles.bodySm,
                                        items: const [
                                          DropdownMenuItem(value: 'absent', child: Text('Absent', style: TextStyle(color: AppColors.error))),
                                          DropdownMenuItem(value: 'present', child: Text('Present', style: TextStyle(color: AppColors.accentGreen))),
                                          DropdownMenuItem(value: 'late', child: Text('Late', style: TextStyle(color: AppColors.accentAmber))),
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
