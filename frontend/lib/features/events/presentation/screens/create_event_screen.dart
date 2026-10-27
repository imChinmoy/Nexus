import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../providers/event_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _capacityController = TextEditingController(text: '500');

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  String _type = 'workshop';
  File? _bannerImage;
  bool _isLoading = false;
  int _activeStep = 0; // 0: Basic Info, 1: Details, 2: Schedule, 3: Review

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
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
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
    return _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _venueController.text.isNotEmpty ||
        _bannerImage != null;
  }

  // ---------------------------------------------------------------------------
  // STEP VALIDATION & NAVIGATION
  // ---------------------------------------------------------------------------
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

      case 3: // Review
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
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
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

  Future<void> _handleTopCreate() async {
    for (int s = 0; s < 3; s++) {
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
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
              surface:
                  isDark ? const Color(0xFF141720) : const Color(0xFFF3F4F7),
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
          'Discard New Event?',
          style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You have uncompleted fields in this new event draft. Are you sure you want to discard them?',
          style: AppTextStyles.bodySm.copyWith(fontSize: 13),
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
    for (int s = 0; s < 3; s++) {
      if (!_validateStep(s)) {
        setState(() => _activeStep = s);
        return;
      }
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final repository = ref.read(eventRepositoryProvider);
      final result = await repository.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()) ?? 0,
        startDate: _startDate,
        endDate: _endDate,
        type: _type,
        bannerPath: _bannerImage?.path,
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
              content: const Text('Event created successfully'),
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

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------
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
                // 1. Pinned Step Progress Indicator Bar (Basic Info, Details, Schedule, Review)
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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

                // 3. Pinned Bottom Navigation Dock (Back & Next / Create Buttons)
                _buildBottomNavDock(context, isDark, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER BAR
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildCustomHeader(
      BuildContext context, bool isDark, Color accent) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

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
      title: Text(
        'New Event',
        style: AppTextStyles.cardTitle.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 9, bottom: 9),
          child: Container(
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
                onTap: _isLoading ? null : _handleTopCreate,
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
                            'Create',
                            style: AppTextStyles.buttonSm.copyWith(
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
  // 1. STEP PROGRESS INDICATOR BAR (Animated Connecting Line & Active Nodes)
  // ---------------------------------------------------------------------------
  Widget _buildStepProgressIndicator(
      BuildContext context, bool isDark, Color accent) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final steps = [
      {'title': 'Basic Info', 'icon': Icons.description_rounded},
      {'title': 'Details', 'icon': Icons.tune_rounded},
      {'title': 'Schedule', 'icon': Icons.calendar_month_rounded},
      {'title': 'Review', 'icon': Icons.rocket_launch_rounded},
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
                                  ? accent.withValues(
                                      alpha: isDark ? 0.35 : 0.22)
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
                    style: AppTextStyles.labelSm.copyWith(
                      fontSize: isCurrent ? 11.0 : 10.5,
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : (isPast ? FontWeight.w600 : FontWeight.w500),
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
          key: const ValueKey('step_3_review'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewSummaryCard(
                context, isDark, textPrimary, textSecondary, accent),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // 2. BANNER UPLOAD CARD
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
            else
              Container(
                color:
                    isDark ? const Color(0xFF141720) : const Color(0xFFE5E7EB),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 38,
                          color: isDark ? Colors.white30 : Colors.black26),
                      const SizedBox(height: 6),
                      Text(
                        'Upload Event Banner',
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Gradient Scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.50),
                  ],
                ),
              ),
            ),

            // "Add Banner" Floating Action Button
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
                                _bannerImage != null
                                    ? 'Change Banner'
                                    : 'Upload Banner',
                                style: AppTextStyles.labelSm.copyWith(
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

  // ---------------------------------------------------------------------------
  // 3. BASIC INFORMATION FIELDS (STEP 0)
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Event Title',
              style: AppTextStyles.labelMd.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            Text(
              '$titleCount/200',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: titleCount > 190 ? Colors.red : textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('create_event_title_field'),
          controller: _titleController,
          maxLength: 200,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Enter event title',
            hintStyle: AppTextStyles.bodySm
                .copyWith(fontSize: 13, color: textSecondary),
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
            if (v.trim().length < 3)
              return 'Event title must be at least 3 characters';
            if (v.trim().length > 200)
              return 'Event title cannot exceed 200 characters';
            return null;
          },
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: AppTextStyles.labelMd.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            Text(
              '$descCount/2000',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: descCount > 1950 ? Colors.red : textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: const ValueKey('create_event_description_field'),
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 2000,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Describe this event in detail...',
            hintStyle: AppTextStyles.bodySm
                .copyWith(fontSize: 12.5, color: textSecondary),
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
  // 4. QUICK SETTINGS SECTION (STEP 1)
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
              'Event Details & Specifications',
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
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
                      style: AppTextStyles.labelSm.copyWith(
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
                              key: const ValueKey('create_event_type_dropdown'),
                              value: _eventTypes.contains(_type)
                                  ? _type
                                  : (_eventTypes.isNotEmpty
                                      ? _eventTypes.first
                                      : null),
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF181B26)
                                  : Colors.white,
                              style: AppTextStyles.bodyMd.copyWith(
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
                      style: AppTextStyles.labelSm.copyWith(
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
                            key: const ValueKey('create_event_capacity_field'),
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
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
        const SizedBox(height: 10),
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
                style: AppTextStyles.labelSm.copyWith(
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
                      key: const ValueKey('create_event_venue_field'),
                      controller: _venueController,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'e.g. CSIT Block or Auditorium',
                        hintStyle: AppTextStyles.bodySm
                            .copyWith(fontSize: 12, color: textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
  // 5. SCHEDULE DATE TILES (STEP 2)
  // ---------------------------------------------------------------------------
  Widget _buildScheduleCard(BuildContext context, bool isDark,
      Color textPrimary, Color textSecondary, Color accent) {
    final cardBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF6F8FA);
    final borderColor =
        isDark ? const Color(0x1FFFFFFF) : const Color(0x0E000000);

    final startFormatted = DateFormat('MMM d, yyyy').format(_startDate);
    final endFormatted = DateFormat('MMM d, yyyy').format(_endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: accent),
            const SizedBox(width: 7),
            Text(
              'Timeline & Schedule',
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: const ValueKey('create_event_start_date_tile'),
                onTap: () => _selectDate(context, true),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              startFormatted,
                              style: AppTextStyles.bodyMd.copyWith(
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
            Expanded(
              child: GestureDetector(
                key: const ValueKey('create_event_end_date_tile'),
                onTap: () => _selectDate(context, false),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              endFormatted,
                              style: AppTextStyles.bodyMd.copyWith(
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. CONFIGURATION REVIEW SUMMARY CARD (STEP 3)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ready to Launch Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0D253A), const Color(0xFF131A26)]
                  : [const Color(0xFFE8F4FD), const Color(0xFFF0F7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.rocket_launch_rounded, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Launch Event',
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Review the parameters below. Once created, this event will be published to the organization feed.',
                      style: AppTextStyles.editorialSubtitle.copyWith(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary Card
        Container(
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
                    'Configuration Summary',
                    style: AppTextStyles.cardTitle.copyWith(
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
                style: AppTextStyles.headlineSm.copyWith(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              if (_descriptionController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _descriptionController.text.trim(),
                  style: AppTextStyles.bodySm.copyWith(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                  maxLines: 3,
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
                    label: 'UPCOMING',
                    color: successColor,
                    isDark: isDark,
                  ),
                  _buildReviewChip(
                    icon: _bannerImage != null
                        ? Icons.image_rounded
                        : Icons.image_not_supported_rounded,
                    label: _bannerImage != null
                        ? 'Custom Banner Attached'
                        : 'Default Gradient Banner',
                    color: _bannerImage != null ? successColor : textSecondary,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            style: AppTextStyles.labelSm.copyWith(
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
  // 7. BOTTOM NAVIGATION DOCK (Back & Next / Create Buttons)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavDock(BuildContext context, bool isDark, Color accent) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final nextLabel = switch (_activeStep) {
      0 => 'Next: Details',
      1 => 'Next: Schedule',
      2 => 'Next: Review',
      _ => 'Create Event',
    };

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
                style: AppTextStyles.buttonSm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textSecondary,
                side: BorderSide(
                  color: isDark
                      ? const Color(0x33FFFFFF)
                      : const Color(0x22000000),
                  width: 0.9,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Primary Button (Next Step or Create Event)
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
                      ? const ValueKey('step_create_button')
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
                                nextLabel,
                                style: AppTextStyles.buttonSm.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (_activeStep < 3) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ] else ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
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
