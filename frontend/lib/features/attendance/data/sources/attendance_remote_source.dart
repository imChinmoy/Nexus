import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';

abstract interface class AttendanceRemoteSource {
  Future<void> markManual({
    required String eventId,
    required String studentId,
    required String status,
  });

  Future<List<Map<String, dynamic>>> getAttendanceByEvent(String eventId);
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
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to mark attendance: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to mark attendance: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAttendanceByEvent(String eventId) async {
    try {
      final response = await _dio.get(ApiConstants.attendanceByEvent(eventId));
      if (response.data['data'] == null) return [];
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to fetch event attendance: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch event attendance: ${e.toString()}');
    }
  }
}
