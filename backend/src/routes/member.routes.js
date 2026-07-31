const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize } = require('../middlewares/role.middleware');
const asyncHandler = require('../utils/asyncHandler');
const Member = require('../models/Member.model');
const { sendSuccess, sendCreated } = require('../utils/apiResponse');
const { ROLES } = require('../constants/roles');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');

router.use(authenticate);

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const filter = {};
  if (req.query.committee) filter.committee = req.query.committee;
  if (req.query.isActive !== undefined) filter.isActive = req.query.isActive === 'true';
  const [data, total] = await Promise.all([
    Member.find(filter).populate('student', 'name rollNumber branch year avatar').sort({ order: 1, joinedAt: -1 }).skip(skip).limit(limit),
    Member.countDocuments(filter),
  ]);
  sendSuccess(res, 'Members fetched', data, buildPaginationMeta(total, page, limit));
}));

router.get('/:id', asyncHandler(async (req, res) => {
  const member = await Member.findById(req.params.id).populate('student');
  if (!member) return res.status(404).json({ success: false, message: 'Member not found' });
  sendSuccess(res, 'Member fetched', member);
}));

router.post('/', authorize(ROLES.COORDINATOR), asyncHandler(async (req, res) => {
  const member = await Member.create(req.body);
  sendCreated(res, 'Member created', member);
}));

router.put('/:id', authorize(ROLES.COORDINATOR), asyncHandler(async (req, res) => {
  const member = await Member.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!member) return res.status(404).json({ success: false, message: 'Member not found' });
  sendSuccess(res, 'Member updated', member);
}));

router.delete('/:id', authorize(ROLES.ADMIN), asyncHandler(async (req, res) => {
  await Member.findByIdAndDelete(req.params.id);
  sendSuccess(res, 'Member deleted');
}));

module.exports = router;
