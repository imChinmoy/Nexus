const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema(
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
    isPresent: { type: Boolean, default: false },
    lastMarkedAt: { type: Date },
    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; return ret; } },
  },
);

studentSchema.index({ name: 'text', rollNo: 'text', email: 'text' });
studentSchema.index({ domain: 1 });
studentSchema.index({ branch: 1 });
studentSchema.index({ isActive: 1 });
studentSchema.index({ lastMarkedAt: -1 });

module.exports = mongoose.model('Student', studentSchema);
