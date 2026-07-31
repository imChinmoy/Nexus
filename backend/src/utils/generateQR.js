const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const generateQRPayload = (eventId) => {
  const sessionId = uuidv4();
  const payload = {
    eventId,
    sessionId,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (parseInt(process.env.QR_EXPIRY_MINUTES) || 10) * 60,
  };
  const token = jwt.sign(payload, process.env.QR_SECRET);
  return { token, sessionId, expiresAt: new Date(payload.exp * 1000) };
};

const verifyQRToken = (token) => {
  try {
    return jwt.verify(token, process.env.QR_SECRET);
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      throw new Error('QR_EXPIRED');
    }
    throw new Error('QR_INVALID');
  }
};

module.exports = { generateQRPayload, verifyQRToken };
