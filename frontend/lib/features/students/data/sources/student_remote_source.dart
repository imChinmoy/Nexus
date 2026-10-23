import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/student_model.dart';

abstract interface class StudentRemoteSource {
  Future<List<StudentModel>> getStudents({String? search});

  Future<EventStudentsResultModel> getStudentsByEvent(
    String eventId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? branch,
    String? attendanceStatus,
  });

  Future<StudentModel> createStudent({
    required String name,
    required String rollNumber,
    required String branch,
    required int year,
    required String email,
    required String phone,
  });
}

class StudentRemoteSourceImpl implements StudentRemoteSource {
  final Dio _dio;

  StudentRemoteSourceImpl(this._dio);

  @override
  Future<List<StudentModel>> getStudents({String? search}) async {
    try {
      final Map<String, dynamic> queryParams = {'limit': 1000};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      final response = await _dio.get(
        ApiConstants.students,
        queryParameters: queryParams,
      );
      if (response.data['data'] == null) return [];
      return (response.data['data'] as List)
          .map((json) => StudentModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to fetch students: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch students: ${e.toString()}');
    }
  }

  @override
  Future<EventStudentsResultModel> getStudentsByEvent(
    String eventId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? branch,
    String? attendanceStatus,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (branch != null && branch.trim().isNotEmpty && branch != 'All') {
        queryParams['branch'] = branch.trim();
      }
      if (attendanceStatus != null && attendanceStatus.trim().isNotEmpty && attendanceStatus.toLowerCase() != 'all') {
        queryParams['attendanceStatus'] = attendanceStatus.trim();
      }

      final response = await _dio.get(
        ApiConstants.eventStudents(eventId),
        queryParameters: queryParams,
      );

      return EventStudentsResultModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      final serverMessage = e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerException(serverMessage ?? 'Failed to fetch event students: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch event students: ${e.toString()}');
    }
  }

  @override
  Future<StudentModel> createStudent({
    required String name,
    required String rollNumber,
    required String branch,
    required int year,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.students,
        data: {
          'name': name,
          'rollNumber': rollNumber,
          'branch': branch,
          'year': year,
          'email': email,
          'phone': phone,
        },
      );
      return StudentModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to create student: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create student: ${e.toString()}');
    }
  }
}
