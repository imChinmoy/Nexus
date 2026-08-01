import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract interface class AttendanceRepository {
  Future<Either<Failure, void>> markManual({
    required String eventId,
    required String studentId,
    required String status,
  });
}
