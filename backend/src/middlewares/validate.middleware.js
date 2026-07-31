const { validationResult } = require('express-validator');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const fieldErrors = {};
    errors.array().forEach(({ path, msg }) => {
      fieldErrors[path] = msg;
    });
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: fieldErrors,
    });
  }
  next();
};

module.exports = { validate };
