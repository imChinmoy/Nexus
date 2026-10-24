const { query } = require('express-validator');

const activityHeatmapValidator = [
  query('year')
    .optional()
    .isInt({ min: 2000, max: 2100 })
    .withMessage('Year must be an integer between 2000 and 2100'),
  query('metric')
    .optional()
    .isIn(['events', 'attendance'])
    .withMessage('Metric must be either "events" or "attendance"'),
  query('timezone')
    .optional()
    .isString()
    .trim()
    .isLength({ max: 50 })
    .withMessage('Timezone must be a valid timezone string'),
];

module.exports = {
  activityHeatmapValidator,
};
