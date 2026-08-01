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
  final String? phone;
  final String? domain;
  final String? github;
  final String? unstop;
  final String? hackerrank;
  final String? gender;
  final bool? hosteller;
  final List<CodingProfileEntity>? codingProfiles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.phone,
    this.domain,
    this.github,
    this.unstop,
    this.hackerrank,
    this.gender,
    this.hosteller,
    this.codingProfiles,
    this.createdAt,
    this.updatedAt,
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
        phone: json['phone'] as String?,
        domain: json['domain'] as String?,
        github: json['github'] as String?,
        unstop: json['unstop'] as String?,
        hackerrank: json['hackerrank'] as String?,
        gender: json['gender'] as String?,
        hosteller: json['hosteller'] as bool?,
        codingProfiles: (json['codingProfiles'] as List<dynamic>?)
            ?.map((e) => CodingProfileEntity(
                  platform: e['platform'] as String? ?? '',
                  username: e['username'] as String? ?? '',
                ))
            .toList(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
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
        phone: phone,
        domain: domain,
        github: github,
        unstop: unstop,
        hackerrank: hackerrank,
        gender: gender,
        hosteller: hosteller,
        codingProfiles: codingProfiles,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
