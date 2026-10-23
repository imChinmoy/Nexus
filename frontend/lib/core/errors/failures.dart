import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final String? code;

  const Failure(this.message, {this.statusCode, this.code});

  @override
  List<Object?> get props => [message, statusCode, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.statusCode, super.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode, super.code});
}


class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode});
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(super.message, {this.fieldErrors, super.statusCode});

  @override
  List<Object?> get props => [message, fieldErrors, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message) : super(statusCode: 404);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message) : super(statusCode: 401);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message) : super(statusCode: 403);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
