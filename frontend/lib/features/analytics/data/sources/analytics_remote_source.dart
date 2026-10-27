import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/activity_heatmap_model.dart';

abstract interface class AnalyticsRemoteSource {
  Future<ActivityHeatmapModel> getActivityHeatmap({
    required int year,
    required String metric,
    String? timezone,
  });
}

class AnalyticsRemoteSourceImpl implements AnalyticsRemoteSource {
  final Dio _dio;

  AnalyticsRemoteSourceImpl(this._dio);

  @override
  Future<ActivityHeatmapModel> getActivityHeatmap({
    required int year,
    required String metric,
    String? timezone,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'year': year,
        'metric': metric,
      };
      if (timezone != null && timezone.isNotEmpty) {
        queryParams['timezone'] = timezone;
      }

      final response = await _dio.get(
        ApiConstants.analyticsHeatmap,
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      if (data == null) {
        throw const ServerException('Invalid response structure: data is null');
      }

      return ActivityHeatmapModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to fetch activity heatmap: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
          'Failed to fetch activity heatmap: ${e.toString()}');
    }
  }
}
