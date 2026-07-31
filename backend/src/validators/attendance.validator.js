const { body } = require('express-validator');

const qrScanValidator = [
  body('qrToken').notEmpty().withMessage('QR token is required'),
  body('studentId').isMongoId().withMessage('Valid student ID is required'),
];

const manualAttendanceValidator = [
  body('studentId').isMongoId().withMessage('Valid student ID is required'),
  body('status').isIn(['present','absent','late','excused']).withMessage('Valid status required'),
  body('note').optional().isLength({ max: 500 }),
];

const bulkAttendanceValidator = [
  body('records').isArray({ min: 1 }).withMessage('Records array is required'),
  body('records.*.studentId').isMongoId().withMessage('Valid student ID required'),
  body('records.*.status').isIn(['present','absent','late','excused']),
];

module.exports = { qrScanValidator, manualAttendanceValidator, bulkAttendanceValidator };
