const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/app');
const Event = require('../../src/models/Event.model');
const Student = require('../../src/models/Student.model');
const Attendance = require('../../src/models/Attendance.model');
const registrationSourceService = require('../../src/services/registrationSource.service');
const { connectTestDB, clearTestDB, closeTestDB } = require('../helpers/testDatabase');
const { createTestUser } = require('../helpers/authHelper');
const { ROLES } = require('../../src/constants/roles');
const { ATTENDANCE_STATUS, ATTENDANCE_METHOD } = require('../../src/constants/attendanceStatus');

describe('Event-Based Student Listing and Attendance Integration', () => {
  let adminUser, adminToken;
  let volunteerUser, volunteerToken;
  let event1, event2, eventNoSource;

  const db1Name = 'EXPERT-SEMINAR-REGISTRATION';
  const db2Name = 'RELOAD-REGISTRATION';

  beforeAll(async () => {
    await connectTestDB();
  });

  afterAll(async () => {
    // Drop test databases created during run
    try {
      const db1 = mongoose.connection.useDb(db1Name, { useCache: true });
      await db1.dropDatabase();
      const db2 = mongoose.connection.useDb(db2Name, { useCache: true });
      await db2.dropDatabase();
    } catch (_e) {
      // Ignored
    }
    await closeTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    registrationSourceService.clearCustomSources();

    const admin = await createTestUser({ role: ROLES.ADMIN, email: 'admin_event_students@test.com' });
    adminUser = admin.user;
    adminToken = admin.token;

    const vol = await createTestUser({ role: ROLES.VOLUNTEER, email: 'vol_event_students@test.com' });
    volunteerUser = vol.user;
    volunteerToken = vol.token;

    // 1. Create Event 1 (Expert Seminar)
    event1 = await Event.create({
      title: 'Expert Seminar 2026',
      description: 'AI & Web3 Seminar',
      startDate: new Date(),
      endDate: new Date(Date.now() + 3600000),
      isAttendanceOpen: true,
      registrationSourceKey: 'expert-seminar',
      createdBy: adminUser._id,
    });

    // 2. Create Event 2 (Reload Hackathon)
    event2 = await Event.create({
      title: 'Reload 2026',
      description: 'Annual Hackathon',
      startDate: new Date(),
      endDate: new Date(Date.now() + 7200000),
      isAttendanceOpen: true,
      registrationSourceKey: 'reload',
      createdBy: adminUser._id,
    });

    // 3. Create Event without registration source configured
    eventNoSource = await Event.create({
      title: 'Unconfigured Event',
      startDate: new Date(),
      endDate: new Date(Date.now() + 3600000),
      createdBy: adminUser._id,
    });

    // Seed registrations into EXPERT-SEMINAR-REGISTRATION
    const db1 = mongoose.connection.useDb(db1Name, { useCache: true });
    await db1.collection('registrations').deleteMany({});
    await db1.collection('registrations').insertMany([
      {
        name: 'Alice Sharma',
        rollNo: '240027100001',
        studentNo: '2410001',
        branch: 'CSE',
        email: 'alice@test.com',
        phone: '9876543210',
        gender: 'Female',
        hosteller: true,
      },
      {
        name: 'Bob Verma',
        rollNo: '240027100002',
        studentNo: '2410002',
        branch: 'IT',
        email: 'bob@test.com',
        phone: '9876543211',
        gender: 'Male',
        hosteller: false,
      },
      {
        name: 'Charlie Gupta',
        rollNo: '240027100003',
        studentNo: '2410003',
        branch: 'CSE',
        email: 'charlie@test.com',
        phone: '9876543212',
        gender: 'Male',
        hosteller: true,
      },
    ]);

    // Seed registrations into RELOAD-REGISTRATION
    const db2 = mongoose.connection.useDb(db2Name, { useCache: true });
    await db2.collection('registrations').deleteMany({});
    await db2.collection('registrations').insertMany([
      {
        name: 'David Miller',
        rollNo: '240027100004',
        studentNo: '2410004',
        branch: 'ECE',
        email: 'david@test.com',
        phone: '9876543213',
        gender: 'Male',
        hosteller: false,
      },
      {
        name: 'Eve Adams',
        rollNo: '240027100005',
        studentNo: '2410005',
        branch: 'CSE',
        email: 'eve@test.com',
        phone: '9876543214',
        gender: 'Female',
        hosteller: true,
      },
    ]);

    // Create a local Student document and an Attendance record for Alice in Event 1
    const aliceStudent = await Student.create({
      name: 'Alice Sharma',
      rollNo: '240027100001',
      studentNo: '2410001',
      branch: 'CSE',
      email: 'alice@test.com',
      phone: '9876543210',
      domain: 'Tech',
      gender: 'Female',
      hosteller: true,
      isActive: true,
    });

    await Attendance.create({
      event: event1._id,
      student: aliceStudent._id,
      status: ATTENDANCE_STATUS.PRESENT,
      method: ATTENDANCE_METHOD.QR,
      markedBy: volunteerUser._id,
      markedAt: new Date(),
    });
  });

  describe('1. Registration Source Resolution and Scoped Fetching', () => {
    test('Fetches registrations belonging strictly to the selected event', async () => {
      const res = await request(app)
        .get(`/api/events/${event1._id}/students`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveLength(3);

      const names = res.body.data.map((s) => s.name);
      expect(names).toContain('Alice Sharma');
      expect(names).toContain('Bob Verma');
      expect(names).toContain('Charlie Gupta');
      // Should NOT contain students from Event 2
      expect(names).not.toContain('David Miller');
      expect(names).not.toContain('Eve Adams');

      // Check metadata and counts
      expect(res.body.meta.total).toBe(3);
      expect(res.body.meta.page).toBe(1);
      expect(res.body.counts).toEqual({
        total: 3,
        present: 1,
        notMarked: 2,
        absent: 0,
        late: 0,
        excused: 0,
      });
    });

    test('Correctly matches event-specific attendance status and preserves Not Scanned status', async () => {
      const res = await request(app)
        .get(`/api/events/${event1._id}/students`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(200);

      const alice = res.body.data.find((s) => s.rollNo === '240027100001');
      expect(alice).toBeDefined();
      expect(alice.attendance).toBeDefined();
      expect(alice.attendance.status).toBe('present');
      expect(alice.attendance.markedAt).toBeDefined();

      const bob = res.body.data.find((s) => s.rollNo === '240027100002');
      expect(bob).toBeDefined();
      expect(bob.attendance).toBeNull(); // Not scanned / not marked
    });

    test('Switching to another event loads its distinct registrations and independent attendance', async () => {
      const res = await request(app)
        .get(`/api/events/${event2._id}/students`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(2);

      const names = res.body.data.map((s) => s.name);
      expect(names).toEqual(expect.arrayContaining(['David Miller', 'Eve Adams']));
      expect(names).not.toContain('Alice Sharma');

      // No attendance recorded yet for Event 2
      expect(res.body.counts).toEqual({
        total: 2,
        present: 0,
        notMarked: 2,
        absent: 0,
        late: 0,
        excused: 0,
      });
    });
  });

  describe('2. Search, Filtering, and Pagination Scoped to Event', () => {
    test('Searches by student name within the selected event only', async () => {
      const res = await request(app)
        .get(`/api/events/${event1._id}/students?search=Bob`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].name).toBe('Bob Verma');
      expect(res.body.meta.total).toBe(1);
    });

    test('Searches by roll number within the selected event', async () => {
      const res = await request(app)
        .get(`/api/events/${event1._id}/students?search=240027100003`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].name).toBe('Charlie Gupta');
    });

    test('Filters by branch within the selected event', async () => {
      const res = await request(app)
        .get(`/api/events/${event1._id}/students?branch=CSE`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(2);
      const names = res.body.data.map((s) => s.name);
      expect(names).toContain('Alice Sharma');
      expect(names).toContain('Charlie Gupta');
      expect(names).not.toContain('Bob Verma');
    });

    test('Filters by attendance status (present vs not_marked)', async () => {
      // Present filter
      const presentRes = await request(app)
        .get(`/api/events/${event1._id}/students?attendanceStatus=present`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(presentRes.status).toBe(200);
      expect(presentRes.body.data).toHaveLength(1);
      expect(presentRes.body.data[0].name).toBe('Alice Sharma');

      // Not marked filter
      const notMarkedRes = await request(app)
        .get(`/api/events/${event1._id}/students?attendanceStatus=not_marked`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(notMarkedRes.status).toBe(200);
      expect(notMarkedRes.body.data).toHaveLength(2);
      const notMarkedNames = notMarkedRes.body.data.map((s) => s.name);
      expect(notMarkedNames).toContain('Bob Verma');
      expect(notMarkedNames).toContain('Charlie Gupta');
    });

    test('Server-side pagination works stably across pages', async () => {
      const page1Res = await request(app)
        .get(`/api/events/${event1._id}/students?page=1&limit=2`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(page1Res.status).toBe(200);
      expect(page1Res.body.data).toHaveLength(2);
      expect(page1Res.body.meta.page).toBe(1);
      expect(page1Res.body.meta.limit).toBe(2);
      expect(page1Res.body.meta.total).toBe(3);
      expect(page1Res.body.meta.totalPages).toBe(2);

      const page2Res = await request(app)
        .get(`/api/events/${event1._id}/students?page=2&limit=2`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(page2Res.status).toBe(200);
      expect(page2Res.body.data).toHaveLength(1);
      expect(page2Res.body.meta.page).toBe(2);

      // Verify no overlap between page 1 and page 2
      const p1Ids = page1Res.body.data.map((s) => s.studentId);
      const p2Ids = page2Res.body.data.map((s) => s.studentId);
      expect(p1Ids).not.toContain(p2Ids[0]);
    });
  });

  describe('3. Error Handling and Security', () => {
    test('Returns 404 when event does not exist', async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const res = await request(app)
        .get(`/api/events/${fakeId}/students`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(404);
      expect(res.body.code).toBe('EVENT_NOT_FOUND');
    });

    test('Returns 422 when event has no registrationSourceKey configured', async () => {
      const res = await request(app)
        .get(`/api/events/${eventNoSource._id}/students`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(422);
      expect(res.body.code).toBe('REGISTRATION_SOURCE_NOT_CONFIGURED');
    });

    test('Returns 400 when registrationSourceKey contains invalid characters', async () => {
      const maliciousEvent = await Event.create({
        title: 'Malicious Event',
        startDate: new Date(),
        endDate: new Date(Date.now() + 3600000),
        registrationSourceKey: 'admin$db.dropDatabase()',
        createdBy: adminUser._id,
      });

      const res = await request(app)
        .get(`/api/events/${maliciousEvent._id}/students`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('INVALID_REGISTRATION_SOURCE_KEY');
    });

    test('Returns 404 when registration collection is missing in database', async () => {
      // Register custom source pointing to empty db without registrations collection
      registrationSourceService.registerSource('empty-source', {
        dbName: 'EMPTY_TEST_DB_NO_COLLECTION',
        collectionName: 'non_existent_registrations',
      });

      const badCollectionEvent = await Event.create({
        title: 'Missing Collection Event',
        startDate: new Date(),
        endDate: new Date(Date.now() + 3600000),
        registrationSourceKey: 'empty-source',
        createdBy: adminUser._id,
      });

      const res = await request(app)
        .get(`/api/events/${badCollectionEvent._id}/students`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(404);
      expect(res.body.code).toBe('REGISTRATION_COLLECTION_NOT_FOUND');
    });

    test('Rejects unauthenticated requests with 401', async () => {
      const res = await request(app).get(`/api/events/${event1._id}/students`);
      expect(res.status).toBe(401);
    });

    test('Works via /api/students?eventId=... parameter as well', async () => {
      const res = await request(app)
        .get(`/api/students?eventId=${event1._id}`)
        .set('Authorization', `Bearer ${volunteerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(3);
      expect(res.body.counts.total).toBe(3);
    });
  });
});
