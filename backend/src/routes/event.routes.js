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
router.post('/', authorize(ROLES.SUPER_ADMIN), eventUpload.single('banner'), createEventValidator, validate, eventController.create);
router.put('/:id', authorize(ROLES.SUPER_ADMIN), eventUpload.single('banner'), updateEventValidator, validate, eventController.update);
router.delete('/:id', authorize(ROLES.SUPER_ADMIN), eventController.delete);
router.post('/:id/qr', authorize(ROLES.SUPER_ADMIN), eventController.generateQR);
router.patch('/:id/attendance-toggle', authorize(ROLES.SUPER_ADMIN), eventController.toggleAttendance);
router.patch('/:id/archive', authorize(ROLES.SUPER_ADMIN), eventController.archive);

module.exports = router;
