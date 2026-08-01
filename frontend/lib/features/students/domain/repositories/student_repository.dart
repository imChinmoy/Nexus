import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/student_entity.dart';

abstract interface class StudentRepository {
  Future<Either<Failure, List<StudentEntity>>> getStudents();
  Future<Either<Failure, StudentEntity>> createStudent({
    required String name,
    required String rollNumber,
    required String branch,
    required int year,
    required String email,
    required String phone,
  });
}
