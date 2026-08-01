const router = require('express').Router();
const eventController = require('../controllers/event.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize, requirePermission } = require('../middlewares/role.middleware');
const { validate } = require('../middlewares/validate.middleware');
const { createEventValidator, updateEventValidator } = require('../validators/event.validator');
const { ROLES } = require('../constants/roles');
const { PERMISSIONS } = require('../constants/permissions');
const eventUpload = require('../middlewares/eventUpload.middleware');

router.use(authenticate);

router.get('/', eventController.getAll);
router.get('/:id', eventController.getById);
router.post('/', requirePermission(PERMISSIONS.EVENT_ADD), eventUpload.single('banner'), createEventValidator, validate, eventController.create);
router.put('/:id', requirePermission(PERMISSIONS.EVENT_EDIT), eventUpload.single('banner'), updateEventValidator, validate, eventController.update);
router.delete('/:id', requirePermission(PERMISSIONS.EVENT_EDIT), eventController.delete);
router.post('/:id/qr', requirePermission(PERMISSIONS.EVENT_EDIT), eventController.generateQR);
router.patch('/:id/attendance-toggle', requirePermission(PERMISSIONS.EVENT_EDIT), eventController.toggleAttendance);
router.patch('/:id/archive', requirePermission(PERMISSIONS.EVENT_EDIT), eventController.archive);

module.exports = router;
