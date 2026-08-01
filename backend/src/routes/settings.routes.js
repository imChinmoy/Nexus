const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize, clearRolePermissionsCache, getRolePermissions } = require('../middlewares/role.middleware');
const asyncHandler = require('../utils/asyncHandler');
const Settings = require('../models/Settings.model');
const { sendSuccess } = require('../utils/apiResponse');
const { ROLES } = require('../constants/roles');

router.use(authenticate);

// Get role permissions explicitly
router.get('/role-permissions', authorize(ROLES.SUPER_ADMIN), asyncHandler(async (req, res) => {
  const permissionsMap = await getRolePermissions();
  sendSuccess(res, 'Role permissions fetched', permissionsMap);
}));

router.get('/', asyncHandler(async (req, res) => {
  const filter = req.user.role === ROLES.VIEWER ? { isPublic: true } : {};
  const settings = await Settings.find(filter);
  const obj = settings.reduce((acc, s) => ({ ...acc, [s.key]: s.value }), {});
  sendSuccess(res, 'Settings fetched', obj);
}));

router.put('/:key', authorize(ROLES.SUPER_ADMIN, ROLES.ADMIN), asyncHandler(async (req, res) => {
  if (req.params.key === 'role_permissions' && req.user.role !== ROLES.SUPER_ADMIN) {
    return res.status(403).json({ success: false, message: 'Only Super Admin can edit role permissions' });
  }

  const setting = await Settings.findOneAndUpdate(
    { key: req.params.key },
    { value: req.body.value, updatedBy: req.user._id },
    { upsert: true, new: true },
  );

  if (req.params.key === 'role_permissions') {
    clearRolePermissionsCache();
  }

  sendSuccess(res, 'Setting updated', setting);
}));

module.exports = router;
