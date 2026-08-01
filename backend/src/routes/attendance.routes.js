const router = require('express').Router();
const attendanceController = require('../controllers/attendance.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize, requirePermission } = require('../middlewares/role.middleware');
const { validate } = require('../middlewares/validate.middleware');
const { qrScanValidator, manualAttendanceValidator, bulkAttendanceValidator } = require('../validators/attendance.validator');
const { qrLimiter } = require('../middlewares/rateLimiter.middleware');
const { ROLES } = require('../constants/roles');
const { PERMISSIONS } = require('../constants/permissions');

router.use(authenticate);

router.post('/scan', qrLimiter, qrScanValidator, validate, attendanceController.scanQR);
router.post('/event/:eventId/manual', requirePermission(PERMISSIONS.ATTENDANCE_MARK), manualAttendanceValidator, validate, attendanceController.markManual);
router.post('/event/:eventId/bulk', requirePermission(PERMISSIONS.ATTENDANCE_MARK), bulkAttendanceValidator, validate, attendanceController.markBulk);
router.get('/event/:eventId', attendanceController.getByEvent);
router.get('/event/:eventId/stats', attendanceController.getEventStats);
router.get('/student/:studentId', attendanceController.getByStudent);

module.exports = router;
