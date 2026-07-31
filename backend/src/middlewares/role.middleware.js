const { hasPermission } = require('../constants/roles');

const authorize = (...roles) => (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ success: false, message: 'Not authenticated' });
  }

  // Check if user has at least one of the required roles
  const hasRole = roles.some((role) => hasPermission(req.user.role, role));
  if (!hasRole) {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Insufficient permissions.',
    });
  }
  next();
};

module.exports = { authorize };
