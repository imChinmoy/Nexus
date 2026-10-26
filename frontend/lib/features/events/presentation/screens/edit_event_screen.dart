import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../domain/entities/event_entity.dart';
import '../../providers/event_provider.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventEntity event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;
  late final TextEditingController _capacityController;

  late DateTime _startDate;
  late DateTime _endDate;
  late String _type;
  late String _status;
  late bool _isAttendanceOpen;
  File? _bannerImage;
  bool _isLoading = false;
  int _activeStep = 0; // 0: Basic Info, 1: Details, 2: Schedule, 3: Settings

  final List<String> _eventTypes = [
    'workshop',
    'seminar',
    'hackathon',
    'recruitment',
    'meeting',
    'social',
    'bootcamp',
    'webinar',
    'meetup',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description ?? '');
    _venueController = TextEditingController(text: widget.event.venue ?? '');
    _capacityController =
        TextEditingController(text: widget.event.capacity.toString());
    _startDate = widget.event.startDate;
    _endDate = widget.event.endDate;
    _type = widget.event.type.toLowerCase().trim();
    if (_type.isEmpty) {
      _type = 'other';
    }
    if (!_eventTypes.contains(_type)) {
      _eventTypes.add(_type);
    }
    _status = widget.event.status.toLowerCase().trim();
    if (_status.isEmpty) {
      _status = 'upcoming';
    }
    _isAttendanceOpen = widget.event.isAttendanceOpen;

    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _venueController.addListener(() => setState(() {}));
    _capacityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _titleController.text != widget.event.title ||
        _descriptionController.text != (widget.event.description ?? '') ||
        _venueController.text != (widget.event.venue ?? '') ||
        _capacityController.text != widget.event.capacity.toString() ||
        _startDate != widget.event.startDate ||
        _endDate != widget.event.endDate ||
        _type != widget.event.type.toLowerCase() ||
        _status != widget.event.status.toLowerCase() ||
        _isAttendanceOpen != widget.event.isAttendanceOpen ||
        _bannerImage != null;
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Info';
      case 1:
        return 'Details';
      case 2:
        return 'Schedule';
      case 3:
        return 'Settings';
      default:
        return '';
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0: // Basic Info
        final title = _titleController.text.trim();
        if (title.isEmpty) {
          _showValidationError('Event title is required');
          return false;
        }
        if (title.length < 3) {
          _showValidationError('Event title must be at least 3 characters');
          return false;
        }
        if (title.length > 200) {
          _showValidationError('Event title cannot exceed 200 characters');
          return false;
        }
        if (_descriptionController.text.length > 2000) {
          _showValidationError('Description cannot exceed 2000 characters');
          return false;
        }
        return true;

      case 1: // Details
        final capacityStr = _capacityController.text.trim();
        final capacity = int.tryParse(capacityStr);
        if (capacity == null || capacity <= 0) {
          _showValidationError('Valid positive capacity is required');
          return false;
        }
        if (_type.trim().isEmpty) {
          _showValidationError('Please select an event type');
          return false;
        }
        return true;

      case 2: // Schedule
        if (_endDate.isBefore(_startDate)) {
          _showValidationError('End date cannot precede start date');
          return false;
        }
        return true;

      case 3: // Settings
        if (_status.trim().isEmpty) {
          _showValidationError('Please select a lifecycle status');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _showValidationError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.errorOf(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _navigateToStep(int targetIndex) {
    if (targetIndex == _activeStep) return;

    if (targetIndex < _activeStep) {
      // Going backward is always permitted
      ScaffoldMessenger.of(context).clearSnackBars();
      HapticFeedback.selectionClick();
      setState(() => _activeStep = targetIndex);
      return;
    }

    // Going forward requires validation of all intermediate steps
    for (int s = _activeStep; s < targetIndex; s++) {
      if (!_validateStep(s)) {
        setState(() => _activeStep = s);
        return;
      }
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    HapticFeedback.selectionClick();
    setState(() => _activeStep = targetIndex);
  }

  void _handleAppBarBack() {
    if (_activeStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _activeStep--);
    } else {
      _handlePop();
    }
  }

  Future<void> _handleTopSave() async {
    for (int s = 0; s < 4; s++) {
      if (!_validateStep(s)) {
        setState(() => _activeStep = s);
        return;
      }
    }
    await _submit();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _bannerImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: accent,
              onPrimary: Colors.white,
              secondary: accent,
              onSecondary: Colors.white,
              surface: isDark
                  ? const Color(0xFF141720)
                  : const Color(0xFFF3F4F7),
              onSurface: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              error: AppColors.errorOf(context),
              onError: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          if (picked.isBefore(_startDate)) {
            _showValidationError('End date cannot precede start date');
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _handlePop() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF161922)
            : Colors.white,
        title: Text(
          'Discard Unsaved Changes?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You have unsaved changes in this event editor. Are you sure you want to discard them?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorOf(context),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    for (int s = 0; s < 4; s++) {
      if (!_validateStep(s)) {
        setState(() => _activeStep = s);
        return;
      }
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final repository = ref.read(eventRepositoryProvider);
      final result = await repository.updateEvent(
        widget.event.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()) ?? 0,
        startDate: _startDate,
        endDate: _endDate,
        type: _type,
        bannerPath: _bannerImage?.path,
        status: _status,
        isAttendanceOpen: _isAttendanceOpen,
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.errorOf(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        (event) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Event updated successfully'),
              backgroundColor: AppColors.successOf(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          ref.invalidate(eventsProvider);
          Navigator.pop(context);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorOf(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return PopScope(
      canPop: !_hasUnsavedChanges && _activeStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleAppBarBack();
        }
      },
      child: AnimatedGradientBg(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildCustomHeader(context, isDark, accent),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Pinned Step Progress Indicator Bar (Basic Info, Details, Schedule, Settings)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: _buildStepProgressIndicator(context, isDark, accent),
                ),

                // 2. Step-Specific Form Content with smooth transitions
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey<int>(_activeStep),
                            child: _buildStepContent(
                              context,
                              isDark,
                              textPrimary,
                              textSecondary,
                              accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 3. Pinned Bottom Navigation Dock (Back & Next / Save Buttons)
                _buildBottomNavDock(context, isDark, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP CONTENT SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildStepContent(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    switch (_activeStep) {
      case 0:
        return Column(
          key: const ValueKey('step_0_basic_info'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerCard(context, isDark, accent),
            const SizedBox(height: 18),
            _buildBasicInfoFields(context, isDark, textPrimary, textSecondary),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey('step_1_details'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickSettingsCard(
                context, isDark, textPrimary, textSecondary, accent),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey('step_2_schedule'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScheduleCard(
                context, isDark, textPrimary, textSecondary, accent),
          ],
        );
      case 3:
        return Column(
          key: const ValueKey('step_3_settings'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusAndAttendanceCard(
                context, isDark, textPrimary, textSecondary, accent),
            const SizedBox(height: 18),
            _buildReviewSummaryCard(
                context, isDark, textPrimary, textSecondary, accent),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. CUSTOM TOP APP BAR (Back Button, Title/Subtitle, Prominent Save Button)
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildCustomHeader(
      BuildContext context, bool isDark, Color accent) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0x1FFFFFFF)
                      : const Color(0x0F000000),
                  width: 0.8,
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: textPrimary),
                onPressed: _handleAppBarBack,
              ),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Event',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: textPrimary,
            ),
          ),
          Text(
            widget.event.title,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 9, bottom: 9),
          child: Container(
            key: const ValueKey('top_save_button'),
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2997FF), Color(0xFF0A84FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _handleTopSave,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. STEP PROGRESS INDICATOR BAR (Animated Connecting Line & Active Nodes)
  // ---------------------------------------------------------------------------
  Widget _buildStepProgressIndicator(
      BuildContext context, bool isDark, Color accent) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final steps = [
      {'title': 'Basic Info', 'icon': Icons.description_rounded},
      {'title': 'Details', 'icon': Icons.tune_rounded},
      {'title': 'Schedule', 'icon': Icons.calendar_month_rounded},
      {'title': 'Settings', 'icon': Icons.settings_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCurrent = _activeStep == index;
          final isPast = _activeStep > index;
          final iconData = steps[index]['icon'] as IconData;
          final title = steps[index]['title'] as String;

          return Expanded(
            child: GestureDetector(
              key: ValueKey('step_node_$index'),
              onTap: () => _navigateToStep(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Left Connecting Segment
                      if (index > 0)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                            height: 2.0,
                            decoration: BoxDecoration(
                              color: isPast || isCurrent
                                  ? accent
                                  : (isDark
                                      ? const Color(0x22FFFFFF)
                                      : const Color(0x18000000)),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),

                      // Step Node Icon Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent
                              : (isPast
                                  ? accent.withValues(alpha: isDark ? 0.35 : 0.22)
                                  : (isDark
                                      ? const Color(0xFF171A24)
                                      : const Color(0xFFEBEFF4))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent
                                ? Colors.white
                                : (isPast ? accent : Colors.transparent),
                            width: isCurrent ? 1.6 : 1.0,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isPast ? Icons.check_rounded : iconData,
                            key: ValueKey<String>('${index}_$isPast'),
                            size: 16,
                            color: isCurrent
                                ? Colors.white
                                : (isPast ? accent : textSecondary),
                          ),
                        ),
                      ),

                      // Right Connecting Segment
                      if (index < steps.length - 1)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                            height: 2.0,
                            decoration: BoxDecoration(
                              color: isPast
                                  ? accent
                                  : (isDark
                                      ? const Color(0x22FFFFFF)
                                      : const Color(0x18000000)),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: GoogleFonts.inter(
                      fontSize: isCurrent ? 11.0 : 10.5,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : (isPast ? FontWeight.w600 : FontWeight.w500),
                      color: isCurrent
                          ? accent
                          : (isPast
                              ? (isDark ? Colors.white : Colors.black87)
                              : textSecondary),
                    ),
                    textAlign: TextAlign.center,
                    child: Text(title),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. BANNER PREVIEW CARD WITH "CHANGE BANNER" BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildBannerCard(BuildContext context, bool isDark, Color accent) {
    return Container(
      height: 175,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13161F) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_bannerImage != null)
              Image.file(_bannerImage!, fit: BoxFit.cover)
            else if (widget.event.banner != null &&
                widget.event.banner!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.event.banner!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(),
                errorWidget: (_, __, ___) => _buildBannerFallback(isDark),
              )
            else
              _buildBannerFallback(isDark),

            // Gradient Scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),

            // "Change Banner" Floating Action Button
            Positioned(
              right: 12,
              bottom: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_camera_rounded,
                                  size: 15, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Change Banner',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF141720) : const Color(0xFFE5E7EB),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. BASIC INFORMATION FIELDS (STEP 0)
  // ---------------------------------------------------------------------------
  Widget _buildBasicInfoFields(BuildContext context, bool isDark,
      Color textPrimary, Color textSecondary) {
    final titleCount = _titleController.text.length;
    final descCount = _descriptionController.text.length;
    final fieldBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA);
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Label with Character Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Event Title',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            Text(
              '$titleCount/200',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: titleCount > 190 ? Colors.red : textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('edit_event_title_field'),
          controller: _titleController,
          maxLength: 200,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Enter event title',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: textSecondary),
            filled: true,
            fillColor: fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 0.8),
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Event title is required';
            if (v.trim().length < 3) return 'Event title must be at least 3 characters';
            if (v.trim().length > 200) return 'Event title cannot exceed 200 characters';
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Description Label with Character Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            Text(
              '$descCount/2000',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: descCount > 1950 ? Colors.red : textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('edit_event_description_field'),
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 2000,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Describe this event in detail...',
            hintStyle: GoogleFonts.inter(fontSize: 12.5, color: textSecondary),
            filled: true,
            fillColor: fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. QUICK SETTINGS (STEP 1: Event Type, Capacity & Venue)
  // ---------------------------------------------------------------------------
  Widget _buildQuickSettingsCard(BuildContext context, bool isDark,
      Color textPrimary, Color textSecondary, Color accent) {
    final cardBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA);
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, size: 16, color: accent),
            const SizedBox(width: 7),
            Text(
              'Event Details & Venue',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Event Type Dropdown Card
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Type',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.category_rounded, size: 16, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              key: const ValueKey('edit_event_type_dropdown'),
                              value: _eventTypes.contains(_type)
                                  ? _type
                                  : (_eventTypes.isNotEmpty
                                      ? _eventTypes.first
                                      : null),
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF181B26)
                                  : Colors.white,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 18, color: textSecondary),
                              items: _eventTypes.map((type) {
                                final label = type.isEmpty
                                    ? ''
                                    : (type[0].toUpperCase() +
                                        (type.length > 1
                                            ? type.substring(1)
                                            : ''));
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _type = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Capacity Input Card
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacity',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.groups_rounded, size: 17, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('edit_event_capacity_field'),
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final n = int.tryParse(v.trim());
                              if (n == null || n <= 0) return '> 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Venue Input Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Venue / Location',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 17, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('edit_event_venue_field'),
                      controller: _venueController,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'e.g. CSIT Block or Auditorium',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 12, color: textSecondary),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. SCHEDULE SECTION (STEP 2: Start & End Date Tiles & Duration Badge)
  // ---------------------------------------------------------------------------
  Widget _buildScheduleCard(BuildContext context, bool isDark,
      Color textPrimary, Color textSecondary, Color accent) {
    final cardBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA);
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000);

    final startFormatted = DateFormat('MMM d, yyyy').format(_startDate);
    final endFormatted = DateFormat('MMM d, yyyy').format(_endDate);
    final durationDays = _endDate.difference(_startDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: accent),
            const SizedBox(width: 7),
            Text(
              'Event Schedule',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Start Date Tile
            Expanded(
              child: GestureDetector(
                key: const ValueKey('edit_event_start_date_tile'),
                onTap: () => _selectDate(context, true),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.event_available_rounded,
                            size: 16, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              startFormatted,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // End Date Tile
            Expanded(
              child: GestureDetector(
                key: const ValueKey('edit_event_end_date_tile'),
                onTap: () => _selectDate(context, false),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.event_busy_rounded,
                            size: 16, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              endFormatted,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Duration Info Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.timelapse_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _endDate.isBefore(_startDate)
                      ? 'Invalid Schedule: End date precedes start date'
                      : 'Schedule Duration: $durationDays ${durationDays == 1 ? 'Day' : 'Days'} ($startFormatted – $endFormatted)',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _endDate.isBefore(_startDate)
                        ? AppColors.errorOf(context)
                        : accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 7. STATUS & ATTENDANCE SECTION (STEP 3: Lifecycle & Live Attendance Switch)
  // ---------------------------------------------------------------------------
  Widget _buildStatusAndAttendanceCard(BuildContext context, bool isDark,
      Color textPrimary, Color textSecondary, Color accent) {
    final cardBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA);
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000);
    final successColor = isDark ? AppColors.successDark : AppColors.success;

    final statuses = ['upcoming', 'ongoing', 'completed', 'cancelled'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: accent),
            const SizedBox(width: 7),
            Text(
              'Status & Attendance',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lifecycle Status Segmented Pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lifecycle Status',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: statuses.map((s) {
                  final isSelected = _status == s;
                  final Color pillColor;
                  switch (s) {
                    case 'ongoing':
                      pillColor = successColor;
                      break;
                    case 'completed':
                      pillColor = accent;
                      break;
                    case 'cancelled':
                      pillColor = AppColors.errorOf(context);
                      break;
                    default:
                      pillColor = accent;
                  }

                  return Expanded(
                    child: GestureDetector(
                      key: ValueKey('status_pill_$s'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _status = s);
                      },
                      child: Container(
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? pillColor
                              : (isDark
                                  ? const Color(0xFF1D202C)
                                  : const Color(0xFFE5E9EE)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? pillColor : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s[0].toUpperCase() + s.substring(1),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Divider(
                color: isDark
                    ? const Color(0x18FFFFFF)
                    : const Color(0x0C000000),
                height: 1,
              ),
              const SizedBox(height: 12),

              // Live Attendance Switch Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.qr_code_scanner_rounded,
                        size: 18, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Live Attendance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Allow QR code check-in for this event',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    key: const ValueKey('edit_event_attendance_switch'),
                    value: _isAttendanceOpen,
                    activeTrackColor: accent,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _isAttendanceOpen = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 8. CONFIGURATION REVIEW SUMMARY CARD (STEP 3)
  // ---------------------------------------------------------------------------
  Widget _buildReviewSummaryCard(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent,
  ) {
    final cardBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA);
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000);
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final dateRangeStr =
        '${DateFormat('MMM d').format(_startDate)} – ${DateFormat('MMM d, yyyy').format(_endDate)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_outlined, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'Configuration Review',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _titleController.text.trim().isEmpty
                ? 'Untitled Event'
                : _titleController.text.trim(),
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          if (_descriptionController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _descriptionController.text.trim(),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildReviewChip(
                icon: Icons.category_rounded,
                label: _type.toUpperCase(),
                color: accent,
                isDark: isDark,
              ),
              _buildReviewChip(
                icon: Icons.groups_rounded,
                label: '${_capacityController.text.trim()} Capacity',
                color: accent,
                isDark: isDark,
              ),
              _buildReviewChip(
                icon: Icons.calendar_today_rounded,
                label: dateRangeStr,
                color: accent,
                isDark: isDark,
              ),
              if (_venueController.text.trim().isNotEmpty)
                _buildReviewChip(
                  icon: Icons.location_on_rounded,
                  label: _venueController.text.trim(),
                  color: accent,
                  isDark: isDark,
                ),
              _buildReviewChip(
                icon: Icons.flag_rounded,
                label: _status.toUpperCase(),
                color: _status == 'ongoing'
                    ? successColor
                    : (_status == 'cancelled'
                        ? AppColors.errorOf(context)
                        : accent),
                isDark: isDark,
              ),
              _buildReviewChip(
                icon: _isAttendanceOpen
                    ? Icons.qr_code_scanner_rounded
                    : Icons.qr_code_2_rounded,
                label: _isAttendanceOpen
                    ? 'QR Attendance Open'
                    : 'QR Attendance Closed',
                color: _isAttendanceOpen ? successColor : textSecondary,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. BOTTOM NAVIGATION DOCK (Back & Next / Save Buttons)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavDock(BuildContext context, bool isDark, Color accent) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 6
            : 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111319) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button (shown when on step > 0)
          if (_activeStep > 0) ...[
            OutlinedButton.icon(
              key: const ValueKey('step_back_button'),
              onPressed: _isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      setState(() => _activeStep--);
                    },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Back',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textSecondary,
                side: BorderSide(
                  color: isDark ? const Color(0x33FFFFFF) : const Color(0x22000000),
                  width: 0.9,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Primary Button (Next Step or Save Changes)
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2997FF), Color(0xFF0A84FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: _activeStep == 3
                      ? const ValueKey('step_save_button')
                      : const ValueKey('step_next_button'),
                  onTap: _isLoading
                      ? null
                      : () {
                          if (_activeStep < 3) {
                            if (_validateStep(_activeStep)) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              HapticFeedback.lightImpact();
                              setState(() => _activeStep++);
                            }
                          } else {
                            _submit();
                          }
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _activeStep == 3
                                    ? 'Save Changes'
                                    : 'Next: ${_getStepTitle(_activeStep + 1)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _activeStep == 3
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
