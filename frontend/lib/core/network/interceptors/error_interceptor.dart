import 'package:dio/dio.dart';
import '../../errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const NetworkException('Connection timed out. Check your internet.');
      case DioExceptionType.connectionError:
        throw const NetworkException('No internet connection.');
      case DioExceptionType.badResponse:
        _handleResponseError(err);
      default:
        handler.next(err);
    }
  }

  Never _handleResponseError(DioException err) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    final message = data is Map ? (data['message'] ?? 'An error occurred') : 'An error occurred';

    switch (statusCode) {
      case 400:
        final errors = data is Map ? (data['errors'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) : null;
        throw ValidationException(message.toString(), fieldErrors: errors);
      case 401:
        throw UnauthorizedException(message.toString());
      case 403:
        throw ForbiddenException(message.toString());
      case 404:
        throw NotFoundException(message.toString());
      case 422:
        throw ValidationException(message.toString());
      case 500:
      case 502:
      case 503:
        throw ServerException(message.toString(), statusCode: statusCode);
      default:
        throw ServerException(message.toString(), statusCode: statusCode);
    }
  }
}
