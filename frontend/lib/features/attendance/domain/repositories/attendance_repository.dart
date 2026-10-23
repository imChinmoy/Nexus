import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/scan_attendance_result.dart';

abstract interface class AttendanceRepository {
  Future<Either<Failure, ScanAttendanceResult>> scanAttendance({
    required String eventId,
    required String qrValue,
  });

  Future<Either<Failure, void>> markManual({
    required String eventId,
    required String studentId,
    required String status,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getAttendanceByEvent(String eventId);
}
