import '../../domain/entities/student_entity.dart';

class StudentModel {
  final String id;
  final String name;
  final String rollNumber;
  final String studentNo;
  final String branch;
  final int year;
  final String email;
  final int attendance;

  const StudentModel({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.studentNo,
    required this.branch,
    required this.year,
    required this.email,
    this.attendance = 0,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        rollNumber: json['rollNo'] as String? ?? json['rollNumber'] as String? ?? '',
        studentNo: json['studentNo'] as String? ?? '',
        branch: json['branch'] as String? ?? '',
        year: json['year'] as int? ?? 1,
        email: json['email'] as String? ?? '',
        attendance: json['attendance'] as int? ?? 0,
      );

  StudentEntity toEntity() => StudentEntity(
        id: id,
        name: name,
        rollNumber: rollNumber,
        studentNo: studentNo,
        branch: branch,
        year: year,
        email: email,
        attendance: attendance,
      );
}
