const authService = require('../services/auth.service');
const { sendSuccess, sendCreated, sendError } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const { user, accessToken, refreshToken } = await authService.login(email, password, req.ip);
  res.cookie('refreshToken', refreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 7 * 24 * 60 * 60 * 1000,
  });
  sendSuccess(res, 'Login successful', { user, accessToken, refreshToken });
});

exports.refresh = asyncHandler(async (req, res) => {
  const token = req.cookies.refreshToken || req.body.refreshToken;
  if (!token) return sendError(res, 'Refresh token required', 401);
  const { accessToken, user } = await authService.refreshSession(token);
  sendSuccess(res, 'Token refreshed', { accessToken, user });
});

exports.logout = asyncHandler(async (req, res) => {
  const token = req.cookies.refreshToken || req.body.refreshToken;
  await authService.logout(req.user._id, token);
  res.clearCookie('refreshToken');
  sendSuccess(res, 'Logged out successfully');
});

exports.me = asyncHandler(async (req, res) => {
  sendSuccess(res, 'User profile fetched', req.user);
});

exports.forgotPassword = asyncHandler(async (req, res) => {
  await authService.forgotPassword(req.body.email);
  // Always return success to prevent user enumeration
  sendSuccess(res, 'If that email exists, a reset link has been sent');
});

exports.resetPassword = asyncHandler(async (req, res) => {
  await authService.resetPassword(req.body.token, req.body.password);
  sendSuccess(res, 'Password reset successfully');
});

exports.changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  await authService.changePassword(req.user._id, currentPassword, newPassword);
  sendSuccess(res, 'Password changed successfully');
});
