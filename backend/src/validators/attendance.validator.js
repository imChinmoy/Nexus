const { body, param } = require('express-validator');

const eventScanValidator = [
  param('eventId').isMongoId().withMessage('Valid event ID is required'),
  body('qrValue').trim().notEmpty().withMessage('Scanned QR value is required'),
];

const qrScanValidator = [
  body('qrToken').optional().notEmpty().withMessage('QR token is required'),
  body('qrValue').optional().notEmpty().withMessage('QR value is required'),
  body('studentId').optional().isMongoId().withMessage('Valid student ID is required'),
];

const manualAttendanceValidator = [
  param('eventId').isMongoId().withMessage('Valid event ID is required'),
  body('studentId').trim().notEmpty().withMessage('Valid student ID is required'),
  body('status')
    .customSanitizer((val) => (typeof val === 'string' ? val.toLowerCase().trim() : val))
    .isIn(['present', 'absent', 'late', 'excused', 'not_scanned', 'not_marked', 'unmarked'])
    .withMessage('Valid status required (present, absent, late, excused, not_scanned)'),
  body('note').optional().isLength({ max: 500 }),
];

const bulkAttendanceValidator = [
  param('eventId').isMongoId().withMessage('Valid event ID is required'),
  body('records').isArray({ min: 1 }).withMessage('Records array is required'),
  body('records.*.studentId').isMongoId().withMessage('Valid student ID required'),
  body('records.*.status').isIn(['present', 'absent', 'late', 'excused']),
];

module.exports = {
  eventScanValidator,
  qrScanValidator,
  manualAttendanceValidator,
  bulkAttendanceValidator,
};
