import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/repositories/student_repository_impl.dart';
import '../data/sources/student_remote_source.dart';
import '../domain/entities/student_entity.dart';
import '../domain/repositories/student_repository.dart';

import '../../events/domain/entities/event_entity.dart';
import '../../events/providers/event_provider.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return StudentRepositoryImpl(StudentRemoteSourceImpl(dio));
});

final selectedEventIdProvider = StateProvider<String?>((ref) => null);
final studentSearchQueryProvider = StateProvider<String>((ref) => '');
final studentBranchFilterProvider = StateProvider<String>((ref) => 'All');
final studentAttendanceFilterProvider = StateProvider<String>((ref) => 'All');
final studentPageProvider = StateProvider<int>((ref) => 1);

/// Event-scoped students provider with server-side search, filtering, and pagination.
final eventStudentsProvider = FutureProvider.autoDispose<EventStudentsResultEntity?>((ref) async {
  String? eventId = ref.watch(selectedEventIdProvider);
  if (eventId == null || eventId.trim().isEmpty) {
    final eventsAsync = ref.watch(eventsProvider);
    final events = eventsAsync.valueOrNull;
    if (events != null && events.isNotEmpty) {
      final sorted = EventEntity.sortChronologically(events);
      final defaultEvent = EventEntity.findDefaultEvent(sorted);
      if (defaultEvent != null) {
        eventId = defaultEvent.id;
      }
    }
  }
  if (eventId == null || eventId.trim().isEmpty) {
    return null;
  }

  final repository = ref.watch(studentRepositoryProvider);
  final search = ref.watch(studentSearchQueryProvider);
  final branch = ref.watch(studentBranchFilterProvider);
  final attendanceStatus = ref.watch(studentAttendanceFilterProvider);
  final page = ref.watch(studentPageProvider);

  String? normalizedStatus;
  if (attendanceStatus != 'All') {
    final lower = attendanceStatus.toLowerCase();
    if (lower == 'not scanned' || lower == 'not marked') {
      normalizedStatus = 'not_marked';
    } else {
      normalizedStatus = lower;
    }
  }

  final result = await repository.getStudentsByEvent(
    eventId,
    page: page,
    limit: 20,
    search: search.trim().isNotEmpty ? search.trim() : null,
    branch: branch != 'All' ? branch : null,
    attendanceStatus: normalizedStatus,
  );

  return result.fold(
    (failure) => throw failure.message,
    (res) => res,
  );
});

/// Backward-compatible students list provider for detail views and legacy workflows.
final studentsProvider = FutureProvider.autoDispose<List<StudentEntity>>((ref) async {
  final eventId = ref.watch(selectedEventIdProvider);
  if (eventId != null && eventId.trim().isNotEmpty) {
    try {
      final eventResult = await ref.watch(eventStudentsProvider.future);
      if (eventResult != null && eventResult.students.isNotEmpty) {
        return eventResult.students;
      }
    } catch (_) {
      // Fallback gracefully to default students query if event-scoped registrations fail
    }
  }

  final repository = ref.watch(studentRepositoryProvider);
  final result = await repository.getStudents();
  return result.fold(
    (failure) => throw failure.message,
    (students) => students,
  );
});

/// Family provider for fetching event-scoped student registrations and live counts.
final eventScopedStudentsFamilyProvider = FutureProvider.family<EventStudentsResultEntity?, String>((ref, eventId) async {
  if (eventId.trim().isEmpty) return null;
  final repository = ref.watch(studentRepositoryProvider);
  final result = await repository.getStudentsByEvent(eventId, limit: 100);
  return result.fold(
    (failure) => null,
    (res) => res,
  );
});

