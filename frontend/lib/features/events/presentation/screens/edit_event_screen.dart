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
import '../../domain/entities/event_entity.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventEntity event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _capacityController = TextEditingController();
  
  late DateTime _startDate;
  late DateTime _endDate;
  late String _type;
  File? _bannerImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.event.title;
    _descriptionController.text = widget.event.description ?? '';
    _venueController.text = widget.event.venue ?? '';
    _capacityController.text = widget.event.capacity.toString();
    _startDate = widget.event.startDate;
    _endDate = widget.event.endDate;
    _type = widget.event.type.toLowerCase();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _bannerImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.moduleEvents,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: Colors.white,
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
      );

      result.fold(
        (failure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
          );
        },
        (event) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully!'), backgroundColor: AppColors.success),
          );
          ref.invalidate(eventsProvider);
          Navigator.pop(context);
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
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
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'EDIT EVENT',
          accentColor: AppColors.moduleEvents,
          showBack: true,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: BrlGlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _bannerImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_bannerImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate, size: 48, color: AppColors.moduleEvents),
                              const SizedBox(height: 8),
                              Text('Upload Banner Image', style: AppTextStyles.bodyMd.copyWith(color: AppColors.moduleEvents)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BrlGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrlTextField(
                      label: 'Event Title',
                      controller: _titleController,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    BrlTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    BrlTextField(
                      label: 'Venue',
                      controller: _venueController,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: BrlTextField(
                            label: 'Capacity',
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              labelStyle: TextStyle(color: AppColors.onSurfaceMuted),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.onSurfaceMuted)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.moduleEvents)),
                            ),
                            dropdownColor: AppColors.surface,
                            items: ['workshop', 'seminar', 'hackathon', 'meeting', 'recruitment', 'social', 'other']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white))))
                                .toList(),
                            onChanged: (val) => setState(() => _type = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.moduleEvents), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start Date', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                  const SizedBox(height: 4),
                                  Text(_startDate.toString().split(' ')[0], style: AppTextStyles.bodyMd),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.moduleEvents), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('End Date', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted)),
                                  const SizedBox(height: 4),
                                  Text(_endDate.toString().split(' ')[0], style: AppTextStyles.bodyMd),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.moduleEvents))
                  : BrlButton(
                      label: 'UPDATE EVENT',
                      onPressed: _submit,
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
