class ScanAttendanceResult {
  final bool success;
  final String code;
  final String message;
  final bool isDuplicate;
  final String? attendanceId;
  final String? studentName;
  final String? rollNumber;
  final String? studentNo;
  final String? branch;
  final String status;
  final DateTime timestamp;

  const ScanAttendanceResult({
    required this.success,
    required this.code,
    required this.message,
    required this.isDuplicate,
    this.attendanceId,
    this.studentName,
    this.rollNumber,
    this.studentNo,
    this.branch,
    this.status = 'present',
    required this.timestamp,
  });

  factory ScanAttendanceResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? true;
    final code = json['code'] as String? ?? 'ATTENDANCE_MARKED';
    final message = json['message'] as String? ?? '';
    final isDuplicate = code == 'ALREADY_MARKED';

    final data = json['data'] as Map<String, dynamic>?;
    String? attendanceId;
    String? studentName;
    String? rollNumber;
    String? studentNo;
    String? branch;
    String status = 'present';
    DateTime timestamp = DateTime.now();

    if (data != null) {
      attendanceId = data['_id'] as String? ?? data['id'] as String?;
      status = data['status'] as String? ?? 'present';
      if (data['markedAt'] != null) {
        timestamp = DateTime.tryParse(data['markedAt'] as String) ?? DateTime.now();
      }

      final student = data['student'];
      if (student is Map<String, dynamic>) {
        studentName = student['name'] as String?;
        rollNumber = student['rollNo'] as String? ?? student['rollNumber'] as String?;
        studentNo = student['studentNo'] as String?;
        branch = student['branch'] as String?;
      }
    }

    return ScanAttendanceResult(
      success: success,
      code: code,
      message: message,
      isDuplicate: isDuplicate,
      attendanceId: attendanceId,
      studentName: studentName,
      rollNumber: rollNumber,
      studentNo: studentNo,
      branch: branch,
      status: status,
      timestamp: timestamp,
    );
  }
}
