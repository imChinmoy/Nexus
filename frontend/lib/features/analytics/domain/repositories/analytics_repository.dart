import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/activity_heatmap_entity.dart';

abstract interface class AnalyticsRepository {
  Future<Either<Failure, ActivityHeatmapEntity>> getActivityHeatmap({
    required int year,
    required String metric,
    String? timezone,
  });
}
