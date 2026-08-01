import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/student_model.dart';

abstract interface class StudentRemoteSource {
  Future<List<StudentModel>> getStudents();
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
  Future<List<StudentModel>> getStudents() async {
    try {
      final response = await _dio.get(ApiConstants.students);
      if (response.data['data'] == null) return [];
      return (response.data['data'] as List)
          .map((json) => StudentModel.fromJson(json))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch students: ${e.toString()}');
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
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create student: ${e.toString()}');
    }
  }
}
