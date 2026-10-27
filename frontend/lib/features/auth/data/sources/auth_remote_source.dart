import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteSource {
  Future<AuthResponseModel> login(
      {required String email, required String password});
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String secretKey,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  });
  Future<void> logout(String? refreshToken);
  Future<UserModel> getCurrentUser();
  Future<String> refreshToken(String token);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(
      {required String token, required String newPassword});
  Future<void> changePassword(
      {required String currentPassword, required String newPassword});
  Future<UserModel> updateProfile({
    String? name,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  });
  Future<UserModel> updateAvatar(File imageFile);
}

class AuthRemoteSourceImpl implements AuthRemoteSource {
  final Dio _dio;

  AuthRemoteSourceImpl(this._dio);

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      final serverMsg =
          e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerException(serverMsg ?? 'Login failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    required String secretKey,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'secretKey': secretKey,
          if (year != null && year.isNotEmpty) 'year': year,
          if (domain != null && domain.isNotEmpty) 'domain': domain,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (bio != null && bio.isNotEmpty) 'bio': bio,
          if (github != null && github.isNotEmpty) 'github': github,
          if (linkedin != null && linkedin.isNotEmpty) 'linkedin': linkedin,
        },
      );
      return AuthResponseModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      final serverMsg =
          e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerException(serverMsg ?? 'Registration failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post(
        ApiConstants.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : null,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Logout failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to get user: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to get user: ${e.toString()}');
    }
  }

  @override
  Future<String> refreshToken(String token) async {
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': token},
      );
      return response.data['data']['accessToken'] as String;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Token refresh failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Token refresh failed: ${e.toString()}');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiConstants.resetPassword,
        data: {'token': token, 'password': newPassword},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Reset failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Reset failed: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiConstants.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Change password failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Change password failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.me,
        data: {
          if (name != null) 'name': name,
          if (year != null) 'year': year,
          if (domain != null) 'domain': domain,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
          if (github != null) 'github': github,
          if (linkedin != null) 'linkedin': linkedin,
        },
      );
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Update profile failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Update profile failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateAvatar(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'avatar':
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _dio.put(
        ApiConstants.updateAvatar,
        data: formData,
      );
      return UserModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Update avatar failed: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Update avatar failed: ${e.toString()}');
    }
  }
}
