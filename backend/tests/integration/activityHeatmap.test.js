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

beforeEach(async () => {
  await clearTestDB();
});

afterEach(async () => {
  await clearTestDB();
});

afterAll(async () => {
  await closeTestDB();
});

describe('Annual Society Activity Heatmap Integration Tests', () => {
  test('Unauthenticated request to activity heatmap is rejected with 401', async () => {
    const res = await request(app).get('/api/analytics/activity-heatmap?year=2026&metric=events');
    expect(res.status).toBe(401);
  });

  test('Rejects invalid year and invalid metric query parameters with 422', async () => {
    const { token } = await createTestUser({ role: ROLES.MEMBER });

    const res1 = await request(app)
      .get('/api/analytics/activity-heatmap?year=1899&metric=events')
      .set('Authorization', `Bearer ${token}`);
    expect(res1.status).toBe(422);

    const res2 = await request(app)
      .get('/api/analytics/activity-heatmap?year=2026&metric=invalid_metric')
      .set('Authorization', `Bearer ${token}`);
    expect(res2.status).toBe(422);
  });

  test('Returns empty activity heatmap for a year with no recorded events', async () => {
    const { token } = await createTestUser({ role: ROLES.MEMBER });

    const res = await request(app)
      .get('/api/analytics/activity-heatmap?year=2025&metric=events')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.year).toBe(2025);
    expect(res.body.data.metric).toBe('events');
    expect(res.body.data.stats.totalCount).toBe(0);
    expect(res.body.data.stats.activeDays).toBe(0);
    expect(res.body.data.stats.busiestDay).toBeNull();
    expect(res.body.data.days).toEqual([]);
  });

  test('Correctly computes Events metric including multi-day events and excluding cancelled events', async () => {
    const { user, token } = await createTestUser({ role: ROLES.SUPER_ADMIN });

    // 1. Single-day workshop on 2026-03-10
    await Event.create({
      title: 'Solidity Deep Dive',
      type: 'workshop',
      status: 'completed',
      startDate: new Date('2026-03-10T10:00:00.000Z'),
      endDate: new Date('2026-03-10T16:00:00.000Z'),
      createdBy: user._id,
    });

    // 2. Multi-day hackathon from 2026-03-10 to 2026-03-12 (3 days: 10th, 11th, 12th)
    await Event.create({
      title: 'Web3 Hackathon 2026',
      type: 'hackathon',
      status: 'ongoing',
      startDate: new Date('2026-03-10T09:00:00.000Z'),
      endDate: new Date('2026-03-12T18:00:00.000Z'),
      createdBy: user._id,
    });

    // 3. Cancelled event on 2026-03-11 (MUST be excluded)
    await Event.create({
      title: 'Cancelled Guest Lecture',
      type: 'seminar',
      status: 'cancelled',
      startDate: new Date('2026-03-11T14:00:00.000Z'),
      endDate: new Date('2026-03-11T16:00:00.000Z'),
      createdBy: user._id,
    });

    // 4. Single-day meeting on 2026-04-05
    await Event.create({
      title: 'General Body Meeting',
      type: 'meeting',
      status: 'upcoming',
      startDate: new Date('2026-04-05T11:00:00.000Z'),
      endDate: new Date('2026-04-05T13:00:00.000Z'),
      createdBy: user._id,
    });

    const res = await request(app)
      .get('/api/analytics/activity-heatmap?year=2026&metric=events&timezone=UTC')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const { stats, days } = res.body.data;
    // 3 unique valid events (excluding the cancelled one)
    expect(stats.totalCount).toBe(3);
    // Active days: 2026-03-10, 2026-03-11, 2026-03-12, 2026-04-05 = 4 days
    expect(stats.activeDays).toBe(4);

    const dayMap = {};
    for (const d of days) {
      dayMap[d.date] = d;
    }

    // 2026-03-10 has 2 events (Solidity Deep Dive + Web3 Hackathon)
    expect(dayMap['2026-03-10'].count).toBe(2);
    expect(dayMap['2026-03-10'].events.map((e) => e.title)).toContain('Solidity Deep Dive');
    expect(dayMap['2026-03-10'].events.map((e) => e.title)).toContain('Web3 Hackathon 2026');

    // 2026-03-11 has 1 event (Web3 Hackathon only; Cancelled is excluded)
    expect(dayMap['2026-03-11'].count).toBe(1);
    expect(dayMap['2026-03-11'].events[0].title).toBe('Web3 Hackathon 2026');

    // 2026-03-12 has 1 event (Web3 Hackathon)
    expect(dayMap['2026-03-12'].count).toBe(1);

    // 2026-04-05 has 1 event
    expect(dayMap['2026-04-05'].count).toBe(1);
    expect(dayMap['2026-04-05'].events[0].title).toBe('General Body Meeting');

    // Peak day was 2026-03-10 with count 2
    expect(stats.busiestDay.date).toBe('2026-03-10');
    expect(stats.busiestDay.count).toBe(2);
    expect(stats.busiestPeriod).toBe('March');
  });

  test('Correctly groups Attendance metric by date and event in local timezone', async () => {
    const { user, token } = await createTestUser({ role: ROLES.SUPER_ADMIN });

    const event1 = await Event.create({
      title: 'Reload 26 Tech Summit',
      type: 'workshop',
      startDate: new Date('2026-02-15T09:00:00.000Z'),
      endDate: new Date('2026-02-15T18:00:00.000Z'),
      createdBy: user._id,
    });

    const event2 = await Event.create({
      title: 'Smart Contracts 101',
      type: 'seminar',
      startDate: new Date('2026-02-15T14:00:00.000Z'),
      endDate: new Date('2026-02-15T17:00:00.000Z'),
      createdBy: user._id,
    });

    const s1 = await Student.create({
      name: 'Rohan Verma',
      rollNo: '2100290100010',
      studentNo: '2100290100010',
      branch: 'CSE',
      year: 3,
      section: 'A',
      email: 'rohan.v@example.com',
    });

    const s2 = await Student.create({
      name: 'Priya Singh',
      rollNo: '2100290100011',
      studentNo: '2100290100011',
      branch: 'IT',
      year: 3,
      section: 'B',
      email: 'priya.s@example.com',
    });

    const s3 = await Student.create({
      name: 'Ankit Gupta',
      rollNo: '2100290100012',
      studentNo: '2100290100012',
      branch: 'ECE',
      year: 2,
      section: 'C',
      email: 'ankit.g@example.com',
    });

    // 2 check-ins for event1 on 2026-02-15
    await Attendance.create({
      event: event1._id,
      student: s1._id,
      status: 'present',
      method: 'qr',
      markedAt: new Date('2026-02-15T10:15:00.000Z'),
    });

    await Attendance.create({
      event: event1._id,
      student: s2._id,
      status: 'present',
      method: 'qr',
      markedAt: new Date('2026-02-15T10:20:00.000Z'),
    });

    // 1 check-in for event2 on 2026-02-15
    await Attendance.create({
      event: event2._id,
      student: s3._id,
      status: 'late',
      method: 'manual',
      markedAt: new Date('2026-02-15T14:30:00.000Z'),
    });

    // 1 check-in on 2026-02-16
    await Attendance.create({
      event: event1._id,
      student: s3._id,
      status: 'present',
      method: 'qr',
      markedAt: new Date('2026-02-16T11:00:00.000Z'),
    });

    const res = await request(app)
      .get('/api/analytics/activity-heatmap?year=2026&metric=attendance&timezone=UTC')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const { stats, days } = res.body.data;
    expect(stats.totalCount).toBe(4);
    expect(stats.activeDays).toBe(2);
    expect(stats.busiestDay.date).toBe('2026-02-15');
    expect(stats.busiestDay.count).toBe(3);

    const day15 = days.find((d) => d.date === '2026-02-15');
    expect(day15).toBeDefined();
    expect(day15.count).toBe(3);
    expect(day15.events.length).toBe(2);

    const reloadBreakdown = day15.events.find((e) => e.title === 'Reload 26 Tech Summit');
    expect(reloadBreakdown.count).toBe(2);

    const seminarBreakdown = day15.events.find((e) => e.title === 'Smart Contracts 101');
    expect(seminarBreakdown.count).toBe(1);
  });
});
