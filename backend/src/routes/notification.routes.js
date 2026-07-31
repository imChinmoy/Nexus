const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const asyncHandler = require('../utils/asyncHandler');
const Notification = require('../models/Notification.model');
const { sendSuccess } = require('../utils/apiResponse');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');

router.use(authenticate);

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const filter = { user: req.user._id };
  if (req.query.unread === 'true') filter.isRead = false;
  const [data, total] = await Promise.all([
    Notification.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Notification.countDocuments(filter),
  ]);
  sendSuccess(res, 'Notifications fetched', data, buildPaginationMeta(total, page, limit));
}));

router.patch('/:id/read', asyncHandler(async (req, res) => {
  const n = await Notification.findByIdAndUpdate(
    req.params.id, { isRead: true, readAt: new Date() }, { new: true },
  );
  sendSuccess(res, 'Notification marked as read', n);
}));

router.patch('/read-all', asyncHandler(async (req, res) => {
  await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true, readAt: new Date() });
  sendSuccess(res, 'All notifications marked as read');
}));

module.exports = router;
