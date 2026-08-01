import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/repositories/attendance_repository_impl.dart';
import '../data/sources/attendance_remote_source.dart';
import '../domain/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AttendanceRepositoryImpl(AttendanceRemoteSourceImpl(dio));
});
