const router = require('express').Router();
const attendanceController = require('../controllers/attendance.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { requirePermission } = require('../middlewares/role.middleware');
const { validate } = require('../middlewares/validate.middleware');
const {
  eventScanValidator,
  qrScanValidator,
  manualAttendanceValidator,
  bulkAttendanceValidator,
} = require('../validators/attendance.validator');
const { qrLimiter } = require('../middlewares/rateLimiter.middleware');
const { PERMISSIONS } = require('../constants/permissions');

router.use(authenticate);

// Dedicated event-aware scan endpoint for continuous entry-gate scanning
router.post(
  '/event/:eventId/scan',
  requirePermission(PERMISSIONS.ATTENDANCE_MARK),
  qrLimiter,
  eventScanValidator,
  validate,
  attendanceController.scanEventQR,
);

// Backward-compatible QR scan endpoint
router.post(
  '/scan',
  requirePermission(PERMISSIONS.ATTENDANCE_MARK),
  qrLimiter,
  qrScanValidator,
  validate,
  attendanceController.scanQR,
);

// Manual and bulk attendance routes
router.post(
  '/event/:eventId/manual',
  requirePermission(PERMISSIONS.ATTENDANCE_MARK),
  manualAttendanceValidator,
  validate,
  attendanceController.markManual,
);

router.post(
  '/event/:eventId/bulk',
  requirePermission(PERMISSIONS.ATTENDANCE_MARK),
  bulkAttendanceValidator,
  validate,
  attendanceController.markBulk,
);

router.get('/event/:eventId', attendanceController.getByEvent);
router.get('/event/:eventId/stats', attendanceController.getEventStats);
router.get('/student/:studentId', attendanceController.getByStudent);

module.exports = router;
