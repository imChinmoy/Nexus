const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize } = require('../middlewares/role.middleware');
const asyncHandler = require('../utils/asyncHandler');
const Settings = require('../models/Settings.model');
const { sendSuccess } = require('../utils/apiResponse');
const { ROLES } = require('../constants/roles');

router.use(authenticate);

router.get('/', asyncHandler(async (req, res) => {
  const filter = req.user.role === ROLES.VIEWER ? { isPublic: true } : {};
  const settings = await Settings.find(filter);
  const obj = settings.reduce((acc, s) => ({ ...acc, [s.key]: s.value }), {});
  sendSuccess(res, 'Settings fetched', obj);
}));

router.put('/:key', authorize(ROLES.ADMIN), asyncHandler(async (req, res) => {
  const setting = await Settings.findOneAndUpdate(
    { key: req.params.key },
    { value: req.body.value, updatedBy: req.user._id },
    { upsert: true, new: true },
  );
  sendSuccess(res, 'Setting updated', setting);
}));

module.exports = router;
