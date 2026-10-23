import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/exceptions.dart';
import 'package:brl_nexus/features/attendance/data/models/scan_attendance_result.dart';
import 'package:brl_nexus/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:brl_nexus/features/attendance/data/sources/attendance_remote_source.dart';
import 'package:brl_nexus/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:brl_nexus/features/attendance/presentation/screens/qr_scanner_screen.dart';

class MockAttendanceRemoteSource implements AttendanceRemoteSource {
  bool shouldFail = false;
  bool isDuplicate = false;
  int scanCallCount = 0;
  String? lastEventId;
  String? lastQrValue;

  @override
  Future<ScanAttendanceResult> scanAttendance({
    required String eventId,
    required String qrValue,
  }) async {
    scanCallCount++;
    lastEventId = eventId;
    lastQrValue = qrValue;

    if (shouldFail) {
      throw const ServerException(
        'The scanned QR could not be verified',
        statusCode: 404,
        code: 'STUDENT_NOT_FOUND',
      );
    }

    if (isDuplicate) {
      return ScanAttendanceResult(
        success: true,
        code: 'ALREADY_MARKED',
        message: 'Attendance already recorded for this student',
        isDuplicate: true,
        studentName: 'Test Student',
        rollNumber: '2400270130001',
        studentNo: '2413001',
        branch: 'IT',
        status: 'present',
        timestamp: DateTime.now(),
      );
    }

    return ScanAttendanceResult(
      success: true,
      code: 'ATTENDANCE_MARKED',
      message: 'Attendance marked successfully',
      isDuplicate: false,
      studentName: 'Test Student',
      rollNumber: '2400270130001',
      studentNo: '2413001',
      branch: 'IT',
      status: 'present',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> markManual({
    required String eventId,
    required String studentId,
    required String status,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getAttendanceByEvent(String eventId) async {
    return [];
  }
}

void main() {
  group('ScanAttendanceResult parsing tests', () {
    test('Correctly parses successful new attendance payload', () {
      final json = {
        'success': true,
        'code': 'ATTENDANCE_MARKED',
        'message': 'Attendance marked successfully',
        'data': {
          '_id': 'att123',
          'status': 'present',
          'markedAt': '2026-10-23T12:00:00.000Z',
          'student': {
            '_id': 'stu123',
            'name': 'Anirudh Agarwal',
            'rollNo': '2400270130033',
            'studentNo': '2413084',
            'branch': 'IT',
          },
        },
      };

      final result = ScanAttendanceResult.fromJson(json);
      expect(result.success, true);
      expect(result.code, 'ATTENDANCE_MARKED');
      expect(result.isDuplicate, false);
      expect(result.studentName, 'Anirudh Agarwal');
      expect(result.rollNumber, '2400270130033');
      expect(result.studentNo, '2413084');
      expect(result.status, 'present');
    });

    test('Correctly parses duplicate attendance payload without error', () {
      final json = {
        'success': true,
        'code': 'ALREADY_MARKED',
        'message': 'Attendance already recorded for this student',
        'data': {
          '_id': 'att123',
          'status': 'present',
          'student': {
            'name': 'Anirudh Agarwal',
            'rollNo': '2400270130033',
          },
        },
      };

      final result = ScanAttendanceResult.fromJson(json);
      expect(result.success, true);
      expect(result.code, 'ALREADY_MARKED');
      expect(result.isDuplicate, true);
      expect(result.message, 'Attendance already recorded for this student');
    });
  });

  group('AttendanceRepository scanAttendance tests', () {
    late MockAttendanceRemoteSource mockRemote;
    late AttendanceRepository repository;

    setUp(() {
      mockRemote = MockAttendanceRemoteSource();
      repository = AttendanceRepositoryImpl(mockRemote);
    });

    test('Marks attendance and receives Right(ScanAttendanceResult)', () async {
      final result = await repository.scanAttendance(
        eventId: 'evt999',
        qrValue: '2400270130001',
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (scanResult) {
          expect(scanResult.success, true);
          expect(scanResult.isDuplicate, false);
          expect(scanResult.rollNumber, '2400270130001');
          expect(mockRemote.lastEventId, 'evt999');
          expect(mockRemote.lastQrValue, '2400270130001');
        },
      );
    });

    test('Handles duplicate scan outcome correctly', () async {
      mockRemote.isDuplicate = true;
      final result = await repository.scanAttendance(
        eventId: 'evt999',
        qrValue: '2400270130001',
      );

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure'),
        (scanResult) {
          expect(scanResult.success, true);
          expect(scanResult.isDuplicate, true);
          expect(scanResult.code, 'ALREADY_MARKED');
        },
      );
    });

    test('Propagates server failure with code when student is not found', () async {
      mockRemote.shouldFail = true;
      final result = await repository.scanAttendance(
        eventId: 'evt999',
        qrValue: 'UNKNOWN_QR',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure.message, 'The scanned QR could not be verified');
          expect(failure.code, 'STUDENT_NOT_FOUND');
        },
        (_) => fail('Expected failure but got success'),
      );
    });
  });

  group('QrScannerScreen widget tests', () {
    testWidgets('Displays warning state when eventId is missing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: QrScannerScreen(eventId: ''),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('NO EVENT SELECTED'), findsOneWidget);
      expect(find.text('GO TO ATTENDANCE HUB'), findsOneWidget);
    });
  });
}

