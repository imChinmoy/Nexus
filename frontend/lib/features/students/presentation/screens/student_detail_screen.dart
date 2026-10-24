import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../domain/entities/student_entity.dart';
import '../../providers/student_provider.dart';
import '../../../attendance/providers/attendance_provider.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Overview, 1 = QR Pass

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final accent = AppColors.accentOf(context);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Student Profile',
          showBack: true,
        ),
        body: studentsAsync.maybeWhen(
          data: (students) {
            final student = students.firstWhere(
              (s) => s.rollNumber == widget.studentId || s.id == widget.studentId,
              orElse: () => throw Exception('Student not found'),
            );

            return RefreshIndicator(
              color: accent,
              backgroundColor: AppColors.surfaceOf(context),
              onRefresh: () async {
                ref.invalidate(studentsProvider);
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildHero(context, student),
                  const SizedBox(height: 18),
                  _buildSegmentedControl(context),
                  const SizedBox(height: 20),
                  if (_selectedTab == 0)
                    _buildOverviewTab(context, student)
                  else
                    _buildQrCardTab(context, student),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: accent, strokeWidth: 2.5),
          ),
          orElse: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 48, color: AppColors.errorOf(context)),
                const SizedBox(height: 12),
                Text('Student Not Found', style: AppTextStyles.headlineSm),
                const SizedBox(height: 6),
                Text(
                  'No record matched the provided ID: ${widget.studentId}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, StudentEntity student) {
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = student.name.trim().isNotEmpty
        ? student.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'S';

    return Column(
      children: [
        Hero(
          tag: 'avatar_${widget.studentId}',
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.headlineLg.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          student.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${student.rollNumber}  •  ${student.studentNo}',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.textSecondaryOf(context),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? AppColors.surfaceOf(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Overview',
                    style: AppTextStyles.labelMd.copyWith(
                      fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.w500,
                      color: _selectedTab == 0
                          ? AppColors.textPrimaryOf(context)
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? AppColors.surfaceOf(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 16,
                        color: _selectedTab == 1 ? accent : AppColors.textSecondaryOf(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'QR Pass',
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedTab == 1
                              ? AppColors.textPrimaryOf(context)
                              : AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventAttendanceSection(BuildContext context, StudentEntity student) {
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.valueOrNull ?? [];
    if (events.isEmpty) return const SizedBox.shrink();

    final selectedEventId = ref.watch(selectedEventIdProvider);
    final activeEvent = events.cast<EventEntity?>().firstWhere(
          (e) => e?.id == selectedEventId,
          orElse: () => EventEntity.findDefaultEvent(events) ?? events.first,
        );

    if (activeEvent == null) return const SizedBox.shrink();

    final eventScopedAsync = ref.watch(eventScopedStudentsFamilyProvider(activeEvent.id));
    final scopedStudent = eventScopedAsync.valueOrNull?.students.cast<StudentEntity?>().firstWhere(
          (s) => s?.id == student.id || s?.rollNumber == student.rollNumber,
          orElse: () => null,
        );

    final attStatus = scopedStudent?.attendanceStatus?.toLowerCase() ??
        student.attendanceStatus?.toLowerCase() ??
        (student.isPresent ? 'present' : 'not_scanned');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (attStatus == 'present') {
      statusColor = AppColors.successOf(context);
      statusLabel = 'Present';
      statusIcon = Icons.check_circle_rounded;
    } else if (attStatus == 'late') {
      statusColor = Colors.orange;
      statusLabel = 'Late';
      statusIcon = Icons.access_time_filled_rounded;
    } else if (attStatus == 'absent') {
      statusColor = AppColors.errorOf(context);
      statusLabel = 'Absent';
      statusIcon = Icons.cancel_rounded;
    } else if (attStatus == 'excused') {
      statusColor = Colors.blue;
      statusLabel = 'Excused';
      statusIcon = Icons.info_rounded;
    } else {
      statusColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
      statusLabel = 'Not Scanned';
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'EVENT ATTENDANCE • ${activeEvent.title.toUpperCase()}'),
        const SizedBox(height: 8),
        BrlGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Manual Override',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiaryOf(context)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickMarkChip(
                    context,
                    label: 'Present',
                    color: AppColors.successOf(context),
                    isSelected: attStatus == 'present',
                    onTap: () => _markStudent(student, activeEvent.id, 'present'),
                  ),
                  _buildQuickMarkChip(
                    context,
                    label: 'Absent',
                    color: AppColors.errorOf(context),
                    isSelected: attStatus == 'absent',
                    onTap: () => _markStudent(student, activeEvent.id, 'absent'),
                  ),
                  _buildQuickMarkChip(
                    context,
                    label: 'Late',
                    color: Colors.orange,
                    isSelected: attStatus == 'late',
                    onTap: () => _markStudent(student, activeEvent.id, 'late'),
                  ),
                  _buildQuickMarkChip(
                    context,
                    label: 'Not Scanned',
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                    isSelected: attStatus == 'not_scanned',
                    onTap: () => _markStudent(student, activeEvent.id, 'not_scanned'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuickMarkChip(
    BuildContext context, {
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderOf(context),
            width: isSelected ? 1.0 : 0.6,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            color: isSelected ? color : AppColors.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }

  Future<void> _markStudent(StudentEntity student, String eventId, String status) async {
    try {
      final attendanceRepo = ref.read(attendanceRepositoryProvider);
      final targetId = student.id.isNotEmpty ? student.id : student.rollNumber;
      final result = await attendanceRepo.markManual(
        eventId: eventId,
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
        },
        (_) {
          final displayLabel = status == 'not_scanned' ? 'Not Scanned' : status.toUpperCase();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance updated: $displayLabel'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          ref.invalidate(eventStudentsProvider);
          ref.invalidate(eventScopedStudentsFamilyProvider(eventId));
          ref.invalidate(eventAttendanceProvider(eventId));
          ref.invalidate(studentsProvider);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildOverviewTab(BuildContext context, StudentEntity student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventAttendanceSection(context, student),
        _buildSectionHeader(context, 'ACADEMIC & PERSONAL'),
        const SizedBox(height: 8),
        BrlGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildRow(context, Icons.email_outlined, 'Email', student.email),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.phone_outlined, 'Phone', student.phone?.isNotEmpty == true ? student.phone! : 'Not specified'),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.account_balance_outlined, 'Branch', student.branch),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.school_outlined, 'Year', 'Year ${student.year}'),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.domain_outlined, 'Domain', student.domain?.isNotEmpty == true ? student.domain! : 'General'),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.person_outline, 'Gender', student.gender?.isNotEmpty == true ? student.gender! : 'Not specified'),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.hotel_outlined, 'Hosteller', student.hosteller == true ? 'Yes' : 'Day Scholar'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(context, 'DEVELOPER & CODING PROFILES'),
        const SizedBox(height: 8),
        BrlGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildRow(context, Icons.code_rounded, 'GitHub', student.github?.isNotEmpty == true ? student.github! : 'Not linked'),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.emoji_events_outlined, 'Unstop', student.unstop?.isNotEmpty == true ? student.unstop! : 'Not linked'),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(context, Icons.terminal_rounded, 'HackerRank', student.hackerrank?.isNotEmpty == true ? student.hackerrank! : 'Not linked'),
              if (student.codingProfiles != null && student.codingProfiles!.isNotEmpty) ...[
                for (var profile in student.codingProfiles!) ...[
                  Divider(color: AppColors.borderOf(context), height: 1),
                  _buildRow(context, Icons.laptop_chromebook_outlined, profile.platform, profile.username),
                ]
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(context, 'RECORD TIMESTAMPS'),
        const SizedBox(height: 8),
        BrlGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildRow(
                context,
                Icons.calendar_today_outlined,
                'Joined Registry',
                student.createdAt != null ? '${student.createdAt!.toLocal()}'.split(' ')[0] : 'N/A',
              ),
              Divider(color: AppColors.borderOf(context), height: 1),
              _buildRow(
                context,
                Icons.update_outlined,
                'Last Updated',
                student.updatedAt != null ? '${student.updatedAt!.toLocal()}'.split(' ')[0] : 'N/A',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrCardTab(BuildContext context, StudentEntity student) {
    return Center(
      child: BrlGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: student.rollNumber,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1D1D1F),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              student.name,
              style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Roll No: ${student.rollNumber}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: student.rollNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Roll number copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 14, color: AppColors.accentOf(context)),
                    const SizedBox(width: 6),
                    Text(
                      'Copy Roll Number',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiaryOf(context),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentOf(context), size: 18),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondaryOf(context))),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
