const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    rollNumber: { type: String, required: true, unique: true, trim: true, uppercase: true },
    email: { type: String, lowercase: true, trim: true },
    phone: { type: String, trim: true },
    branch: { type: String, required: true, trim: true },
    year: { type: Number, required: true, min: 1, max: 5 },
    section: { type: String, trim: true },
    avatar: { type: String, default: null },
    gender: { type: String, enum: ['male', 'female', 'other', 'prefer_not_to_say'] },
    address: { type: String, trim: true },
    isActive: { type: Boolean, default: true },
    qrCode: { type: String },
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; return ret; } },
  },
);

studentSchema.index({ rollNumber: 1 }, { unique: true });
studentSchema.index({ name: 'text', rollNumber: 'text', email: 'text' });
studentSchema.index({ branch: 1, year: 1 });
studentSchema.index({ isActive: 1 });

module.exports = mongoose.model('Student', studentSchema);
