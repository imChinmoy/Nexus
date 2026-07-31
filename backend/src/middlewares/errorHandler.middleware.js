const logger = require('../config/logger');

const errorHandler = (err, req, res, next) => {
  let { status = 500, message = 'Internal server error' } = err;

  // Mongoose errors
  if (err.name === 'CastError') {
    status = 400;
    message = `Invalid ${err.path}: ${err.value}`;
  }
  if (err.name === 'ValidationError') {
    status = 422;
    const errors = {};
    Object.keys(err.errors).forEach((k) => { errors[k] = err.errors[k].message; });
    return res.status(status).json({ success: false, message: 'Validation failed', errors });
  }
  if (err.code === 11000) {
    status = 409;
    const field = Object.keys(err.keyPattern)[0];
    message = `${field.charAt(0).toUpperCase() + field.slice(1)} already exists`;
  }
  if (err.name === 'JsonWebTokenError') { status = 401; message = 'Invalid token'; }
  if (err.name === 'TokenExpiredError') { status = 401; message = 'Token expired'; }

  if (status >= 500) {
    logger.error(`[${req.method}] ${req.path} >> StatusCode:: ${status}, Message:: ${err.message}`, { stack: err.stack });
  }

  res.status(status).json({ success: false, message });
};

module.exports = errorHandler;
