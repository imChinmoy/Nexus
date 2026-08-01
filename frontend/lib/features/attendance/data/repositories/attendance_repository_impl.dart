import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../sources/attendance_remote_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteSource _remote;

  AttendanceRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, void>> markManual({
    required String eventId,
    required String studentId,
    required String status,
  }) async {
    try {
      await _remote.markManual(
        eventId: eventId,
        studentId: studentId,
        status: status,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAttendanceByEvent(String eventId) async {
    try {
      final result = await _remote.getAttendanceByEvent(eventId);
      return Right(result);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
