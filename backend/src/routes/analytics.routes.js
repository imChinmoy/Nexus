const router = require('express').Router();
const analyticsController = require('../controllers/analytics.controller');
const { authenticate } = require('../middlewares/auth.middleware');
const { validate } = require('../middlewares/validate.middleware');
const { activityHeatmapValidator } = require('../validators/analytics.validator');

router.use(authenticate);
router.get('/overview', analyticsController.getOverview);
router.get('/trends', analyticsController.getMonthlyTrends);
router.get('/branch-wise', analyticsController.getBranchWise);
router.get('/year-wise', analyticsController.getYearWise);
router.get('/activity-heatmap', activityHeatmapValidator, validate, analyticsController.getActivityHeatmap);

module.exports = router;
