const analyticsService = require('../services/analytics.service');
const { sendSuccess } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

exports.getOverview = asyncHandler(async (req, res) => {
  const data = await analyticsService.getOverview();
  sendSuccess(res, 'Analytics overview fetched', data);
});

exports.getMonthlyTrends = asyncHandler(async (req, res) => {
  const data = await analyticsService.getMonthlyTrends(req.query.year);
  sendSuccess(res, 'Monthly trends fetched', data);
});

exports.getBranchWise = asyncHandler(async (req, res) => {
  const data = await analyticsService.getBranchWise();
  sendSuccess(res, 'Branch-wise analytics fetched', data);
});

exports.getYearWise = asyncHandler(async (req, res) => {
  const data = await analyticsService.getYearWise();
  sendSuccess(res, 'Year-wise analytics fetched', data);
});
