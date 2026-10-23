const { body } = require('express-validator');

const createEventValidator = [
  body('title').trim().notEmpty().withMessage('Title is required').isLength({ max: 200 }),
  body('description').optional().trim().isLength({ max: 2000 }),
  body('startDate').isISO8601().withMessage('Valid start date is required'),
  body('endDate').isISO8601().withMessage('Valid end date is required')
    .custom((val, { req }) => {
      if (new Date(val) <= new Date(req.body.startDate)) throw new Error('End date must be after start date');
      return true;
    }),
  body('type').optional().isIn(['workshop', 'seminar', 'hackathon', 'meeting', 'recruitment', 'social', 'other']),
  body('venue').optional().trim(),
  body('capacity').optional().isInt({ min: 0 }),
  body('isAttendanceOpen').optional().isBoolean(),
  body('attendanceWindowStart').optional().isISO8601(),
  body('attendanceWindowEnd').optional().isISO8601()
    .custom((val, { req }) => {
      if (req.body.attendanceWindowStart && new Date(val) <= new Date(req.body.attendanceWindowStart)) {
        throw new Error('Attendance window end must be after attendance window start');
      }
      return true;
    }),
];

const updateEventValidator = [
  body('title').optional().trim().notEmpty().isLength({ max: 200 }),
  body('description').optional().trim().isLength({ max: 2000 }),
  body('startDate').optional().isISO8601(),
  body('endDate').optional().isISO8601(),
  body('status').optional().isIn(['upcoming', 'ongoing', 'completed', 'cancelled', 'archived']),
  body('type').optional().isIn(['workshop', 'seminar', 'hackathon', 'meeting', 'recruitment', 'social', 'other']),
  body('venue').optional().trim(),
  body('capacity').optional().isInt({ min: 0 }),
  body('isAttendanceOpen').optional().isBoolean(),
  body('attendanceWindowStart').optional().isISO8601(),
  body('attendanceWindowEnd').optional().isISO8601(),
];

module.exports = { createEventValidator, updateEventValidator };
