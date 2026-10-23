const request = require('supertest');
const app = require('../../src/app');
const { connectTestDB, clearTestDB, closeTestDB } = require('../helpers/testDatabase');
const { createTestUser } = require('../helpers/authHelper');
const { ROLES } = require('../../src/constants/roles');
const Event = require('../../src/models/Event.model');
const Student = require('../../src/models/Student.model');
const Attendance = require('../../src/models/Attendance.model');

beforeAll(async () => {
  await connectTestDB();
});

afterEach(async () => {
  await clearTestDB();
});

afterAll(async () => {
  await closeTestDB();
});

describe('Attendance API Integration Tests', () => {
  let volunteerToken;
  let volunteerUser;
  let viewerToken;
  let testEvent;
  let testStudent;

  beforeEach(async () => {
    await clearTestDB();
    // Create volunteer user
    const vol = await createTestUser({ role: ROLES.VOLUNTEER, email: 'volunteer@brl.com' });
    volunteerToken = vol.token;
    volunteerUser = vol.user;

    // Create viewer user
    const view = await createTestUser({ role: ROLES.VIEWER, email: 'viewer@brl.com' });
    viewerToken = view.token;

    // Create open test event
    testEvent = await Event.create({
      title: 'DevSprint 2026',
      description: 'Annual development sprint',
      startDate: new Date(Date.now() - 3600000),
      endDate: new Date(Date.now() + 7200000),
      type: 'workshop',
      venue: 'Lab 3',
      isAttendanceOpen: true,
      attendanceWindowStart: new Date(Date.now() - 3600000),
      attendanceWindowEnd: new Date(Date.now() + 7200000),
      createdBy: volunteerUser._id,
    });

    // Create test student
    testStudent = await Student.create({
      name: 'Rohan Sharma',
      rollNo: '2100290100099',
      studentNo: '2110099',
      email: 'rohan.sharma@test.com',
      phone: '9988776655',
      domain: 'Web',
      gender: 'Male',
      branch: 'CSE',
      isActive: true,
    });
  });

  test('Gate scan marks attendance successfully for valid student and open event', async () => {
    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.code).toBe('ATTENDANCE_MARKED');
    expect(res.body.data.student.rollNo).toBe(testStudent.rollNo);
    const eventId = res.body.data.event._id || res.body.data.event;
    expect(eventId.toString()).toBe(testEvent._id.toString());
    expect(res.body.data.markedBy.toString()).toBe(volunteerUser._id.toString());
    expect(res.body.data.method).toBe('qr');

    // Verify database record
    const count = await Attendance.countDocuments({
      event: testEvent._id,
      student: testStudent._id,
    });
    expect(count).toBe(1);

    // Verify student isPresent was not globally mutated
    const studentCheck = await Student.findById(testStudent._id);
    expect(studentCheck.isPresent).toBe(false);
  });

  test('Subsequent scan of already-marked student returns ALREADY_MARKED (HTTP 200)', async () => {
    // First scan
    await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });

    // Repeat scan
    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.code).toBe('ALREADY_MARKED');
    expect(res.body.data._id).toBeDefined();

    // Database still has exactly 1 record
    const count = await Attendance.countDocuments({
      event: testEvent._id,
      student: testStudent._id,
    });
    expect(count).toBe(1);
  });

  test('Concurrent scans for same student resolve safely with exactly 1 DB record and no 500 error', async () => {
    // Dispatch 2 concurrent requests
    const [res1, res2] = await Promise.all([
      request(app)
        .post(`/api/attendance/event/${testEvent._id}/scan`)
        .set('Authorization', `Bearer ${volunteerToken}`)
        .send({ qrValue: testStudent.rollNo }),
      request(app)
        .post(`/api/attendance/event/${testEvent._id}/scan`)
        .set('Authorization', `Bearer ${volunteerToken}`)
        .send({ qrValue: testStudent.rollNo }),
    ]);

    // Both requests must succeed (one 201, one 200)
    const statuses = [res1.status, res2.status].sort();
    expect(statuses).toEqual([200, 201]);

    const codes = [res1.body.code, res2.body.code].sort();
    expect(codes).toEqual(['ALREADY_MARKED', 'ATTENDANCE_MARKED']);

    // Check DB record count is strictly 1
    const count = await Attendance.countDocuments({
      event: testEvent._id,
      student: testStudent._id,
    });
    expect(count).toBe(1);
  });

  test('Same student can attend multiple distinct events independently', async () => {
    const secondEvent = await Event.create({
      title: 'HackNight 2026',
      startDate: new Date(Date.now() - 3600000),
      endDate: new Date(Date.now() + 7200000),
      isAttendanceOpen: true,
      createdBy: volunteerUser._id,
    });

    const res1 = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });
    expect(res1.status).toBe(201);

    const res2 = await request(app)
      .post(`/api/attendance/event/${secondEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });
    expect(res2.status).toBe(201);

    const totalAttendance = await Attendance.countDocuments({ student: testStudent._id });
    expect(totalAttendance).toBe(2);
  });

  test('Rejects attendance scan when event attendance is explicitly closed', async () => {
    testEvent.isAttendanceOpen = false;
    await testEvent.save();

    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('ATTENDANCE_CLOSED');
  });

  test('Rejects attendance scan when attendance window has not started', async () => {
    testEvent.attendanceWindowStart = new Date(Date.now() + 3600000); // 1 hr future
    testEvent.attendanceWindowEnd = new Date(Date.now() + 7200000);
    await testEvent.save();

    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('ATTENDANCE_WINDOW_NOT_STARTED');
  });

  test('Rejects attendance scan when attendance window has expired', async () => {
    testEvent.attendanceWindowStart = new Date(Date.now() - 7200000);
    testEvent.attendanceWindowEnd = new Date(Date.now() - 3600000); // expired 1 hr ago
    await testEvent.save();

    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('ATTENDANCE_WINDOW_EXPIRED');
  });

  test('Rejects attendance scan for non-existent event', async () => {
    const fakeId = '507f1f77bcf86cd799439011';
    const res = await request(app)
      .post(`/api/attendance/event/${fakeId}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('EVENT_NOT_FOUND');
  });

  test('Rejects attendance scan when student cannot be resolved', async () => {
    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({ qrValue: 'UNKNOWN_STUDENT_99999' });

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('STUDENT_NOT_FOUND');
  });

  test('Unauthorized user (Viewer) is forbidden from marking attendance', async () => {
    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .set('Authorization', `Bearer ${viewerToken}`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('Unauthenticated scan request is rejected with 401', async () => {
    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/scan`)
      .send({ qrValue: testStudent.rollNo });

    expect(res.status).toBe(401);
  });

  test('Manual attendance marking enforces event attendance window and records correctly', async () => {
    const res = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/manual`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({
        studentId: testStudent._id,
        status: 'present',
        note: 'Manual entry gate check',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.method).toBe('manual');

    // Updating manual submission
    const dupRes = await request(app)
      .post(`/api/attendance/event/${testEvent._id}/manual`)
      .set('Authorization', `Bearer ${volunteerToken}`)
      .send({
        studentId: testStudent._id,
        status: 'present',
      });

    expect(dupRes.status).toBe(200);
    expect(dupRes.body.success).toBe(true);
  });
});
