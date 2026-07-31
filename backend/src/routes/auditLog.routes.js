const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize } = require('../middlewares/role.middleware');
const asyncHandler = require('../utils/asyncHandler');
const AuditLog = require('../models/AuditLog.model');
const { sendSuccess } = require('../utils/apiResponse');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');
const { ROLES } = require('../constants/roles');

router.use(authenticate, authorize(ROLES.ADMIN));

router.get('/', asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const filter = {};
  if (req.query.user) filter.user = req.query.user;
  if (req.query.resource) filter.resource = req.query.resource;
  const [data, total] = await Promise.all([
    AuditLog.find(filter).populate('user', 'name email').sort({ createdAt: -1 }).skip(skip).limit(limit),
    AuditLog.countDocuments(filter),
  ]);
  sendSuccess(res, 'Audit logs fetched', data, buildPaginationMeta(total, page, limit));
}));

module.exports = router;
