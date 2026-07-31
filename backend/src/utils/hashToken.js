const crypto = require('crypto');

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const generateResetToken = () => {
  const token = crypto.randomBytes(32).toString('hex');
  const hashedToken = hashToken(token);
  const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  return { token, hashedToken, expiry };
};

module.exports = { hashToken, generateResetToken };
