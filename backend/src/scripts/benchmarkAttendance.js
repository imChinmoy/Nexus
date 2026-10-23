/**
 * BRL Nexus - Attendance Scanning Benchmark & Load Verification Script
 *
 * Runs against the isolated test environment (port 27099).
 * Measures throughput, p50, p95, p99 latency, duplicate handling, and concurrency safety.
 */

process.env.NODE_ENV = 'test';
process.env.MONGODB_URI = process.env.TEST_MONGODB_URI || 'mongodb://127.0.0.1:27099/brl_nexus_test';
process.env.JWT_ACCESS_SECRET = 'test_jwt_access_secret_for_tests_12345';
process.env.JWT_REFRESH_SECRET = 'test_jwt_refresh_secret_for_tests_12345';
process.env.QR_SECRET = 'test_qr_secret_for_tests_12345';
process.env.RATE_LIMIT_QR_MAX = '5000'; // Set high for benchmark to measure raw endpoint latency

const mongoose = require('mongoose');
const request = require('supertest');
const app = require('../app');
const Event = require('../models/Event.model');
const Student = require('../models/Student.model');
const Attendance = require('../models/Attendance.model');
const User = require('../models/User.model');
const { ROLES } = require('../constants/roles');
const jwt = require('jsonwebtoken');

function calculatePercentiles(latencies) {
  if (latencies.length === 0) return { min: 0, p50: 0, p95: 0, p99: 0, max: 0, mean: 0 };
  const sorted = [...latencies].sort((a, b) => a - b);
  const getPercentile = (p) => {
    const idx = Math.min(Math.floor((p / 100) * sorted.length), sorted.length - 1);
    return sorted[idx];
  };
  const sum = sorted.reduce((acc, v) => acc + v, 0);
  return {
    min: sorted[0],
    p50: getPercentile(50),
    p95: getPercentile(95),
    p99: getPercentile(99),
    max: sorted[sorted.length - 1],
    mean: Number((sum / sorted.length).toFixed(2)),
  };
}

async function runBenchmark() {
  console.log('=================================================================');
  console.log('   BRL NEXUS — ATTENDANCE SCANNING BENCHMARK & LOAD TEST        ');
  console.log('=================================================================');
  console.log(`Connecting to test database: ${process.env.MONGODB_URI}...`);
  await mongoose.connect(process.env.MONGODB_URI);

  // Clean test database
  await Promise.all([
    Event.deleteMany({}),
    Student.deleteMany({}),
    Attendance.deleteMany({}),
    User.deleteMany({}),
  ]);

  console.log('Seeding synthetic benchmark data...');
  // 1. Create volunteer user
  const volunteer = await User.create({
    name: 'Benchmark Gate Volunteer',
    email: 'bench_volunteer@brl.com',
    password: 'password123',
    role: ROLES.VOLUNTEER,
    isActive: true,
    accessAllowed: true,
  });

  const token = jwt.sign(
    { id: volunteer._id, role: volunteer.role },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: '1h' }
  );

  // 2. Create open event
  const event = await Event.create({
    title: 'Nexus National Hackathon 2026',
    description: 'High-volume entry gate benchmark test event',
    startDate: new Date(Date.now() - 3600000),
    endDate: new Date(Date.now() + 14400000),
    isAttendanceOpen: true,
    attendanceWindowStart: new Date(Date.now() - 3600000),
    attendanceWindowEnd: new Date(Date.now() + 14400000),
    createdBy: volunteer._id,
  });

  // 3. Seed 100 synthetic students
  const students = [];
  for (let i = 1; i <= 100; i++) {
    const rollNo = `2100290100${String(i).padStart(3, '0')}`;
    const studentNo = `2110${String(i).padStart(3, '0')}`;
    students.push({
      name: `Synthetic Student ${i}`,
      rollNo,
      studentNo,
      email: `student_${i}@test.com`,
      phone: `9800000${String(i).padStart(3, '0')}`,
      domain: 'Web',
      branch: 'CSE',
      gender: i % 2 === 0 ? 'Female' : 'Male',
      isActive: true,
    });
  }
  const insertedStudents = await Student.insertMany(students);
  console.log(`Successfully seeded 1 Event, 1 Volunteer, and ${insertedStudents.length} Students.`);

  const allLatencies = [];
  let successMarks = 0;
  let duplicateMarks = 0;
  let unexpectedFailures = 0;

  // -------------------------------------------------------------
  // Scenario 1: Sequential continuous scanning of 50 students
  // -------------------------------------------------------------
  console.log('\n--- Scenario 1: Sequential Continuous Scanning (50 students) ---');
  const seqLatencies = [];
  const seqStart = Date.now();

  for (let i = 0; i < 50; i++) {
    const qrValue = students[i].rollNo;
    const t0 = Date.now();
    const res = await request(app)
      .post(`/api/attendance/event/${event._id}/scan`)
      .set('Authorization', `Bearer ${token}`)
      .send({ qrValue });
    const elapsed = Date.now() - t0;

    seqLatencies.push(elapsed);
    allLatencies.push(elapsed);

    if (res.status === 201 && res.body.code === 'ATTENDANCE_MARKED') {
      successMarks++;
    } else if (res.status === 200 && res.body.code === 'ALREADY_MARKED') {
      duplicateMarks++;
    } else {
      unexpectedFailures++;
      console.error(`Unexpected response for student ${qrValue}:`, res.status, res.body);
    }
  }
  const seqDuration = Date.now() - seqStart;
  const seqStats = calculatePercentiles(seqLatencies);
  console.log(`Completed 50 sequential scans in ${seqDuration}ms (${(50 / (seqDuration / 1000)).toFixed(1)} scans/sec)`);
  console.log(`Latency: min=${seqStats.min}ms, p50=${seqStats.p50}ms, p95=${seqStats.p95}ms, p99=${seqStats.p99}ms, max=${seqStats.max}ms, mean=${seqStats.mean}ms`);

  // -------------------------------------------------------------
  // Scenario 2: Repeat scanning of already-marked students (Duplicate verification)
  // -------------------------------------------------------------
  console.log('\n--- Scenario 2: Repeat Scanning (20 duplicate scans) ---');
  const dupLatencies = [];
  for (let i = 0; i < 20; i++) {
    const qrValue = students[i].rollNo; // already marked
    const t0 = Date.now();
    const res = await request(app)
      .post(`/api/attendance/event/${event._id}/scan`)
      .set('Authorization', `Bearer ${token}`)
      .send({ qrValue });
    const elapsed = Date.now() - t0;

    dupLatencies.push(elapsed);
    allLatencies.push(elapsed);

    if (res.status === 200 && res.body.code === 'ALREADY_MARKED') {
      duplicateMarks++;
    } else {
      unexpectedFailures++;
      console.error(`Unexpected response for duplicate scan ${qrValue}:`, res.status, res.body);
    }
  }
  const dupStats = calculatePercentiles(dupLatencies);
  console.log(`Completed 20 duplicate scans.`);
  console.log(`Latency: min=${dupStats.min}ms, p50=${dupStats.p50}ms, p95=${dupStats.p95}ms, max=${dupStats.max}ms, mean=${dupStats.mean}ms`);

  // -------------------------------------------------------------
  // Scenario 3: Concurrent Scans (5 batches of 4 simultaneous requests)
  // -------------------------------------------------------------
  console.log('\n--- Scenario 3: Concurrent Batches (20 students in 5 concurrent batches of 4) ---');
  const concLatencies = [];
  let studentIdx = 50;
  for (let b = 0; b < 5; b++) {
    const batchStudents = [
      students[studentIdx++],
      students[studentIdx++],
      students[studentIdx++],
      students[studentIdx++],
    ];

    const promises = batchStudents.map(async (st) => {
      const t0 = Date.now();
      const res = await request(app)
        .post(`/api/attendance/event/${event._id}/scan`)
        .set('Authorization', `Bearer ${token}`)
        .send({ qrValue: st.rollNo });
      const elapsed = Date.now() - t0;
      return { res, elapsed };
    });

    const results = await Promise.all(promises);
    for (const { res, elapsed } of results) {
      concLatencies.push(elapsed);
      allLatencies.push(elapsed);
      if (res.status === 201 && res.body.code === 'ATTENDANCE_MARKED') {
        successMarks++;
      } else if (res.status === 200 && res.body.code === 'ALREADY_MARKED') {
        duplicateMarks++;
      } else {
        unexpectedFailures++;
      }
    }
  }
  const concStats = calculatePercentiles(concLatencies);
  console.log(`Completed 20 concurrent scans.`);
  console.log(`Latency: min=${concStats.min}ms, p50=${concStats.p50}ms, p95=${concStats.p95}ms, max=${concStats.max}ms, mean=${concStats.mean}ms`);

  // -------------------------------------------------------------
  // Scenario 4: Concurrent Race on Identical Student (4 simultaneous scans of 1 student)
  // -------------------------------------------------------------
  console.log('\n--- Scenario 4: Concurrency Race on Single Student (4 simultaneous scans) ---');
  const raceStudent = insertedStudents[75];
  const racePromises = [1, 2, 3, 4].map(async () => {
    const t0 = Date.now();
    const res = await request(app)
      .post(`/api/attendance/event/${event._id}/scan`)
      .set('Authorization', `Bearer ${token}`)
      .send({ qrValue: raceStudent.rollNo });
    const elapsed = Date.now() - t0;
    return { res, elapsed };
  });

  const raceResults = await Promise.all(racePromises);
  let raceMarkedCount = 0;
  let raceDuplicateCount = 0;
  for (const { res, elapsed } of raceResults) {
    allLatencies.push(elapsed);
    if (res.status === 201 && res.body.code === 'ATTENDANCE_MARKED') {
      successMarks++;
      raceMarkedCount++;
    } else if (res.status === 200 && res.body.code === 'ALREADY_MARKED') {
      duplicateMarks++;
      raceDuplicateCount++;
    } else {
      unexpectedFailures++;
      console.error('Race scan error:', res.status, res.body);
    }
  }

  // Database verification
  const raceDbCount = await Attendance.countDocuments({
    event: event._id,
    student: raceStudent._id,
  });
  console.log(`Race results: ${raceMarkedCount} marked (HTTP 201), ${raceDuplicateCount} duplicate (HTTP 200).`);
  console.log(`Database records for student: ${raceDbCount} (Expected: exactly 1). Race safe: ${raceDbCount === 1}`);

  // -------------------------------------------------------------
  // Overall Summary Metrics
  // -------------------------------------------------------------
  const totalScans = allLatencies.length;
  const overallStats = calculatePercentiles(allLatencies);
  const totalDbRecords = await Attendance.countDocuments({ event: event._id });

  console.log('\n=================================================================');
  console.log('                   BENCHMARK FINAL RESULTS                      ');
  console.log('=================================================================');
  console.log(`Total Attempted Scans:           ${totalScans}`);
  console.log(`Successful Attendance Writes:    ${successMarks}`);
  console.log(`Duplicate Scan Outcomes:         ${duplicateMarks}`);
  console.log(`Unexpected Failures:             ${unexpectedFailures}`);
  console.log(`Total DB Attendance Records:     ${totalDbRecords}`);
  console.log(`Error Rate:                      ${((unexpectedFailures / totalScans) * 100).toFixed(2)}%`);
  console.log('-----------------------------------------------------------------');
  console.log('Latency Distribution:');
  console.log(`  Minimum:                       ${overallStats.min} ms`);
  console.log(`  p50 (Median):                  ${overallStats.p50} ms`);
  console.log(`  p95:                           ${overallStats.p95} ms`);
  console.log(`  p99:                           ${overallStats.p99} ms`);
  console.log(`  Maximum:                       ${overallStats.max} ms`);
  console.log(`  Mean (Average):                ${overallStats.mean} ms`);
  console.log('=================================================================\n');

  await mongoose.disconnect();
}

runBenchmark().catch((err) => {
  console.error('Benchmark error:', err);
  process.exit(1);
});
