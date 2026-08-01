import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/repositories/student_repository_impl.dart';
import '../data/sources/student_remote_source.dart';
import '../domain/entities/student_entity.dart';
import '../domain/repositories/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return StudentRepositoryImpl(StudentRemoteSourceImpl(dio));
});

final studentsProvider = FutureProvider.autoDispose<List<StudentEntity>>((ref) async {
  final repository = ref.watch(studentRepositoryProvider);
  final result = await repository.getStudents();
  return result.fold(
    (failure) => throw failure.message,
    (students) => students,
  );
});
