import '../domain/entities/user_entity.dart';

/// Sealed-style auth state without freezed code generation.
abstract class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(UserEntity user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(UserEntity user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    final s = this;
    if (s is AuthInitial) return initial();
    if (s is AuthLoading) return loading();
    if (s is AuthAuthenticated) return authenticated(s.user);
    if (s is AuthUnauthenticated) return unauthenticated();
    if (s is AuthError) return error(s.message);
    throw StateError('Unknown AuthState: $s');
  }

  T? whenOrNull<T>({
    T? Function()? initial,
    T? Function()? loading,
    T? Function(UserEntity user)? authenticated,
    T? Function()? unauthenticated,
    T? Function(String message)? error,
  }) {
    final s = this;
    if (s is AuthInitial) return initial?.call();
    if (s is AuthLoading) return loading?.call();
    if (s is AuthAuthenticated) return authenticated?.call(s.user);
    if (s is AuthUnauthenticated) return unauthenticated?.call();
    if (s is AuthError) return error?.call(s.message);
    return null;
  }
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
