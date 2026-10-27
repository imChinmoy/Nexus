import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failures.dart';
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

final splashAnimationCompletedProvider = StateProvider<bool>((ref) => false);

final myPermissionsProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

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
    try {
      final isLoggedIn = await _repo.isLoggedIn();
      if (!isLoggedIn) {
        state = const AuthState.unauthenticated();
        return;
      }

      // 1. Instant Cache-First Session Restoration:
      // If we have a cached user profile saved locally, authenticate immediately.
      // This eliminates network blocking during splash screen so the app launches instantaneously.
      final cachedUser = await _repo.getCachedUser();
      if (cachedUser != null) {
        state = AuthState.authenticated(cachedUser);
        // Revalidate profile in background without blocking splash or app launch
        _revalidateSession();
        return;
      }

      // 2. Fallback if no cached user profile found: fetch with a quick 4-second timeout
      final result = await _repo.getCurrentUser().timeout(
            const Duration(seconds: 4),
            onTimeout: () =>
                const Left(NetworkFailure('Auth verification timeout')),
          );
      result.fold(
        (failure) => state = const AuthState.unauthenticated(),
        (user) => state = AuthState.authenticated(user),
      );
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> _revalidateSession() async {
    try {
      final result = await _repo.getCurrentUser();
      result.fold(
        (failure) {
          if (failure is UnauthorizedFailure) {
            logout();
          }
        },
        (user) {
          if (mounted) {
            state = AuthState.authenticated(user);
          }
        },
      );
    } catch (_) {
      // Retain cached session if background revalidation fails
    }
  }

  Future<void> refreshCurrentUser() => _revalidateSession();

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

  Future<bool> register({
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
    state = const AuthState.loading();
    final result = await _repo.register(
      name: name,
      email: email,
      password: password,
      secretKey: secretKey,
      year: year,
      domain: domain,
      phone: phone,
      bio: bio,
      github: github,
      linkedin: linkedin,
    );
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

  void clearError() {
    if (state is AuthError) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }

  UserEntity? get currentUser => state.whenOrNull(
        authenticated: (user) => user,
      );

  Future<String?> updateProfile({
    String? name,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  }) async {
    final result = await _repo.updateProfile(
      name: name,
      year: year,
      domain: domain,
      phone: phone,
      bio: bio,
      github: github,
      linkedin: linkedin,
    );
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
