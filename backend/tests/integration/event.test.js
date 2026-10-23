const request = require('supertest');
const app = require('../../src/app');
const { connectTestDB, clearTestDB, closeTestDB } = require('../helpers/testDatabase');
const { createTestUser } = require('../helpers/authHelper');
const { ROLES } = require('../../src/constants/roles');

beforeAll(async () => {
  await connectTestDB();
});

beforeEach(async () => {
  await clearTestDB();
});

afterEach(async () => {
  await clearTestDB();
});

afterAll(async () => {
  await closeTestDB();
});

describe('Event Management Integration Tests', () => {
  test('Authorized user (Super Admin) can create a valid event with attendance window', async () => {
    const { token } = await createTestUser({ role: ROLES.SUPER_ADMIN });

    const startDate = new Date(Date.now() + 3600000).toISOString();
    const endDate = new Date(Date.now() + 7200000).toISOString();
    const windowStart = new Date(Date.now() + 1800000).toISOString();
    const windowEnd = new Date(Date.now() + 7200000).toISOString();

    const res = await request(app)
      .post('/api/events')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'BRL Hackathon 2026',
        description: 'Annual Blockchain Hackathon',
        startDate,
        endDate,
        type: 'hackathon',
        venue: 'Auditorium Hall',
        capacity: 150,
        isAttendanceOpen: true,
        attendanceWindowStart: windowStart,
        attendanceWindowEnd: windowEnd,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.title).toBe('BRL Hackathon 2026');
    expect(res.body.data.isAttendanceOpen).toBe(true);
    expect(res.body.data.capacity).toBe(150);
  });

  test('Invalid event data (end date before start date) is rejected', async () => {
    const { token } = await createTestUser({ role: ROLES.SUPER_ADMIN });

    const res = await request(app)
      .post('/api/events')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Invalid Date Event',
        startDate: '2026-10-25T10:00:00Z',
        endDate: '2026-10-24T10:00:00Z', // Before start
      });

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors.endDate).toBeDefined();
  });

  test('Missing title is rejected with validation error', async () => {
    const { token } = await createTestUser({ role: ROLES.SUPER_ADMIN });

    const res = await request(app)
      .post('/api/events')
      .set('Authorization', `Bearer ${token}`)
      .send({
        startDate: '2026-10-25T10:00:00Z',
        endDate: '2026-10-26T10:00:00Z',
      });

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
    expect(res.body.errors.title).toBeDefined();
  });

  test('Unauthorized user (Viewer) cannot create event', async () => {
    const { token } = await createTestUser({ role: ROLES.VIEWER });

    const res = await request(app)
      .post('/api/events')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Unauthorized Event',
        startDate: '2026-10-25T10:00:00Z',
        endDate: '2026-10-26T10:00:00Z',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('Authorized user can toggle attendance open and closed', async () => {
    const { token } = await createTestUser({ role: ROLES.SUPER_ADMIN });

    const createRes = await request(app)
      .post('/api/events')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Toggle Attendance Event',
        startDate: new Date(Date.now() + 10000).toISOString(),
        endDate: new Date(Date.now() + 50000).toISOString(),
      });

    const eventId = createRes.body.data._id;

    // Open attendance
    const openRes = await request(app)
      .patch(`/api/events/${eventId}/attendance-toggle`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isOpen: true });

    expect(openRes.status).toBe(200);
    expect(openRes.body.data.isAttendanceOpen).toBe(true);

    // Close attendance
    const closeRes = await request(app)
      .patch(`/api/events/${eventId}/attendance-toggle`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isOpen: false });

    expect(closeRes.status).toBe(200);
    expect(closeRes.body.data.isAttendanceOpen).toBe(false);
  });
});
