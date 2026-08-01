import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteSource {
  Future<AuthResponseModel> login({required String email, required String password});
  Future<void> logout(String? refreshToken);
  Future<UserModel> getCurrentUser();
  Future<String> refreshToken(String token);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({required String token, required String newPassword});
  Future<void> changePassword({required String currentPassword, required String newPassword});
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
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post(
        ApiConstants.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : null,
      );
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
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Change password failed: ${e.toString()}');
    }
  }
}
