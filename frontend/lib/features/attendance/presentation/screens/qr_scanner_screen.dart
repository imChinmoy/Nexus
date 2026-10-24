import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../data/models/scan_attendance_result.dart';
import '../../providers/attendance_provider.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/providers/event_provider.dart';
import '../../../students/providers/student_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String eventId;
  const QrScannerScreen({super.key, this.eventId = ''});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _ScanFeedback {
  final bool isSuccess;
  final bool isDuplicate;
  final String title;
  final String subtitle;
  final String? studentName;
  final String? rollNumber;
  final DateTime timestamp;

  const _ScanFeedback({
    required this.isSuccess,
    required this.isDuplicate,
    required this.title,
    required this.subtitle,
    this.studentName,
    this.rollNumber,
    required this.timestamp,
  });
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _lastScannedCode;
  DateTime? _lastScannedAt;
  _ScanFeedback? _activeFeedback;
  final List<ScanAttendanceResult> _sessionHistory = [];
  Timer? _feedbackTimer;
  String? _overrideEventId;

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        if (!_controller.value.isInitialized) {
          _controller.start();
        }
        break;
      case AppLifecycleState.inactive:
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedbackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String rawValue, String eventId) async {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty || eventId.trim().isEmpty) return;

    if (_isProcessing) return;

    // Debounce: prevent same QR code from re-triggering within 3 seconds
    final now = DateTime.now();
    if (_lastScannedCode == trimmed &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!).inSeconds < 3) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _lastScannedCode = trimmed;
      _lastScannedAt = now;
    });

    try {
      final repository = ref.read(attendanceRepositoryProvider);
      final result = await repository.scanAttendance(
        eventId: eventId,
        qrValue: trimmed,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          HapticFeedback.heavyImpact();
          _showFeedback(
            _ScanFeedback(
              isSuccess: false,
              isDuplicate: false,
              title: failure.code ?? 'SCAN_FAILED',
              subtitle: failure.message,
              timestamp: DateTime.now(),
            ),
          );
        },
        (scanResult) {
          if (scanResult.isDuplicate) {
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.lightImpact();
          }

          // Insert into in-memory session history
          _sessionHistory.insert(0, scanResult);

          _showFeedback(
            _ScanFeedback(
              isSuccess: true,
              isDuplicate: scanResult.isDuplicate,
              title: scanResult.isDuplicate ? 'Already Recorded' : 'Marked Present',
              subtitle: scanResult.message,
              studentName: scanResult.studentName,
              rollNumber: scanResult.rollNumber ?? scanResult.studentNo,
              timestamp: scanResult.timestamp,
            ),
          );

          ref.invalidate(eventAttendanceProvider(eventId));
          ref.invalidate(eventScopedStudentsFamilyProvider(eventId));
          ref.invalidate(eventStudentsProvider);
          ref.invalidate(studentsProvider);
        },
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _showFeedback(
        _ScanFeedback(
          isSuccess: false,
          isDuplicate: false,
          title: 'Scan Error',
          subtitle: e.toString(),
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      // Cooldown pause before releasing lock to allow next student scan
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showFeedback(_ScanFeedback feedback) {
    _feedbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _activeFeedback = feedback;
    });

    _feedbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _activeFeedback = null;
        });
      }
    });
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) {
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    }
  }

  void _showHistoryModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session Scans (${_sessionHistory.length})',
                      style: AppTextStyles.headlineSm,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (_sessionHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        'No students scanned in this session yet.',
                        style: AppTextStyles.bodyMd.copyWith(color: textSecondary),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _sessionHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _sessionHistory[index];
                        final name = item.studentName ?? 'Unknown Student';
                        final id = item.rollNumber ?? item.studentNo ?? 'N/A';
                        final color = item.isDuplicate
                            ? (isDark ? AppColors.warningDark : AppColors.warning)
                            : (isDark ? AppColors.successDark : AppColors.success);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.isDuplicate ? Icons.history_rounded : Icons.check_rounded,
                              color: color,
                              size: 18,
                            ),
                          ),
                          title: Text(name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(id, style: AppTextStyles.caption.copyWith(color: textSecondary)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.isDuplicate ? 'Duplicate' : 'Present',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.valueOrNull ?? [];
    final sortedEvents = EventEntity.sortChronologically(events);

    // Resolve active event:
    // 1. Manual user override in this screen
    EventEntity? event;
    if (_overrideEventId != null && _overrideEventId!.trim().isNotEmpty) {
      event = sortedEvents.where((e) => e.id == _overrideEventId).firstOrNull;
    }
    // 2. Event explicitly passed via navigation parameter
    if (event == null && widget.eventId.trim().isNotEmpty) {
      event = sortedEvents.where((e) => e.id == widget.eventId.trim()).firstOrNull;
    }
    // 3. Default event: ongoing event first, or closest upcoming event
    event ??= EventEntity.findDefaultEvent(sortedEvents);

    final effectiveEventId = event?.id ??
        (_overrideEventId?.trim().isNotEmpty == true
            ? _overrideEventId!
            : widget.eventId.trim());

    if (effectiveEventId.isEmpty) {
      if (eventsAsync.isLoading) {
        return _buildLoadingEventState();
      }
      return _buildNoEventState();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successColor = isDark ? AppColors.successDark : AppColors.success;
    final isOpen = event?.isAttendanceOpen ?? true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.errorDark.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_off_outlined, color: AppColors.errorDark, size: 44),
                        const SizedBox(height: 16),
                        Text(
                          'Camera Access Error',
                          style: AppTextStyles.headlineSm.copyWith(color: AppColors.errorDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.errorDetails?.message ?? error.errorCode.name,
                          style: AppTextStyles.bodySm.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _controller.start(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Restart Camera'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.trim().isNotEmpty) {
                  _processBarcode(rawValue, effectiveEventId);
                  break;
                }
              }
            },
          ),

          // Viewfinder Target Overlay
          _buildViewfinderOverlay(),

          // Top Header & Controls Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      tooltip: 'Exit Scanner',
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: sortedEvents.length > 1
                          ? () => _showEventSwitchSheet(sortedEvents, effectiveEventId)
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    event?.title ?? 'Attendance Scanner',
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isOpen ? successColor : AppColors.errorDark,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isOpen ? 'Attendance Open' : 'Attendance Closed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isOpen ? successColor : AppColors.errorDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (sortedEvents.length > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.unfold_more_rounded,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isTorchOn ? const Color(0xFFFF9F0A) : Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Toggle Flashlight',
                      onPressed: _toggleTorch,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 20),
                          tooltip: 'Session Scans',
                          onPressed: _showHistoryModal,
                        ),
                      ),
                      if (_sessionHistory.isNotEmpty)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2997FF),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${_sessionHistory.length}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                      tooltip: 'Manual Attendance Entry',
                      onPressed: () {
                        context.push('${RouteConstants.attendance}/manual?eventId=$effectiveEventId');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing Status Pill
          if (_isProcessing)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2997FF).withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2997FF)),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Verifying attendee...',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Scan Result Feedback Banner (Non-blocking: volunteer can scan next student immediately)
          if (_activeFeedback != null)
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: _buildFeedbackCard(_activeFeedback!),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(_ScanFeedback feedback) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = feedback.isSuccess
        ? (feedback.isDuplicate
            ? (isDark ? AppColors.warningDark : AppColors.warning)
            : (isDark ? AppColors.successDark : AppColors.success))
        : (isDark ? AppColors.errorDark : AppColors.error);

    final icon = feedback.isSuccess
        ? (feedback.isDuplicate ? Icons.info_outline_rounded : Icons.check_circle_rounded)
        : Icons.error_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1F).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      feedback.title,
                      style: AppTextStyles.labelMd.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (feedback.studentName != null && feedback.studentName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    feedback.studentName!,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (feedback.rollNumber != null && feedback.rollNumber!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    feedback.rollNumber!,
                    style: AppTextStyles.caption.copyWith(color: Colors.white60),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  feedback.subtitle,
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.70;
        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: CustomPaint(
                  painter: _AppleViewfinderPainter(
                    isProcessing: _isProcessing,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Align QR code within frame',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingEventState() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2997FF)),
            ),
            SizedBox(height: 16),
            Text(
              'Connecting to event gate...',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventSwitchSheet(List<EventEntity> events, String currentEventId) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white60 : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Event for Scanner',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000),
                    ),
                    itemBuilder: (context, index) {
                      final ev = events[index];
                      final isSelected = ev.id == currentEventId;
                      final isOngoing = ev.isOngoing;
                      final isUpcoming = ev.isUpcoming;
                      final statusLabel = isOngoing
                          ? 'ONGOING'
                          : (isUpcoming ? 'UPCOMING' : (ev.isPast ? 'PAST' : ev.status.toUpperCase()));
                      final statusColor = isOngoing
                          ? (isDark ? AppColors.successDark : AppColors.success)
                          : (isUpcoming
                              ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                              : textSecondary);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _overrideEventId = ev.id;
                          });
                          Navigator.pop(context);
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ev.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? AppColors.darkAccent : AppColors.lightAccent)
                                      : textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(ev.startDate),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                                size: 20,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoEventState() {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(title: 'QR Scanner', showBack: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: BrlGlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_busy_outlined, color: AppColors.errorDark, size: 52),
                  const SizedBox(height: 16),
                  Text(
                    'NO EVENT SELECTED',
                    style: AppTextStyles.headlineSm.copyWith(color: AppColors.errorDark),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'An active event must be selected before opening the entry gate scanner. Please choose an event from the Attendance Hub.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.darkTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BrlButton(
                    label: 'GO TO ATTENDANCE HUB',
                    onPressed: () => context.go(RouteConstants.attendance),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleViewfinderPainter extends CustomPainter {
  final bool isProcessing;

  const _AppleViewfinderPainter({required this.isProcessing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isProcessing ? const Color(0xFF2997FF) : Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const radius = 12.0;

    // Top-left
    final topLeft = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(topLeft, paint);

    // Top-right
    final topRight = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(topRight, paint);

    // Bottom-left
    final bottomLeft = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - radius)
      ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(bottomLeft, paint);

    // Bottom-right
    final bottomRight = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant _AppleViewfinderPainter oldDelegate) {
    return oldDelegate.isProcessing != isProcessing;
  }
}
