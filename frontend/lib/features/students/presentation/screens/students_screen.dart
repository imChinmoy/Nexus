import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../../shared/widgets/neon_badge.dart';
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

  static const List<String> _primaryAttendanceFilters = ['All', 'Present', 'Not Scanned'];
  static const List<String> _branchFilters = [
    'All',
    'CSE',
    'CSE(DS)',
    'CSE(AIML)',
    'CSIT',
    'ECE',
    'CS(H)',
    'ME',
    'AIML',
    'CE',
    'IT'
  ];
  static const List<String> _secondaryAttendanceFilters = [
    'All',
    'Present',
    'Not Scanned',
    'Late',
    'Absent',
    'Excused',
  ];

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

  void _resetAllFilters() {
    _searchController.clear();
    ref.read(studentSearchQueryProvider.notifier).state = '';
    ref.read(studentBranchFilterProvider.notifier).state = 'All';
    ref.read(studentAttendanceFilterProvider.notifier).state = 'All';
    ref.read(studentPageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentOf(context);
    final selectedEventId = ref.watch(selectedEventIdProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final selectedBranch = ref.watch(studentBranchFilterProvider);
    final selectedAttendance = ref.watch(studentAttendanceFilterProvider);

    // Active secondary filter count
    int activeFilterCount = 0;
    if (selectedBranch != 'All') activeFilterCount++;
    if (selectedAttendance != 'All' &&
        selectedAttendance != 'Present' &&
        selectedAttendance != 'Not Scanned') {
      activeFilterCount++;
    }

    // Find the currently selected event entity, defaulting to ongoing or closest upcoming event
    EventEntity? selectedEvent;
    final allEvents = eventsAsync.valueOrNull;
    if (allEvents != null && allEvents.isNotEmpty) {
      final sortedEvents = EventEntity.sortChronologically(allEvents);
      if (selectedEventId != null) {
        selectedEvent = sortedEvents.cast<EventEntity?>().firstWhere(
              (e) => e?.id == selectedEventId,
              orElse: () => null,
            );
      }
      if (selectedEvent == null) {
        final defEvent = EventEntity.findDefaultEvent(sortedEvents);
        if (defEvent != null) {
          selectedEvent = defEvent;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && ref.read(selectedEventIdProvider) != defEvent.id) {
              ref.read(selectedEventIdProvider.notifier).state = defEvent.id;
            }
          });
        }
      }
    }

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, selectedEvent, activeFilterCount),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Refined Selected-Event Card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildSelectedEventCard(context, selectedEvent),
              ),

              // 2. Search & Filter Controls (active only when event is selected)
              if (selectedEvent != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    children: [
                      // Search field
                      BrlTextField(
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
                      const SizedBox(height: 10),

                      // Segmented Primary Attendance & Secondary Filters Action
                      _buildFilterRow(context, selectedAttendance, activeFilterCount),
                    ],
                  ),
                ),
              ],

              // 3. Main Content Viewport
              Expanded(
                child: selectedEvent == null
                    ? _buildNoEventSelectedState(context)
                    : RefreshIndicator(
                        color: accent,
                        backgroundColor: AppColors.surfaceOf(context),
                        onRefresh: () async {
                          ref.invalidate(eventStudentsProvider);
                          ref.invalidate(eventsProvider);
                          await Future.delayed(const Duration(milliseconds: 400));
                        },
                        child: _buildEventStudentsContent(context, selectedEvent),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// 1. APP BAR: Refined, native-feeling Apple-style top navigation bar
  /// --------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    EventEntity? selectedEvent,
    int activeFilterCount,
  ) {
    final accent = AppColors.accentOf(context);

    return BrlAppBar(
      title: 'Students',
      overline: 'NEXUS • STUDENT REGISTRY',
      counterText: activeFilterCount > 0 ? '$activeFilterCount filtered' : null,
      actions: [
        BrlHeaderIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Filter Students',
          isActive: activeFilterCount > 0,
          badge: activeFilterCount > 0
              ? Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Center(
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              : null,
          onTap: () => _showSecondaryFiltersSheet(context),
        ),
        BrlHeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh Registrations',
          onTap: () {
            ref.invalidate(eventStudentsProvider);
            ref.invalidate(eventsProvider);
          },
        ),
      ],
    );
  }

  /// --------------------------------------------------------------------------
  /// 2. SELECTED-EVENT CARD: Wide card with subtle cover image background
  /// --------------------------------------------------------------------------
  Widget _buildSelectedEventCard(BuildContext context, EventEntity? selectedEvent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);
    final hasValidBanner = selectedEvent?.banner != null && selectedEvent!.banner!.trim().isNotEmpty;

    return Semantics(
      label: selectedEvent != null
          ? 'Selected Event: ${selectedEvent.title}. Tap to change event.'
          : 'Select an Event to View Students',
      button: true,
      child: GestureDetector(
        onTap: () => _showEventSelectionSheet(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // 1. Subtle Cover Background (or themed fallback surface)
                Positioned.fill(
                  child: hasValidBanner
                      ? CachedNetworkImage(
                          imageUrl: selectedEvent.banner!,
                          fit: BoxFit.cover,
                          memCacheWidth: 800,
                          memCacheHeight: 400,
                          placeholder: (_, __) => _buildCoverFallback(context, selectedEvent.type, isDark),
                          errorWidget: (_, __, ___) =>
                              _buildCoverFallback(context, selectedEvent.type, isDark),
                        )
                      : _buildCoverFallback(context, selectedEvent?.type, isDark),
                ),

                // 2. Theme-aware Translucent Gradient Scrim
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.black.withValues(alpha: 0.86),
                                Colors.black.withValues(alpha: 0.72),
                                Colors.black.withValues(alpha: 0.88),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.90),
                                Colors.white.withValues(alpha: 0.82),
                                Colors.white.withValues(alpha: 0.93),
                              ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Card Content Foreground
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Event Tag, Icon & Status Badge
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: accent,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EVENT',
                            style: AppTextStyles.caption.copyWith(
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : AppColors.textTertiaryOf(context),
                            ),
                          ),
                          const Spacer(),
                          if (selectedEvent != null)
                            NeonBadge(
                              label: selectedEvent.isAttendanceOpen
                                  ? 'ACTIVE'
                                  : selectedEvent.status.toUpperCase(),
                              type: selectedEvent.isAttendanceOpen
                                  ? NeonBadgeType.success
                                  : (selectedEvent.status == 'upcoming'
                                      ? NeonBadgeType.warning
                                      : NeonBadgeType.info),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Title Row with Chevron Affordance
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              selectedEvent != null
                                  ? selectedEvent.title
                                  : 'Select an Event to View Students',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isDark ? Colors.white : AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedEvent != null ? 'Change' : 'Choose',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 15,
                                  color: accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Subtitle: Schedule or Guidance
                      if (selectedEvent != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : AppColors.textSecondaryOf(context),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                DateFormat('MMM d, y • h:mm a').format(selectedEvent.startDate),
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.70)
                                      : AppColors.textSecondaryOf(context),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Deterministic Fallback Background Surface for Event Cards
  Widget _buildCoverFallback(BuildContext context, String? type, bool isDark) {
    final colors = switch (type?.toLowerCase()) {
      'hackathon' => isDark
          ? const [Color(0xFF0F172A), Color(0xFF023E8A), Color(0xFF0077B6)]
          : const [Color(0xFFE2E8F0), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
      'workshop' => isDark
          ? const [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF1D3557)]
          : const [Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      'seminar' => isDark
          ? const [Color(0xFF1E1035), Color(0xFF2C1654), Color(0xFF3F1D78)]
          : const [Color(0xFFF3E8FF), Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
      _ => isDark
          ? const [Color(0xFF18181C), Color(0xFF202026), Color(0xFF282830)]
          : const [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// 3. FILTER ROW: Primary Segmented Attendance Filter & Secondary Filters Sheet Trigger
  /// --------------------------------------------------------------------------
  Widget _buildFilterRow(
    BuildContext context,
    String selectedAttendance,
    int activeFilterCount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);

    return Row(
      children: [
        // Primary Segmented Control (All, Present, Not Scanned)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181C) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
            child: Row(
              children: _primaryAttendanceFilters.map((status) {
                final isSelected = status == selectedAttendance;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ref.read(studentAttendanceFilterProvider.notifier).state = status;
                      ref.read(studentPageProvider.notifier).state = 1;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF2C2C32) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          status,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11.5,
                            color: isSelected
                                ? (isDark ? Colors.white : AppColors.textPrimaryOf(context))
                                : AppColors.textSecondaryOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Dedicated Secondary Filter Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showSecondaryFiltersSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            decoration: BoxDecoration(
              color: activeFilterCount > 0
                  ? accent.withValues(alpha: isDark ? 0.22 : 0.12)
                  : (isDark ? const Color(0xFF18181C) : const Color(0xFFE5E5EA)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activeFilterCount > 0
                    ? accent.withValues(alpha: 0.5)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: activeFilterCount > 0 ? accent : AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 4),
                Text(
                  'Filters',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: activeFilterCount > 0 ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11.5,
                    color: activeFilterCount > 0 ? accent : AppColors.textSecondaryOf(context),
                  ),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// --------------------------------------------------------------------------
  /// 4. SECONDARY FILTERS BOTTOM SHEET: Branch & Secondary Attendance Attributes
  /// --------------------------------------------------------------------------
  void _showSecondaryFiltersSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);

    String tempBranch = ref.read(studentBranchFilterProvider);
    String tempAttendance = ref.read(studentAttendanceFilterProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context).withValues(alpha: isDark ? 0.96 : 0.98),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: AppColors.borderOf(context), width: 0.6),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textTertiaryOf(context).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sheet Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Filter Students',
                              style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempBranch = 'All';
                                tempAttendance = 'All';
                              });
                            },
                            child: Text(
                              'Reset All',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Expanded(
                        child: ListView(
                          children: [
                            // 1. Branch Category Filter
                            Text(
                              'ACADEMIC BRANCH',
                              style: AppTextStyles.caption.copyWith(
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                                color: AppColors.textTertiaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _branchFilters.map((branch) {
                                final isSelected = branch == tempBranch;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setSheetState(() => tempBranch = branch);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accent.withValues(alpha: isDark ? 0.25 : 0.15)
                                          : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? accent : AppColors.borderOf(context),
                                        width: isSelected ? 1.0 : 0.6,
                                      ),
                                    ),
                                    child: Text(
                                      branch,
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 12,
                                        color: isSelected
                                            ? accent
                                            : AppColors.textPrimaryOf(context),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 22),

                            // 2. Attendance Status Filter
                            Text(
                              'ATTENDANCE STATUS',
                              style: AppTextStyles.caption.copyWith(
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                                color: AppColors.textTertiaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _secondaryAttendanceFilters.map((status) {
                                final isSelected = status == tempAttendance;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setSheetState(() => tempAttendance = status);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accent.withValues(alpha: isDark ? 0.25 : 0.15)
                                          : (isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? accent : AppColors.borderOf(context),
                                        width: isSelected ? 1.0 : 0.6,
                                      ),
                                    ),
                                    child: Text(
                                      status,
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 12,
                                        color: isSelected
                                            ? accent
                                            : AppColors.textPrimaryOf(context),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Bottom Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: AppColors.borderOf(context)),
                              ),
                              onPressed: () => Navigator.pop(sheetContext),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textSecondaryOf(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                ref.read(studentBranchFilterProvider.notifier).state = tempBranch;
                                ref.read(studentAttendanceFilterProvider.notifier).state = tempAttendance;
                                ref.read(studentPageProvider.notifier).state = 1;
                                Navigator.pop(sheetContext);
                              },
                              child: const Text(
                                'Apply Filters',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// --------------------------------------------------------------------------
  /// 5. ATTENDANCE STATS BAR: Balanced Apple-style cards with aligned baselines
  /// --------------------------------------------------------------------------
  Widget _buildAttendanceStatsBar(BuildContext context, EventStudentCountsEntity counts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          _buildStatCard(
            context,
            label: 'Total',
            value: '${counts.total}',
            color: AppColors.accentOf(context),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            label: 'Present',
            value: '${counts.present}',
            color: AppColors.successOf(context),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context,
            label: 'Not Scanned',
            value: '${counts.notMarked}',
            color: AppColors.warningOf(context),
          ),
          if (counts.late > 0) ...[
            const SizedBox(width: 8),
            _buildStatCard(
              context,
              label: 'Late',
              value: '${counts.late}',
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// 6. MAIN CONTENT: Event Students List or Guidance State
  /// --------------------------------------------------------------------------
  Widget _buildNoEventSelectedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyStateWidget(
          icon: Icons.event_note_rounded,
          title: 'Select an Event',
          message:
              'Choose an event from the selector above to view registered students and track attendance.',
          actionLabel: 'CHOOSE EVENT',
          onAction: () => _showEventSelectionSheet(context),
        ),
      ),
    );
  }

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
                message:
                    'No student registrations were found in the registration source for this event.',
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
                onAction: _resetAllFilters,
              ),
            ),
          );
        }

        return Column(
          children: [
            // Attendance Summary Bar
            _buildAttendanceStatsBar(context, counts),

            // Padded Students List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
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

  /// Pagination Footer
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

  /// --------------------------------------------------------------------------
  /// 7. EVENT SELECTION SHEET: With subtle cover images on each event card
  /// --------------------------------------------------------------------------
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
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
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
                      width: 38,
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
                      Text(
                        'Select Event',
                        style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondaryOf(context)),
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
                        final sortedEvents = EventEntity.sortChronologically(events);

                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: sortedEvents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final e = sortedEvents[idx];
                            final isSelected = e.id == selectedId;
                            final hasBanner = e.banner != null && e.banner!.trim().isNotEmpty;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _selectEvent(e);
                                Navigator.pop(sheetContext);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? accent
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.10)
                                            : Colors.black.withValues(alpha: 0.06)),
                                    width: isSelected ? 1.4 : 0.6,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      // Subtle Cover Background
                                      Positioned.fill(
                                        child: hasBanner
                                            ? CachedNetworkImage(
                                                imageUrl: e.banner!,
                                                fit: BoxFit.cover,
                                                memCacheWidth: 600,
                                                memCacheHeight: 300,
                                                placeholder: (_, __) =>
                                                    _buildCoverFallback(context, e.type, isDark),
                                                errorWidget: (_, __, ___) =>
                                                    _buildCoverFallback(context, e.type, isDark),
                                              )
                                            : _buildCoverFallback(context, e.type, isDark),
                                      ),

                                      // Scrim Overlay
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDark
                                                  ? [
                                                      Colors.black.withValues(alpha: 0.88),
                                                      Colors.black.withValues(alpha: 0.75),
                                                      Colors.black.withValues(alpha: 0.90),
                                                    ]
                                                  : [
                                                      Colors.white.withValues(alpha: 0.92),
                                                      Colors.white.withValues(alpha: 0.85),
                                                      Colors.white.withValues(alpha: 0.94),
                                                    ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Content Row
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? accent
                                                    : (isDark
                                                        ? Colors.white.withValues(alpha: 0.12)
                                                        : Colors.black.withValues(alpha: 0.08)),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isSelected ? Icons.check_rounded : Icons.event_outlined,
                                                size: 17,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark ? Colors.white70 : Colors.black87),
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
                                                      color: isDark
                                                          ? Colors.white
                                                          : AppColors.textPrimaryOf(context),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    DateFormat('MMM d, y • h:mm a').format(e.startDate),
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.65)
                                                          : AppColors.textSecondaryOf(context),
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (e.isAttendanceOpen)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.successOf(context).withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'OPEN',
                                                  style: AppTextStyles.caption.copyWith(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.successOf(context),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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

/// --------------------------------------------------------------------------
/// 8. STUDENT ROW: Spacious, balanced Apple-style student identity item
/// --------------------------------------------------------------------------
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: BrlGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Student Initials Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
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
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Student Identity Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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
                          fontSize: 12,
                        ),
                      ),
                      if (student.branch.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.textTertiaryOf(context),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          student.branch,
                          style: AppTextStyles.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Attendance Status Pill & Marked Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (markedTimeStr != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    markedTimeStr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiaryOf(context),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.textTertiaryOf(context),
            ),
          ],
        ),
      ),
    );
  }
}
