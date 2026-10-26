import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End date cannot precede start date'),
                behavior: SnackBarBehavior.floating,
              ),
            );
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You have uncompleted fields in this new event draft. Are you sure you want to discard them?',
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
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check form fields for errors'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handlePop();
        }
      },
      child: AnimatedGradientBg(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildCustomHeader(context, isDark, accent),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Step Progress Indicator Bar
                  _buildStepProgressIndicator(context, isDark, accent),
                  const SizedBox(height: 18),

                  // 2. Banner Upload Card
                  _buildBannerCard(context, isDark, accent),
                  const SizedBox(height: 18),

                  // 3. Basic Information Fields
                  _buildBasicInfoFields(
                      context, isDark, textPrimary, textSecondary),
                  const SizedBox(height: 18),

                  // 4. Quick Settings Section
                  _buildQuickSettingsCard(
                      context, isDark, textPrimary, textSecondary, accent),
                  const SizedBox(height: 18),

                  // 5. Schedule Date Tiles
                  _buildScheduleCard(
                      context, isDark, textPrimary, textSecondary, accent),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                onPressed: _handlePop,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'New Event',
        style: GoogleFonts.inter(
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
                onTap: _isLoading ? null : _submit,
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

  Widget _buildStepProgressIndicator(
      BuildContext context, bool isDark, Color accent) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final steps = [
      {'title': 'Basic Info', 'icon': Icons.description_rounded},
      {'title': 'Details', 'icon': Icons.tune_rounded},
      {'title': 'Schedule', 'icon': Icons.calendar_month_rounded},
      {'title': 'Publish', 'icon': Icons.rocket_launch_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCurrent = _activeStep == index;
          final isPast = _activeStep > index;
          final iconData = steps[index]['icon'] as IconData;
          final title = steps[index]['title'] as String;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeStep = index);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 1.5,
                            color: isPast
                                ? accent
                                : (isDark
                                    ? const Color(0x22FFFFFF)
                                    : const Color(0x18000000)),
                          ),
                        ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent
                              : (isPast
                                  ? accent.withValues(alpha: 0.25)
                                  : (isDark
                                      ? const Color(0xFF171A24)
                                      : const Color(0xFFEBEFF4))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent
                                ? Colors.white
                                : (isPast ? accent : Colors.transparent),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          size: 16,
                          color: isCurrent
                              ? Colors.white
                              : (isPast ? accent : textSecondary),
                        ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 1.5,
                            color: isPast
                                ? accent
                                : (isDark
                                    ? const Color(0x22FFFFFF)
                                    : const Color(0x18000000)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? accent : textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

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
                color: isDark ? const Color(0xFF141720) : const Color(0xFFE5E7EB),
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
                        style: GoogleFonts.inter(
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
              'Quick Settings',
              style: GoogleFonts.inter(
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
              'Schedule',
              style: GoogleFonts.inter(
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
            Expanded(
              child: GestureDetector(
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
      ],
    );
  }
}
