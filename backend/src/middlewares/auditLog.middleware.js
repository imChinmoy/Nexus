const AuditLog = require('../models/AuditLog.model');
const logger = require('../config/logger');

const auditLog = (action, resource) => async (req, res, next) => {
  const originalJson = res.json.bind(res);
  res.json = async (body) => {
    try {
      await AuditLog.create({
        user: req.user?._id,
        action,
        resource,
        resourceId: req.params.id || body?.data?._id,
        details: { method: req.method, path: req.path, body: req.body },
        ipAddress: req.ip,
        userAgent: req.headers['user-agent'],
        success: res.statusCode < 400,
        error: res.statusCode >= 400 ? body?.message : undefined,
      });
    } catch (err) {
      logger.error(`Audit log failed: ${err.message}`);
    }
    return originalJson(body);
  };
  next();
};

module.exports = { auditLog };
