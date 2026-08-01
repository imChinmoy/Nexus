import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/event_entity.dart';

abstract interface class EventRepository {
  Future<Either<Failure, List<EventEntity>>> getEvents();
  Future<Either<Failure, EventEntity>> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required int capacity,
    String? description,
    String? venue,
    String? bannerPath,
  });
}
