const rateLimit = require('express-rate-limit');

const globalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 500,
  keyGenerator: (req) => (req.user?._id ? `user_${req.user._id}` : req.ip),
  message: { success: false, code: 'RATE_LIMIT_EXCEEDED', message: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_AUTH_MAX, 10) || 15,
  message: { success: false, code: 'AUTH_RATE_LIMIT_EXCEEDED', message: 'Too many authentication attempts. Try again in 15 minutes.' },
  skipSuccessfulRequests: true,
  standardHeaders: true,
  legacyHeaders: false,
});

const qrLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_QR_WINDOW_MS, 10) || 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_QR_MAX, 10) || 120,
  keyGenerator: (req) => (req.user?._id ? `qr_user_${req.user._id}` : `qr_ip_${req.ip}`),
  message: { success: false, code: 'RATE_LIMIT_EXCEEDED', message: 'Too many QR scan attempts. Please wait a moment.' },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = { globalLimiter, authLimiter, qrLimiter };

