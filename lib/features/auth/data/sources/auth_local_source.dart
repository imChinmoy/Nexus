import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

abstract interface class AuthLocalSource {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAuth();
}

class AuthLocalSourceImpl implements AuthLocalSource {
  final SecureStorageService _storage;

  AuthLocalSourceImpl(this._storage);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(AppConstants.accessTokenKey, accessToken),
      _storage.write(AppConstants.refreshTokenKey, refreshToken),
    ]);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _storage.write(
      AppConstants.userDataKey,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> getUser() async {
    final data = await _storage.read(AppConstants.userDataKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearAuth() async {
    await Future.wait([
      _storage.delete(AppConstants.accessTokenKey),
      _storage.delete(AppConstants.refreshTokenKey),
      _storage.delete(AppConstants.userDataKey),
    ]);
  }
}
