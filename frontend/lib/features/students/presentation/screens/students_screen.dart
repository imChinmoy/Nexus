import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';
import '../../domain/entities/student_entity.dart';
import '../../providers/student_provider.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _searchVisible = true;

  final _attendanceFilters = ['All', 'Present', 'Not Scanned', 'Late', 'Absent'];
  final _branchFilters = ['All', 'CSE', 'CSE(DS)', 'CSE(AIML)', 'CSIT', 'ECE', 'CS(H)', 'ME', 'AIML', 'CE', 'IT'];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(studentSearchQueryProvider.notifier).state = value;
      ref.read(studentPageProvider.notifier).state = 1;
    });
  }

  void _selectEvent(EventEntity event) {
    final currentSelectedId = ref.read(selectedEventIdProvider);
    if (currentSelectedId != event.id) {
      ref.read(selectedEventIdProvider.notifier).state = event.id;
      ref.read(studentPageProvider.notifier).state = 1;
      ref.read(studentSearchQueryProvider.notifier).state = '';
      ref.read(studentBranchFilterProvider.notifier).state = 'All';
      ref.read(studentAttendanceFilterProvider.notifier).state = 'All';
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentOf(context);
    final selectedEventId = ref.watch(selectedEventIdProvider);
    final eventsAsync = ref.watch(eventsProvider);

    // Find the currently selected event object
    final selectedEvent = eventsAsync.valueOrNull?.cast<EventEntity?>().firstWhere(
          (e) => e?.id == selectedEventId,
          orElse: () => null,
        );

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
          ],
        ),
        body: Column(
          children: [
            // 1. Prominent Event Selector Bar
            _buildEventSelector(context, selectedEvent),

            // 2. Search & Filter Section (active only when event is selected)
            if (selectedEventId != null) ...[
              if (_searchVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: BrlTextField(
                    label: 'Search name, roll no, student no...',
                    controller: _searchController,
                    prefix: Icon(Icons.search, color: AppColors.textSecondaryOf(context), size: 18),
                    suffix: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    onChanged: _onSearchChanged,
                  ),
                ),
              _buildFilterChips(),
            ],

            // 3. Main Content: Event Students List or Initial Guidance
            Expanded(
              child: selectedEventId == null
                  ? _buildNoEventSelectedState(context)
                  : RefreshIndicator(
                      color: accent,
                      backgroundColor: AppColors.surfaceOf(context),
                      onRefresh: () async {
                        ref.invalidate(eventStudentsProvider);
                        ref.invalidate(eventsProvider);
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: _buildEventStudentsContent(context, selectedEvent),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact, Apple-style event selector widget at top
  Widget _buildEventSelector(BuildContext context, EventEntity? selectedEvent) {
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: GestureDetector(
        onTap: () => _showEventSelectionSheet(context),
        child: BrlGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event_available_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EVENT',
                      style: AppTextStyles.caption.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiaryOf(context),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedEvent != null ? selectedEvent.title : 'Select an Event to View Students',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selectedEvent != null
                            ? AppColors.textPrimaryOf(context)
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedEvent != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: selectedEvent.isAttendanceOpen
                        ? AppColors.successOf(context).withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedEvent.isAttendanceOpen ? 'Active' : selectedEvent.status.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: selectedEvent.isAttendanceOpen
                          ? AppColors.successOf(context)
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiaryOf(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontal scrolling chips for Attendance Status and Branches
  Widget _buildFilterChips() {
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedAttendance = ref.watch(studentAttendanceFilterProvider);
    final selectedBranch = ref.watch(studentBranchFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        children: [
          // Attendance status chips
          ..._attendanceFilters.map((status) {
            final isSelected = status == selectedAttendance;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  ref.read(studentAttendanceFilterProvider.notifier).state = status;
                  ref.read(studentPageProvider.notifier).state = 1;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent
                        : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? accent : AppColors.borderOf(context),
                      width: 0.6,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      status,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          Container(width: 1, height: 20, color: AppColors.borderOf(context), margin: const EdgeInsets.symmetric(horizontal: 4)),
          // Branch chips
          ..._branchFilters.where((b) => b != 'All').map((branch) {
            final isSelected = branch == selectedBranch;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () {
                  ref.read(studentBranchFilterProvider.notifier).state = isSelected ? 'All' : branch;
                  ref.read(studentPageProvider.notifier).state = 1;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.2)
                        : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFE5E5EA)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? accent : AppColors.borderOf(context),
                      width: 0.6,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      branch,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? accent : AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// State when no event has been selected yet
  Widget _buildNoEventSelectedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyStateWidget(
          icon: Icons.event_note_rounded,
          title: 'Select an Event',
          message: 'Choose an event from the selector above to view registered students and track attendance.',
          actionLabel: 'CHOOSE EVENT',
          onAction: () => _showEventSelectionSheet(context),
        ),
      ),
    );
  }

  /// Event students list with header stats and pagination
  Widget _buildEventStudentsContent(BuildContext context, EventEntity? event) {
    final studentsAsync = ref.watch(eventStudentsProvider);

    return studentsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.accentOf(context), strokeWidth: 2.5),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: EmptyStateWidget(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to Load Registrations',
            message: error.toString().replaceAll('Exception: ', ''),
            actionLabel: 'RETRY',
            onAction: () => ref.invalidate(eventStudentsProvider),
            iconColor: AppColors.errorOf(context),
          ),
        ),
      ),
      data: (result) {
        if (result == null) return _buildNoEventSelectedState(context);

        final counts = result.counts;
        final students = result.students;

        if (counts.total == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: EmptyStateWidget(
                icon: Icons.group_off_outlined,
                title: 'No Students Registered',
                message: 'No student registrations were found in the registration source for this event.',
              ),
            ),
          );
        }

        if (students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: 'No Matching Students',
                message: 'No registered students matched your current search and filter criteria.',
                actionLabel: 'RESET FILTERS',
                onAction: () {
                  _searchController.clear();
                  ref.read(studentSearchQueryProvider.notifier).state = '';
                  ref.read(studentBranchFilterProvider.notifier).state = 'All';
                  ref.read(studentAttendanceFilterProvider.notifier).state = 'All';
                  ref.read(studentPageProvider.notifier).state = 1;
                },
              ),
            ),
          );
        }

        return Column(
          children: [
            // Event Stats Bar
            _buildAttendanceStatsBar(context, counts),

            // Students List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _EventStudentListItem(
                  student: students[i],
                  onTap: () => context.push('/students/${students[i].rollNumber}'),
                ),
              ),
            ),

            // Pagination Footer
            if (result.totalPages > 1) _buildPaginationFooter(context, result),
          ],
        );
      },
    );
  }

  /// Compact Attendance Metric Bar for Selected Event
  Widget _buildAttendanceStatsBar(BuildContext context, EventStudentCountsEntity counts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: [
          _buildStatPill(context, 'Total', '${counts.total}', AppColors.accentOf(context)),
          const SizedBox(width: 8),
          _buildStatPill(context, 'Present', '${counts.present}', AppColors.successOf(context)),
          const SizedBox(width: 8),
          _buildStatPill(context, 'Not Scanned', '${counts.notMarked}', AppColors.warningOf(context)),
          if (counts.late > 0) ...[
            const SizedBox(width: 8),
            _buildStatPill(context, 'Late', '${counts.late}', Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildStatPill(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pagination footer controls
  Widget _buildPaginationFooter(BuildContext context, EventStudentsResultEntity result) {
    final currentPage = ref.watch(studentPageProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: AppColors.borderOf(context), width: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            onPressed: currentPage > 1
                ? () => ref.read(studentPageProvider.notifier).state = currentPage - 1
                : null,
          ),
          Text(
            'Page $currentPage of ${result.totalPages}  •  ${result.total} registered',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            onPressed: currentPage < result.totalPages
                ? () => ref.read(studentPageProvider.notifier).state = currentPage + 1
                : null,
          ),
        ],
      ),
    );
  }

  /// Apple-style blurred bottom sheet for event selection
  void _showEventSelectionSheet(BuildContext context) {
    final eventsAsync = ref.read(eventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);
    final selectedId = ref.read(selectedEventIdProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      Text('Select Event', style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: AppColors.textSecondaryOf(context)),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: eventsAsync.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(color: accent, strokeWidth: 2),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Failed to load events: $err',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.errorOf(context)),
                        ),
                      ),
                      data: (events) {
                        if (events.isEmpty) {
                          return const Center(
                            child: Text('No events available'),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: events.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final e = events[idx];
                            final isSelected = e.id == selectedId;

                            return GestureDetector(
                              onTap: () {
                                _selectEvent(e);
                                Navigator.pop(sheetContext);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accent.withValues(alpha: isDark ? 0.2 : 0.1)
                                      : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? accent : AppColors.borderOf(context),
                                    width: isSelected ? 1.2 : 0.6,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected ? accent : AppColors.surfaceOf(context),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.event_outlined,
                                        size: 16,
                                        color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.title,
                                            style: AppTextStyles.bodyMd.copyWith(
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('MMM d, y • h:mm a').format(e.startDate),
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textSecondaryOf(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (e.isAttendanceOpen)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.successOf(context).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'OPEN',
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.successOf(context),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Clean, minimalistic student list row
class _EventStudentListItem extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onTap;

  const _EventStudentListItem({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);

    final initials = student.name.isNotEmpty
        ? student.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    // Attendance badge formatting
    final attStatus = student.attendanceStatus;
    final bool isPresent = attStatus == 'present';
    final bool isLate = attStatus == 'late';
    final bool isAbsent = attStatus == 'absent';
    final bool isExcused = attStatus == 'excused';

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (isPresent) {
      statusColor = AppColors.successOf(context);
      statusLabel = 'Present';
      statusIcon = Icons.check_circle_rounded;
    } else if (isLate) {
      statusColor = Colors.orange;
      statusLabel = 'Late';
      statusIcon = Icons.access_time_filled_rounded;
    } else if (isAbsent) {
      statusColor = AppColors.errorOf(context);
      statusLabel = 'Absent';
      statusIcon = Icons.cancel_rounded;
    } else if (isExcused) {
      statusColor = Colors.blue;
      statusLabel = 'Excused';
      statusIcon = Icons.info_rounded;
    } else {
      statusColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70);
      statusLabel = 'Not Scanned';
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    String? markedTimeStr;
    if (student.markedAt != null) {
      markedTimeStr = DateFormat('h:mm a').format(student.markedAt!);
    }

    return GestureDetector(
      onTap: onTap,
      child: BrlGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Student Initials Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTextStyles.labelMd.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Student Identity Info
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        student.rollNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondaryOf(context),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (student.branch.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text('•', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          student.branch,
                          style: AppTextStyles.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Attendance Status Pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (markedTimeStr != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    markedTimeStr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiaryOf(context),
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
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
