const { body, query } = require('express-validator');

const createStudentValidator = [
  body('name').trim().notEmpty().withMessage('Name is required').isLength({ max: 100 }),
  body('rollNumber').trim().notEmpty().withMessage('Roll number is required'),
  body('branch').trim().notEmpty().withMessage('Branch is required'),
  body('year').isInt({ min: 1, max: 5 }).withMessage('Year must be between 1 and 5'),
  body('email').optional().isEmail().normalizeEmail().withMessage('Valid email required'),
  body('phone').optional().matches(/^[0-9]{10}$/).withMessage('Valid 10-digit phone required'),
];

const updateStudentValidator = [
  body('name').optional().trim().notEmpty().isLength({ max: 100 }),
  body('year').optional().isInt({ min: 1, max: 5 }),
  body('email').optional().isEmail().normalizeEmail(),
  body('phone').optional().matches(/^[0-9]{10}$/),
];

module.exports = { createStudentValidator, updateStudentValidator };
