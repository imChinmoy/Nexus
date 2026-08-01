const { body, query } = require('express-validator');

const createStudentValidator = [
  body('name').trim().notEmpty().withMessage('Name is required').isLength({ max: 100 }),
  body('rollNo').trim().notEmpty().withMessage('Roll number is required'),
  body('studentNo').trim().notEmpty().withMessage('Student number is required'),
  body('branch').trim().notEmpty().withMessage('Branch is required'),
  body('domain').trim().notEmpty().withMessage('Domain is required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('phone').matches(/^[0-9]{10}$/).withMessage('Valid 10-digit phone required'),
  body('gender').isIn(['Male', 'Female', 'Other']).withMessage('Invalid gender'),
];

const updateStudentValidator = [
  body('name').optional().trim().notEmpty().isLength({ max: 100 }),
  body('email').optional().isEmail().normalizeEmail(),
  body('phone').optional().matches(/^[0-9]{10}$/),
];

module.exports = { createStudentValidator, updateStudentValidator };
