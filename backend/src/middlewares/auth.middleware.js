const authService = require('../services/auth.service');
const asyncHandler = require('../utils/asyncHandler');

const authenticate = asyncHandler(async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];
  const { user, decoded } = await authService.verifyToken(token);
  req.user = user;
  req.decoded = decoded;
  next();
});

module.exports = { authenticate };
