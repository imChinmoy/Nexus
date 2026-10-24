const mongoose = require('mongoose');

const registrationSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    rollNo: { type: String, required: true, unique: true, trim: true },
    studentNo: { type: String, required: true, unique: true, trim: true },
    phone: { type: String, trim: true, default: '0000000000' },
    domain: { type: String, trim: true, default: 'General' },
    github: { type: String, trim: true },
    unstopProfile: { type: String, trim: true },
    codingProfiles: [{ type: String }],
    hackerrank: { type: String, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    gender: { type: String, enum: ['Male', 'Female', 'Other'], default: 'Other' },
    branch: { type: String, trim: true, default: 'General' },
    hosteller: { type: Boolean, default: false },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; return ret; } },
  }
);

registrationSchema.virtual('rollNumber').get(function () {
  return this.rollNo;
});

// Indexes
registrationSchema.index({ domain: 1 });
registrationSchema.index({ branch: 1 });

module.exports = mongoose.model('Registration', registrationSchema);

