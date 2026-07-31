const router = require('express').Router();
const { authenticate } = require('../middlewares/auth.middleware');
const asyncHandler = require('../utils/asyncHandler');
const Attendance = require('../models/Attendance.model');
const { sendSuccess } = require('../utils/apiResponse');
const { getMonthRange } = require('../utils/dateHelpers');

router.use(authenticate);

router.get('/monthly', asyncHandler(async (req, res) => {
  const { year = new Date().getFullYear(), month = new Date().getMonth() + 1 } = req.query;
  const { start, end } = getMonthRange(parseInt(year), parseInt(month));
  const data = await Attendance.find({ markedAt: { $gte: start, $lte: end } })
    .populate('student', 'name rollNumber branch year')
    .populate('event', 'title')
    .sort({ markedAt: -1 });
  sendSuccess(res, 'Monthly report fetched', data);
}));

router.get('/student/:studentId', asyncHandler(async (req, res) => {
  const data = await Attendance.find({ student: req.params.studentId })
    .populate('event', 'title startDate type').sort({ markedAt: -1 });
  sendSuccess(res, 'Student report fetched', data);
}));

router.get('/event/:eventId', asyncHandler(async (req, res) => {
  const data = await Attendance.find({ event: req.params.eventId })
    .populate('student', 'name rollNumber branch year').sort({ markedAt: -1 });
  sendSuccess(res, 'Event report fetched', data);
}));

module.exports = router;
