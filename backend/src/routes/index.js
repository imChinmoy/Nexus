const router = require('express').Router();

router.use('/auth', require('./auth.routes'));
router.use('/students', require('./student.routes'));
router.use('/members', require('./member.routes'));
router.use('/events', require('./event.routes'));
router.use('/attendance', require('./attendance.routes'));
router.use('/analytics', require('./analytics.routes'));
router.use('/reports', require('./report.routes'));
router.use('/users', require('./user.routes'));
router.use('/settings', require('./settings.routes'));
router.use('/notifications', require('./notification.routes'));
router.use('/audit-logs', require('./auditLog.routes'));

module.exports = router;
