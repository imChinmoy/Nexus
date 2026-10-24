const request = require('supertest');
const app = require('../../src/app');
const User = require('../../src/models/User.model');
const { connectTestDB, clearTestDB, closeTestDB } = require('../helpers/testDatabase');
const { ROLES } = require('../../src/constants/roles');

describe('Auth Registration Integration Tests', () => {
  beforeAll(async () => {
    await connectTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
  });

  afterAll(async () => {
    await closeTestDB();
  });

  test('Fails to register if society secret passkey is missing or invalid', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Society Member',
        email: 'member@akgec.ac.in',
        password: 'Password@123',
        secretKey: 'WRONG_SECRET_KEY',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toMatch(/Invalid society secret passkey/i);
  });

  test('Fails validation if required fields are missing', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'invalid-email',
      });

    expect(res.status).toBe(422);
    expect(res.body.success).toBe(false);
  });

  test('Successfully registers a user with valid society secret key and assigns role VIEWER', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Nexus Member',
        email: 'nexus.member@akgec.ac.in',
        password: 'Password@123',
        secretKey: 'BRL_NEXUS_2026',
        year: '3rd Year',
        domain: 'Blockchain',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user).toBeDefined();
    expect(res.body.data.user.email).toBe('nexus.member@akgec.ac.in');
    expect(res.body.data.user.name).toBe('Nexus Member');
    // Crucial check: automatically assigned as VIEWER
    expect(res.body.data.user.role).toBe(ROLES.VIEWER);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();

    // Verify in database
    const dbUser = await User.findOne({ email: 'nexus.member@akgec.ac.in' });
    expect(dbUser).toBeDefined();
    expect(dbUser.role).toBe(ROLES.VIEWER);
    expect(dbUser.isActive).toBe(true);
  });

  test('Ignores any client-supplied role and forces role to VIEWER', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Sneaky User',
        email: 'sneaky@akgec.ac.in',
        password: 'Password@123',
        secretKey: 'BRL_NEXUS_2026',
        role: ROLES.SUPER_ADMIN, // Client tries to elevate privilege
      });

    expect(res.status).toBe(201);
    expect(res.body.data.user.role).toBe(ROLES.VIEWER);

    const dbUser = await User.findOne({ email: 'sneaky@akgec.ac.in' });
    expect(dbUser.role).toBe(ROLES.VIEWER);
  });

  test('Fails registration if email is already taken', async () => {
    await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Original Member',
        email: 'duplicate@akgec.ac.in',
        password: 'Password@123',
        secretKey: 'BRL_NEXUS_2026',
      });

    const res2 = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Another Person',
        email: 'duplicate@akgec.ac.in',
        password: 'Password@456',
        secretKey: 'BRL_NEXUS_2026',
      });

    expect(res2.status).toBe(409);
    expect(res2.body.success).toBe(false);
    expect(res2.body.message).toMatch(/already exists/i);
  });
});
