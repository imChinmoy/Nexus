import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';
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
  final _capacityController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  String _type = 'workshop';
  File? _bannerImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: AppColors.accentOf(context),
              onPrimary: Colors.white,
              secondary: AppColors.accentOf(context),
              onSecondary: Colors.white,
              surface: AppColors.surfaceOf(context),
              onSurface: AppColors.textPrimaryOf(context),
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
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = AppColors.accentOf(context);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'New Event',
          showBack: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Banner Upload Card
                _buildSectionHeader('BANNER IMAGE'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: BrlGlassCard(
                    padding: EdgeInsets.zero,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161619) : const Color(0xFFF0F0F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _bannerImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_bannerImage!, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Change',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add_photo_alternate_outlined, size: 28, color: primaryAccent),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Add Cover Image',
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PNG, JPG up to 5MB (16:9 recommended)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Event Information Group
                _buildSectionHeader('EVENT DETAILS'),
                const SizedBox(height: 8),
                BrlGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrlTextField(
                        label: 'Event Title',
                        hintText: 'e.g., Annual Tech Symposium',
                        controller: _titleController,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 14),
                      BrlTextField(
                        label: 'Description',
                        hintText: 'Brief summary of agenda, speakers, requirements...',
                        controller: _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      BrlTextField(
                        label: 'Venue / Platform',
                        hintText: 'e.g., Main Auditorium or Google Meet',
                        controller: _venueController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Format & Capacity Group
                _buildSectionHeader('TYPE & CAPACITY'),
                const SizedBox(height: 8),
                BrlGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: BrlTextField(
                          label: 'Capacity (0 = unlimited)',
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                          hintText: '0',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Type',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceOf(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderOf(context), width: 0.8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _type,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceOf(context),
                                  icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondaryOf(context)),
                                  items: ['workshop', 'seminar', 'hackathon', 'meeting', 'recruitment', 'social', 'other']
                                      .map((t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              t[0].toUpperCase() + t.substring(1),
                                              style: AppTextStyles.bodyMd.copyWith(
                                                color: AppColors.textPrimaryOf(context),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _type = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Date & Time Group
                _buildSectionHeader('SCHEDULE'),
                const SizedBox(height: 8),
                BrlGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDateTile(
                          title: 'Start Date',
                          date: _startDate,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTile(
                          title: 'End Date',
                          date: _endDate,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                BrlButton(
                  label: 'Create Event',
                  isLoading: _isLoading,
                  onPressed: _submit,
                  icon: Icons.check,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildDateTile({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final formatted = '${_monthName(date.month)} ${date.day}, ${date.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderOf(context), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.accentOf(context)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatted,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
