const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize } = require('../middlewares/role.middleware');
const asyncHandler = require('../utils/asyncHandler');
const User = require('../models/User.model');
const { sendSuccess, sendCreated } = require('../utils/apiResponse');
const { ROLES } = require('../constants/roles');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');
const bcrypt = require('bcryptjs');

router.use(authenticate, authorize(ROLES.ADMIN));

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const [data, total] = await Promise.all([
    User.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
    User.countDocuments(),
  ]);
  sendSuccess(res, 'Users fetched', data, buildPaginationMeta(total, page, limit));
}));

router.post('/', authorize(ROLES.SUPER_ADMIN), asyncHandler(async (req, res) => {
  const user = await User.create(req.body);
  sendCreated(res, 'User created', user);
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const { password, ...data } = req.body;
  const user = await User.findByIdAndUpdate(req.params.id, data, { new: true });
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  sendSuccess(res, 'User updated', user);
}));

router.delete('/:id', authorize(ROLES.SUPER_ADMIN), asyncHandler(async (req, res) => {
  if (req.params.id === req.user._id.toString()) {
    return res.status(400).json({ success: false, message: 'Cannot delete own account' });
  }
  await User.findByIdAndDelete(req.params.id);
  sendSuccess(res, 'User deleted');
}));

module.exports = router;
