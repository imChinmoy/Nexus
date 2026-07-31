const router = require('express').Router();
const analyticsController = require('../controllers/analytics.controller');
const { authenticate } = require('../middlewares/auth.middleware');

router.use(authenticate);
router.get('/overview', analyticsController.getOverview);
router.get('/trends', analyticsController.getMonthlyTrends);
router.get('/branch-wise', analyticsController.getBranchWise);
router.get('/year-wise', analyticsController.getYearWise);

module.exports = router;
