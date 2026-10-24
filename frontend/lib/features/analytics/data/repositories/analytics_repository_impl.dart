import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/activity_heatmap_entity.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../sources/analytics_remote_source.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteSource _remote;

  AnalyticsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, ActivityHeatmapEntity>> getActivityHeatmap({
    required int year,
    required String metric,
    String? timezone,
  }) async {
    try {
      final model = await _remote.getActivityHeatmap(
        year: year,
        metric: metric,
        timezone: timezone,
      );
      return Right(model);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
