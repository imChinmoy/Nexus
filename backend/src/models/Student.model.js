const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema(
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
    isPresent: { type: Boolean, default: false },
    lastMarkedAt: { type: Date },
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; return ret; } },
  },
);

studentSchema.virtual('rollNumber').get(function () {
  return this.rollNo;
});

studentSchema.index({ name: 'text', rollNo: 'text', email: 'text' });
studentSchema.index({ domain: 1 });
studentSchema.index({ branch: 1 });
studentSchema.index({ isActive: 1 });
studentSchema.index({ lastMarkedAt: -1 });

module.exports = mongoose.model('Student', studentSchema);

