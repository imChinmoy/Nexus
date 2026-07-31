const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 200 },
    description: { type: String, trim: true, maxlength: 2000 },
    type: {
      type: String,
      enum: ['workshop', 'seminar', 'hackathon', 'meeting', 'recruitment', 'social', 'other'],
      default: 'other',
    },
    status: {
      type: String,
      enum: ['upcoming', 'ongoing', 'completed', 'cancelled', 'archived'],
      default: 'upcoming',
    },
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    venue: { type: String, trim: true },
    capacity: { type: Number, min: 0 },
    attendanceWindowStart: { type: Date },
    attendanceWindowEnd: { type: Date },
    isAttendanceOpen: { type: Boolean, default: false },
    qrToken: { type: String, select: false },
    qrExpiresAt: { type: Date },
    qrSessionId: { type: String },
    banner: { type: String },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    tags: [{ type: String, trim: true, lowercase: true }],
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; delete ret.qrToken; return ret; } },
  },
);

eventSchema.index({ status: 1, startDate: -1 });
eventSchema.index({ isAttendanceOpen: 1 });
eventSchema.index({ title: 'text', description: 'text' });
eventSchema.index({ createdBy: 1 });

module.exports = mongoose.model('Event', eventSchema);
