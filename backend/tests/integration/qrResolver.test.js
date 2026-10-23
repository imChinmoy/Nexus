const jwt = require('jsonwebtoken');
const { connectTestDB, clearTestDB, closeTestDB } = require('../helpers/testDatabase');
const qrResolverService = require('../../src/services/qrResolver.service');
const Student = require('../../src/models/Student.model');
const Registration = require('../../src/models/Registration.model');

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

describe('QR Resolver Service Integration Tests', () => {
  test('Resolves student from raw roll number against Student collection', async () => {
    const student = await Student.create({
      name: 'John Doe',
      rollNo: '2100290120001',
      studentNo: '2112001',
      email: 'john.doe@test.com',
      phone: '9876543210',
      domain: 'Web',
      gender: 'Male',
      branch: 'CSE',
    });

    const resolved = await qrResolverService.resolveStudent('2100290120001');
    expect(resolved).toBeDefined();
    expect(resolved._id.toString()).toBe(student._id.toString());
    expect(resolved.name).toBe('John Doe');
    expect(resolved.rollNo).toBe('2100290120001');
  });

  test('Resolves student from raw student number', async () => {
    const student = await Student.create({
      name: 'Jane Smith',
      rollNo: '2100290120002',
      studentNo: '2112002',
      email: 'jane.smith@test.com',
      phone: '9876543211',
      domain: 'App',
      gender: 'Female',
      branch: 'IT',
    });

    const resolved = await qrResolverService.resolveStudent('2112002');
    expect(resolved).toBeDefined();
    expect(resolved._id.toString()).toBe(student._id.toString());
    expect(resolved.name).toBe('Jane Smith');
  });

  test('Resolves student from JSON payload with rollNo or rollNumber', async () => {
    const student = await Student.create({
      name: 'Alice Wonder',
      rollNo: '2100290120003',
      studentNo: '2112003',
      email: 'alice@test.com',
      phone: '9876543212',
      domain: 'Design',
      gender: 'Female',
      branch: 'CS',
    });

    const jsonPayload = JSON.stringify({ rollNumber: '2100290120003' });
    const resolved = await qrResolverService.resolveStudent(jsonPayload);
    expect(resolved).toBeDefined();
    expect(resolved._id.toString()).toBe(student._id.toString());
    expect(resolved.name).toBe('Alice Wonder');
  });

  test('Resolves student from signed JWT containing rollNo or studentId', async () => {
    const student = await Student.create({
      name: 'Bob Builder',
      rollNo: '2100290120004',
      studentNo: '2112004',
      email: 'bob@test.com',
      phone: '9876543213',
      domain: 'Blockchain',
      gender: 'Male',
      branch: 'ECE',
    });

    const token = jwt.sign(
      { rollNo: '2100290120004', studentId: student._id.toString() },
      process.env.QR_SECRET,
      { expiresIn: '24h' }
    );

    const resolved = await qrResolverService.resolveStudent(token);
    expect(resolved).toBeDefined();
    expect(resolved._id.toString()).toBe(student._id.toString());
  });

  test('Resolves student from external Registration when Student document does not exist yet', async () => {
    // External portal created registration
    await Registration.create({
      name: 'Charlie External',
      rollNo: '2100290120005',
      studentNo: '2112005',
      email: 'charlie@test.com',
      phone: '9876543214',
      domain: 'AI/ML',
      gender: 'Male',
      branch: 'CSE(AIML)',
    });

    // Student should not exist yet in Student collection
    const existingStudent = await Student.findOne({ rollNo: '2100290120005' });
    expect(existingStudent).toBeNull();

    // Resolving QR should bridge the identity without mutating Registration
    const resolved = await qrResolverService.resolveStudent('2100290120005');
    expect(resolved).toBeDefined();
    expect(resolved.name).toBe('Charlie External');
    expect(resolved.rollNo).toBe('2100290120005');

    // Registration should still be intact
    const regCheck = await Registration.findOne({ rollNo: '2100290120005' });
    expect(regCheck).toBeDefined();
    expect(regCheck.name).toBe('Charlie External');
  });

  test('Returns null for empty or non-existent student QR', async () => {
    const emptyResult = await qrResolverService.resolveStudent('');
    expect(emptyResult).toBeNull();

    const nullResult = await qrResolverService.resolveStudent(null);
    expect(nullResult).toBeNull();

    const notFoundResult = await qrResolverService.resolveStudent('NON_EXISTENT_ROLL_99999');
    expect(notFoundResult).toBeNull();
  });
});
