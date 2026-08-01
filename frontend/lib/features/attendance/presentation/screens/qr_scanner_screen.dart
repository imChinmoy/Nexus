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

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
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
            status: 'PRESENT',
          );

          result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
              setState(() => _isProcessing = false);
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked $rollNo as PRESENT')));
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
