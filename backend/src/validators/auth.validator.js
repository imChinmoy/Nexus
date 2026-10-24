const { body } = require('express-validator');

const loginValidator = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

const forgotPasswordValidator = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
];

const resetPasswordValidator = [
  body('token').notEmpty().withMessage('Reset token is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
];

const changePasswordValidator = [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 8 }).withMessage('New password must be at least 8 characters'),
];

const updateProfileValidator = [
  body('name').optional().isString().isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('year').optional().trim().isString(),
  body('domain').optional().trim().isString(),
  body('phone').optional().trim().isString(),
  body('bio').optional().trim().isString().isLength({ max: 500 }),
  body('github').optional().trim().isString(),
  body('linkedin').optional().trim().isString(),
];

const registerValidator = [
  body('name').trim().notEmpty().withMessage('Name is required').isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('secretKey').trim().notEmpty().withMessage('Society secret passkey is required'),
  body('year').optional().trim().isString(),
  body('domain').optional().trim().isString(),
  body('phone').optional().trim().isString(),
  body('bio').optional().trim().isString().isLength({ max: 500 }),
  body('github').optional().trim().isString(),
  body('linkedin').optional().trim().isString(),
];

module.exports = {
  loginValidator,
  registerValidator,
  forgotPasswordValidator,
  resetPasswordValidator,
  changePasswordValidator,
  updateProfileValidator,
};
