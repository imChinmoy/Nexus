const mongoose = require('mongoose');
const { ATTENDANCE_STATUS, ATTENDANCE_METHOD } = require('../constants/attendanceStatus');

const attendanceSchema = new mongoose.Schema(
  {
    event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    status: {
      type: String,
      enum: Object.values(ATTENDANCE_STATUS),
      required: true,
      default: ATTENDANCE_STATUS.PRESENT,
    },
    method: {
      type: String,
      enum: Object.values(ATTENDANCE_METHOD),
      required: true,
    },
    markedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    markedAt: { type: Date, default: Date.now },
    note: { type: String, maxlength: 500 },
    qrSessionId: { type: String },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true, transform: (_, ret) => { delete ret.__v; return ret; } },
  },
);

// Prevent duplicate attendance
attendanceSchema.index({ event: 1, student: 1 }, { unique: true });
attendanceSchema.index({ event: 1, status: 1 });
attendanceSchema.index({ student: 1, markedAt: -1 });
attendanceSchema.index({ markedAt: -1 });

module.exports = mongoose.model('Attendance', attendanceSchema);
