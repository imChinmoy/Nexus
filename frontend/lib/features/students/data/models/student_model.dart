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
  final String? attendanceStatus;
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

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final id = json['studentId'] as String? ?? json['_id'] as String? ?? json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final rollNumber = json['rollNo'] as String? ?? json['rollNumber'] as String? ?? '';
    final studentNo = json['studentNo'] as String? ?? json['studentNumber'] as String? ?? '';
    final branch = json['branch'] as String? ?? '';
    final year = json['year'] as int? ?? 2;
    final email = json['email'] as String? ?? '';

    String? attStatus;
    DateTime? markedAt;
    String? markedMethod;
    int attPercent = 0;
    bool isPresent = false;

    if (json['attendance'] is Map) {
      final attMap = json['attendance'] as Map<String, dynamic>;
      attStatus = (attMap['status'] as String?)?.toLowerCase().trim();
      markedAt = attMap['markedAt'] != null ? DateTime.tryParse(attMap['markedAt'].toString()) : null;
      markedMethod = attMap['method'] as String?;
      isPresent = attStatus == 'present' || attStatus == 'late';
      attPercent = isPresent ? 100 : 0;
    } else if (json['attendance'] is num) {
      attPercent = (json['attendance'] as num).toInt();
      isPresent = json['isPresent'] as bool? ?? (attPercent >= 75);
      if (isPresent) attStatus = 'present';
    } else {
      isPresent = json['isPresent'] as bool? ?? false;
      if (isPresent) attStatus = 'present';
    }

    return StudentModel(
      id: id,
      name: name,
      rollNumber: rollNumber,
      studentNo: studentNo,
      branch: branch,
      year: year,
      email: email,
      attendance: attPercent,
      isPresent: isPresent,
      attendanceStatus: attStatus,
      markedAt: markedAt,
      markedMethod: markedMethod,
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
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

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
        attendanceStatus: attendanceStatus,
        markedAt: markedAt,
        markedMethod: markedMethod,
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

class EventStudentCountsModel {
  final int total;
  final int present;
  final int notMarked;
  final int absent;
  final int late;
  final int excused;

  const EventStudentCountsModel({
    this.total = 0,
    this.present = 0,
    this.notMarked = 0,
    this.absent = 0,
    this.late = 0,
    this.excused = 0,
  });

  factory EventStudentCountsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EventStudentCountsModel();
    return EventStudentCountsModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      notMarked: (json['notMarked'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      excused: (json['excused'] as num?)?.toInt() ?? 0,
    );
  }

  EventStudentCountsEntity toEntity() => EventStudentCountsEntity(
        total: total,
        present: present,
        notMarked: notMarked,
        absent: absent,
        late: late,
        excused: excused,
      );
}

class EventStudentsResultModel {
  final List<StudentModel> students;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final EventStudentCountsModel counts;

  const EventStudentsResultModel({
    required this.students,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.counts,
  });

  factory EventStudentsResultModel.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final total = (meta['total'] as num?)?.toInt() ?? list.length;
    final page = (meta['page'] as num?)?.toInt() ?? 1;
    final limit = (meta['limit'] as num?)?.toInt() ?? 20;
    final totalPages = (meta['totalPages'] as num?)?.toInt() ?? (total > 0 ? (total / limit).ceil() : 0);

    final countsJson = json['counts'] as Map<String, dynamic>? ?? (meta['counts'] as Map<String, dynamic>?);
    final counts = EventStudentCountsModel.fromJson(countsJson);

    return EventStudentsResultModel(
      students: list,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      counts: counts,
    );
  }

  EventStudentsResultEntity toEntity() => EventStudentsResultEntity(
        students: students.map((m) => m.toEntity()).toList(),
        total: total,
        page: page,
        limit: limit,
        totalPages: totalPages,
        counts: counts.toEntity(),
      );
}
