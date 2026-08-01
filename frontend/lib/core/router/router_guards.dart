import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_state.dart';
import '../constants/route_constants.dart';

String? authGuard(WidgetRef ref, GoRouterState state) {
  final authState = ref.read(authNotifierProvider);
  final isAuthRoute = state.matchedLocation == RouteConstants.login ||
      state.matchedLocation == RouteConstants.forgotPassword ||
      state.matchedLocation.startsWith(RouteConstants.resetPassword);

  return authState.when(
    initial: () => null,
    loading: () => null,
    authenticated: (_) => isAuthRoute ? RouteConstants.dashboard : null,
    unauthenticated: () => isAuthRoute ? null : RouteConstants.login,
    error: (_) => isAuthRoute ? null : RouteConstants.login,
  );
}
