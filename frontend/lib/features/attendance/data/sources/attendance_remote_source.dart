import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';

abstract interface class AttendanceRemoteSource {
  Future<void> markManual({
    required String eventId,
    required String studentId,
    required String status,
  });
}

class AttendanceRemoteSourceImpl implements AttendanceRemoteSource {
  final Dio _dio;

  AttendanceRemoteSourceImpl(this._dio);

  @override
  Future<void> markManual({
    required String eventId,
    required String studentId,
    required String status,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.attendanceByEvent(eventId)}/manual',
        data: {
          'studentId': studentId,
          'status': status,
        },
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to mark attendance: ${e.toString()}');
    }
  }
}
