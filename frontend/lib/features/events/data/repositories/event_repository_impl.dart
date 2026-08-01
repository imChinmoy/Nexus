import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../sources/event_remote_source.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteSource _remote;

  EventRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<EventEntity>>> getEvents() async {
    try {
      final models = await _remote.getEvents();
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventEntity>> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required int capacity,
    String? description,
    String? venue,
    String? bannerPath,
  }) async {
    try {
      final model = await _remote.createEvent(
        title: title,
        startDate: startDate,
        endDate: endDate,
        type: type,
        capacity: capacity,
        description: description,
        venue: venue,
        bannerPath: bannerPath,
      );
      return Right(model.toEntity());
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventEntity>> updateEvent(
    String id, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? capacity,
    String? description,
    String? venue,
    String? bannerPath,
  }) async {
    try {
      final model = await _remote.updateEvent(
        id,
        title: title,
        startDate: startDate,
        endDate: endDate,
        type: type,
        capacity: capacity,
        description: description,
        venue: venue,
        bannerPath: bannerPath,
      );
      return Right(model.toEntity());
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
