import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/event_model.dart';

abstract interface class EventRemoteSource {
  Future<List<EventModel>> getEvents();
  Future<EventModel> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required int capacity,
    String? description,
    String? venue,
    String? bannerPath,
  });
  Future<EventModel> updateEvent(
    String id, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? capacity,
    String? description,
    String? venue,
    String? bannerPath,
  });
}

class EventRemoteSourceImpl implements EventRemoteSource {
  final Dio _dio;

  EventRemoteSourceImpl(this._dio);

  @override
  Future<List<EventModel>> getEvents() async {
    try {
      final response = await _dio.get(ApiConstants.events);
      if (response.data['data'] == null) return [];
      return (response.data['data'] as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to fetch events: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch events: ${e.toString()}');
    }
  }

  @override
  Future<EventModel> createEvent({
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
      final formData = FormData.fromMap({
        'title': title,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'type': type,
        'capacity': capacity,
        if (description != null) 'description': description,
        if (venue != null) 'venue': venue,
      });

      if (bannerPath != null) {
        formData.files.add(
          MapEntry('banner', await MultipartFile.fromFile(bannerPath)),
        );
      }

      final response = await _dio.post(
        ApiConstants.events,
        data: formData,
      );
      return EventModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to create event: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create event: ${e.toString()}');
    }
  }

  @override
  Future<EventModel> updateEvent(
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
      final mapData = <String, dynamic>{};
      if (title != null) mapData['title'] = title;
      if (startDate != null) mapData['startDate'] = startDate.toUtc().toIso8601String();
      if (endDate != null) mapData['endDate'] = endDate.toUtc().toIso8601String();
      if (type != null) mapData['type'] = type;
      if (capacity != null) mapData['capacity'] = capacity;
      if (description != null) mapData['description'] = description;
      if (venue != null) mapData['venue'] = venue;
      
      final formData = FormData.fromMap(mapData);

      if (bannerPath != null && bannerPath.isNotEmpty) {
        formData.files.add(
          MapEntry('banner', await MultipartFile.fromFile(bannerPath)),
        );
      }

      final response = await _dio.put(
        '${ApiConstants.events}/$id',
        data: formData,
      );
      return EventModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw ServerException('Failed to update event: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update event: ${e.toString()}');
    }
  }
}
