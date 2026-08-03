import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../../students/providers/student_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String eventId;
  const QrScannerScreen({super.key, this.eventId = ''});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.start();
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processScannedData(String rollNo) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final studentsResult = await studentRepo.getStudents(search: rollNo);

      studentsResult.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
          setState(() => _isProcessing = false);
        },
        (students) async {
          if (students.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student not found')));
            setState(() => _isProcessing = false);
            return;
          }

          final studentId = students.first.id;
          final attendanceRepo = ref.read(attendanceRepositoryProvider);
          final result = await attendanceRepo.markManual(
            eventId: widget.eventId,
            studentId: studentId,
            status: 'present',
          );

          result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
              setState(() => _isProcessing = false);
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked $rollNo as PRESENT')));
              ref.invalidate(eventAttendanceProvider(widget.eventId));
              ref.invalidate(studentsProvider);
              Navigator.pop(context); // Go back after successful scan
            },
          );
        }
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(title: 'QR Scanner', showBack: true, accentColor: AppColors.moduleAttendance),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Scanner Error: ${error.errorCode.name}\n${error.errorDetails?.message ?? ''}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processScannedData(barcode.rawValue!.trim());
                    break;
                  }
                }
              },
            ),
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
