import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/repositories/analytics_repository_impl.dart';
import '../data/sources/analytics_remote_source.dart';
import '../domain/entities/activity_heatmap_entity.dart';
import '../domain/repositories/analytics_repository.dart';

final analyticsRemoteSourceProvider = Provider<AnalyticsRemoteSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AnalyticsRemoteSourceImpl(dio);
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final remote = ref.watch(analyticsRemoteSourceProvider);
  return AnalyticsRepositoryImpl(remote);
});

class ActivityHeatmapParams extends Equatable {
  final int year;
  final String metric;
  final String? timezone;

  const ActivityHeatmapParams({
    required this.year,
    required this.metric,
    this.timezone,
  });

  @override
  List<Object?> get props => [year, metric, timezone];
}

final activityHeatmapProvider =
    FutureProvider.family<ActivityHeatmapEntity, ActivityHeatmapParams>(
        (ref, params) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final result = await repo.getActivityHeatmap(
    year: params.year,
    metric: params.metric,
    timezone: params.timezone,
  );

  return result.fold(
    (failure) => throw Exception(failure.message),
    (heatmap) => heatmap,
  );
});

final selectedHeatmapYearProvider =
    StateProvider<int>((ref) => DateTime.now().year);

final selectedHeatmapMetricProvider = StateProvider<String>((ref) => 'events');

final selectedHeatmapDateKeyProvider = StateProvider<String?>((ref) => null);
