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
  final String?
      attendanceStatus; // 'present', 'absent', 'late', 'excused', or null (not marked)
  final DateTime? markedAt;
  final String? markedMethod;
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
    this.attendanceStatus,
    this.markedAt,
    this.markedMethod,
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

class EventStudentCountsEntity {
  final int total;
  final int present;
  final int notMarked;
  final int absent;
  final int late;
  final int excused;

  const EventStudentCountsEntity({
    this.total = 0,
    this.present = 0,
    this.notMarked = 0,
    this.absent = 0,
    this.late = 0,
    this.excused = 0,
  });
}

class EventStudentsResultEntity {
  final List<StudentEntity> students;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final EventStudentCountsEntity counts;

  const EventStudentsResultEntity({
    required this.students,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.counts,
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
