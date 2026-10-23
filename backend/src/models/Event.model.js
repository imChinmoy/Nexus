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
    registrationSourceKey: { type: String, trim: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    tags: [{ type: String, trim: true, lowercase: true }],
    meta: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; delete ret.qrToken; return ret; } },
  },
);

function calculateEffectiveStatus(startDate, endDate, status, now = new Date()) {
  const normalized = (status || '').toLowerCase().trim();
  if (normalized === 'cancelled' || normalized === 'archived') {
    return normalized;
  }
  const start = new Date(startDate);
  const end = new Date(endDate);

  const isEndDateOnly =
    (end.getUTCHours() === 0 && end.getUTCMinutes() === 0 && end.getUTCSeconds() === 0 && end.getUTCMilliseconds() === 0) ||
    (end.getHours() === 0 && end.getMinutes() === 0 && end.getSeconds() === 0 && end.getMilliseconds() === 0);

  const endBoundary = isEndDateOnly
    ? new Date(end.getFullYear(), end.getMonth(), end.getDate(), 23, 59, 59, 999)
    : end;

  const isStartDateOnly =
    (start.getUTCHours() === 0 && start.getUTCMinutes() === 0 && start.getUTCSeconds() === 0 && start.getUTCMilliseconds() === 0) ||
    (start.getHours() === 0 && start.getMinutes() === 0 && start.getSeconds() === 0 && start.getMilliseconds() === 0);

  const startBoundary = isStartDateOnly
    ? new Date(start.getFullYear(), start.getMonth(), start.getDate(), 0, 0, 0, 0)
    : start;

  if (now > endBoundary) return 'completed';
  if (now < startBoundary) return 'upcoming';
  return 'ongoing';
}

eventSchema.virtual('effectiveStatus').get(function () {
  return calculateEffectiveStatus(this.startDate, this.endDate, this.status);
});

eventSchema.index({ status: 1, startDate: -1 });
eventSchema.index({ isAttendanceOpen: 1 });
eventSchema.index({ title: 'text', description: 'text' });
eventSchema.index({ createdBy: 1 });

const EventModel = mongoose.model('Event', eventSchema);
EventModel.calculateEffectiveStatus = calculateEffectiveStatus;

module.exports = EventModel;
