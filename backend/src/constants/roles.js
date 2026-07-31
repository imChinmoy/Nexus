const ROLES = Object.freeze({
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  COORDINATOR: 'coordinator',
  VOLUNTEER: 'volunteer',
  VIEWER: 'viewer',
});

const ROLE_HIERARCHY = {
  [ROLES.SUPER_ADMIN]: 5,
  [ROLES.ADMIN]: 4,
  [ROLES.COORDINATOR]: 3,
  [ROLES.VOLUNTEER]: 2,
  [ROLES.VIEWER]: 1,
};

const hasPermission = (userRole, requiredRole) => {
  return (ROLE_HIERARCHY[userRole] || 0) >= (ROLE_HIERARCHY[requiredRole] || 0);
};

module.exports = { ROLES, ROLE_HIERARCHY, hasPermission };
