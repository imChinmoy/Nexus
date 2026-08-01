import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/dio_client.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/sources/auth_local_source.dart';
import '../data/sources/auth_remote_source.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(
    AuthRemoteSourceImpl(dio),
    AuthLocalSourceImpl(storage),
  );
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final myPermissionsProvider = FutureProvider<List<String>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/auth/my-permissions');
  if (response.statusCode == 200) {
    final data = response.data['data'] as List;
    return data.map((e) => e.toString()).toList();
  }
  return [];
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.whenOrNull(authenticated: (user) => user);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState.initial());

  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();
    final isLoggedIn = await _repo.isLoggedIn();
    if (!isLoggedIn) {
      state = const AuthState.unauthenticated();
      return;
    }
    final result = await _repo.getCurrentUser();
    result.fold(
      (failure) => state = const AuthState.unauthenticated(),
      (user) => state = AuthState.authenticated(user),
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState.loading();
    final result = await _repo.login(email: email, password: password);
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (data) {
        state = AuthState.authenticated(data.user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }

  UserEntity? get currentUser => state.whenOrNull(
        authenticated: (user) => user,
      );

  Future<String?> updateProfile({String? name}) async {
    final result = await _repo.updateProfile(name: name);
    return result.fold(
      (failure) => failure.message,
      (user) {
        state = AuthState.authenticated(user);
        return null;
      },
    );
  }

  Future<String?> updateAvatar(File imageFile) async {
    final result = await _repo.updateAvatar(imageFile);
    return result.fold(
      (failure) => failure.message,
      (user) {
        state = AuthState.authenticated(user);
        return null;
      },
    );
  }
}
