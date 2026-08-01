import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../sources/student_remote_source.dart';

class StudentRepositoryImpl implements StudentRepository {
  final StudentRemoteSource _remote;

  StudentRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<StudentEntity>>> getStudents({String? search}) async {
    try {
      final models = await _remote.getStudents(search: search);
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StudentEntity>> createStudent({
    required String name,
    required String rollNumber,
    required String branch,
    required int year,
    required String email,
    required String phone,
  }) async {
    try {
      final model = await _remote.createStudent(
        name: name,
        rollNumber: rollNumber,
        branch: branch,
        year: year,
        email: email,
        phone: phone,
      );
      return Right(model.toEntity());
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
