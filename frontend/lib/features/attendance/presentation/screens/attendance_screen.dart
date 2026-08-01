import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../events/providers/event_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'ATTENDANCE HUB',
          accentColor: AppColors.moduleAttendance,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const Text('No events available', style: TextStyle(color: Colors.white));
                  }
                  return BrlGlassCard(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        hint: const Text('Select Event', style: TextStyle(color: Colors.white54)),
                        value: _selectedEventId,
                        items: events.map((event) {
                          return DropdownMenuItem<String>(
                            value: event.id,
                            child: Text(event.title, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEventId = value;
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading events: $err', style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  if (_selectedEventId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an event first')));
                    return;
                  }
                  context.push('${RouteConstants.attendance}/qr-scan?eventId=$_selectedEventId');
                },
                child: BrlGlassCard(
                  padding: const EdgeInsets.all(24),
                  borderColor: AppColors.accentGreen,
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 64, color: AppColors.accentGreen),
                      const SizedBox(height: 16),
                      Text('QR SCANNER', style: AppTextStyles.headlineMd.copyWith(color: AppColors.accentGreen)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (_selectedEventId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an event first')));
                    return;
                  }
                  context.push('${RouteConstants.attendance}/manual?eventId=$_selectedEventId');
                },
                child: BrlGlassCard(
                  padding: const EdgeInsets.all(24),
                  borderColor: AppColors.primary,
                  child: Column(
                    children: [
                      const Icon(Icons.edit_note, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('MANUAL ENTRY', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
