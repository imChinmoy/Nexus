const router = require('express').Router();
const studentController = require('../controllers/student.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { authorize } = require('../middlewares/role.middleware');
const { validate } = require('../middlewares/validate.middleware');
const { createStudentValidator, updateStudentValidator } = require('../validators/student.validator');
const { ROLES } = require('../constants/roles');
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

router.use(authenticate);

router.get('/', studentController.getAll);
router.get('/stats', studentController.getStats);
router.get('/:id', studentController.getById);
router.post('/', authorize(ROLES.COORDINATOR), createStudentValidator, validate, studentController.create);
router.put('/:id', authorize(ROLES.COORDINATOR), updateStudentValidator, validate, studentController.update);
router.delete('/:id', authorize(ROLES.ADMIN), studentController.delete);
router.post('/import', authorize(ROLES.ADMIN), upload.single('file'), studentController.importCSV);

module.exports = router;
