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
  final bool isPresent;

  const StudentModel({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.studentNo,
    required this.branch,
    required this.year,
    required this.email,
    this.attendance = 0,
    this.isPresent = false,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        rollNumber: json['rollNo'] as String? ?? json['rollNumber'] as String? ?? '',
        studentNo: json['studentNo'] as String? ?? '',
        branch: json['branch'] as String? ?? '',
        year: json['year'] as int? ?? 2,
        email: json['email'] as String? ?? '',
        attendance: json['attendance'] as int? ?? 0,
        isPresent: json['isPresent'] as bool? ?? false,
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
        isPresent: isPresent,
      );
}
