import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/repositories/event_repository_impl.dart';
import '../data/sources/event_remote_source.dart';
import '../domain/entities/event_entity.dart';
import '../domain/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return EventRepositoryImpl(EventRemoteSourceImpl(dio));
});

final eventsProvider = FutureProvider<List<EventEntity>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  final result = await repository.getEvents();
  return result.fold(
    (failure) => throw failure.message,
    (events) => events,
  );
});
