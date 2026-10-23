const logger = require('../config/logger');

const errorHandler = (err, req, res, next) => {
  let { status = 500, message = 'Internal server error', code } = err;

  // Mongoose errors
  if (err.name === 'CastError') {
    status = 400;
    message = `Invalid ${err.path}: ${err.value}`;
    code = code || 'INVALID_IDENTIFIER';
  }
  if (err.name === 'ValidationError') {
    status = 422;
    const errors = {};
    Object.keys(err.errors).forEach((k) => { errors[k] = err.errors[k].message; });
    return res.status(status).json({ success: false, code: code || 'VALIDATION_ERROR', message: 'Validation failed', errors });
  }
  if (err.code === 11000) {
    status = 409;
    const field = err.keyPattern ? Object.keys(err.keyPattern)[0] : 'record';
    message = `${field.charAt(0).toUpperCase() + field.slice(1)} already exists`;
    code = code || 'DUPLICATE_ENTRY';
  }
  if (err.name === 'JsonWebTokenError') { status = 401; message = 'Invalid token'; code = 'INVALID_TOKEN'; }
  if (err.name === 'TokenExpiredError') { status = 401; message = 'Token expired'; code = 'TOKEN_EXPIRED'; }

  if (status >= 500) {
    logger.error(`[${req.method}] ${req.path} >> StatusCode:: ${status}, Message:: ${err.message}`, { stack: err.stack });
  }

  const response = { success: false, message };
  if (code) response.code = code;
  res.status(status).json(response);
};

module.exports = errorHandler;

