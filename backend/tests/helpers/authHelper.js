const jwt = require('jsonwebtoken');
const User = require('../../src/models/User.model');
const { ROLES } = require('../../src/constants/roles');

const createTestUser = async ({ name = 'Test User', email, role = ROLES.VOLUNTEER, password = 'password123' } = {}) => {
  const userEmail = email || `user_${Date.now()}_${Math.random().toString(36).substring(7)}@test.com`;
  const user = await User.create({
    name,
    email: userEmail,
    password,
    role,
    isActive: true,
    accessAllowed: true,
  });

  const token = jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: '1h' },
  );

  return { user, token };
};

module.exports = { createTestUser };
