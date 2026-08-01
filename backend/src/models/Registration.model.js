const mongoose = require('mongoose');

const registrationSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    rollNo: { type: String, required: true, unique: true, trim: true },
    studentNo: { type: String, required: true, unique: true, trim: true },
    phone: { type: String, required: true, trim: true },
    domain: { type: String, required: true, trim: true },
    github: { type: String, trim: true },
    unstopProfile: { type: String, trim: true },
    codingProfiles: [{ type: String }],
    hackerrank: { type: String, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    gender: { type: String, required: true, enum: ['Male', 'Female', 'Other'] },
    branch: { type: String, required: true, trim: true },
    hosteller: { type: Boolean, default: false },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; return ret; } },
  }
);

// Indexes are implicitly created by unique: true
registrationSchema.index({ domain: 1 });
registrationSchema.index({ branch: 1 });

module.exports = mongoose.model('Registration', registrationSchema);
