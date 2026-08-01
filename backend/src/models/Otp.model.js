const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, lowercase: true, trim: true },
    otp: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    isUsed: { type: Boolean, default: false },
  },
  {
    timestamps: true,
  }
);

otpSchema.index({ email: 1 });
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // Auto-delete expired OTPs

module.exports = mongoose.model('Otp', otpSchema);
