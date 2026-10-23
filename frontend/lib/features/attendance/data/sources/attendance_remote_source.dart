import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/scan_attendance_result.dart';

abstract interface class AttendanceRemoteSource {
  Future<ScanAttendanceResult> scanAttendance({
    required String eventId,
    required String qrValue,
  });

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
  Future<ScanAttendanceResult> scanAttendance({
    required String eventId,
    required String qrValue,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.eventScanAttendance(eventId),
        data: {'qrValue': qrValue},
      );
      final data = response.data as Map<String, dynamic>;
      return ScanAttendanceResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Scan attendance failed';
        final code = data['code'] as String?;
        throw ServerException(
          message,
          statusCode: e.response?.statusCode,
          code: code,
          data: data,
        );
      }
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException(
        'Failed to scan attendance: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to scan attendance: ${e.toString()}');
    }
  }

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
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        final message = data['message'] as String? ?? 'Failed to mark attendance';
        final code = data['code'] as String?;
        throw ServerException(message, statusCode: e.response?.statusCode, code: code);
      }
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
