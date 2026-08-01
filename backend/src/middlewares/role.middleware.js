const { hasPermission, ROLES } = require('../constants/roles');
const { PERMISSIONS } = require('../constants/permissions');
const Settings = require('../models/Settings.model');

let rolePermissionsCache = null;
let cacheTimestamp = 0;
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

const getRolePermissions = async () => {
  if (rolePermissionsCache && (Date.now() - cacheTimestamp < CACHE_TTL)) {
    return rolePermissionsCache;
  }
  const setting = await Settings.findOne({ key: 'role_permissions' });
  if (setting && setting.value) {
    rolePermissionsCache = setting.value;
    cacheTimestamp = Date.now();
    return rolePermissionsCache;
  }
  // Default permissions if not set in DB
  return {
    [ROLES.SUPER_ADMIN]: [PERMISSIONS.ALL],
    [ROLES.ADMIN]: [PERMISSIONS.ALL],
    [ROLES.COORDINATOR]: [PERMISSIONS.ATTENDANCE_MARK, PERMISSIONS.EVENT_ADD],
    [ROLES.VOLUNTEER]: [],
    [ROLES.VIEWER]: []
  };
};

const clearRolePermissionsCache = () => {
  rolePermissionsCache = null;
  cacheTimestamp = 0;
};

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

const requirePermission = (requiredPermission) => async (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ success: false, message: 'Not authenticated' });
  }

  try {
    const permissionsMap = await getRolePermissions();
    const userPermissions = permissionsMap[req.user.role] || [];

    // super_admin or user with 'all' permission has access to everything
    if (req.user.role === ROLES.SUPER_ADMIN || userPermissions.includes(PERMISSIONS.ALL) || userPermissions.includes(requiredPermission)) {
      return next();
    }

    return res.status(403).json({
      success: false,
      message: `Access denied. Requires '${requiredPermission}' permission.`,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error while checking permissions' });
  }
};

module.exports = { authorize, requirePermission, clearRolePermissionsCache, getRolePermissions };
