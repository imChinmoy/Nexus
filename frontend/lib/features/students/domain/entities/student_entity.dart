class StudentEntity {
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

  const StudentEntity({
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
}

class CodingProfileEntity {
  final String platform;
  final String username;

  const CodingProfileEntity({
    required this.platform,
    required this.username,
  });
}
