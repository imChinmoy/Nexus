const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize } = require('../middlewares/role.middleware');
const asyncHandler = require('../utils/asyncHandler');
const User = require('../models/User.model');
const { sendSuccess, sendCreated } = require('../utils/apiResponse');
const { ROLES } = require('../constants/roles');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');

router.use(authenticate);

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const filter = {};
  if (req.query.role) filter.role = req.query.role;
  if (req.query.isActive !== undefined) filter.isActive = req.query.isActive === 'true';
  const [data, total] = await Promise.all([
    User.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    User.countDocuments(filter),
  ]);
  sendSuccess(res, 'Members fetched', data, buildPaginationMeta(total, page, limit));
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const member = await User.findById(req.params.id);
  if (!member) return res.status(404).json({ success: false, message: 'Member not found' });
  sendSuccess(res, 'Member fetched', member);
}));

router.post('/', authorize(ROLES.COORDINATOR), asyncHandler(async (req, res) => {
  const member = await User.create(req.body);
  sendCreated(res, 'Member created', member);
}));

router.put('/:id', authorize(ROLES.COORDINATOR), asyncHandler(async (req, res) => {
  const member = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!member) return res.status(404).json({ success: false, message: 'Member not found' });
  sendSuccess(res, 'Member updated', member);
}));

router.delete('/:id', authorize(ROLES.ADMIN), asyncHandler(async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  sendSuccess(res, 'Member deleted');
}));

module.exports = router;
