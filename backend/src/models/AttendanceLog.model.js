const mongoose = require('mongoose');

const attendanceLogSchema = new mongoose.Schema(
  {
    event: { type: mongoose.Schema.Types.ObjectId, ref: 'Event', required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    action: { type: String, enum: ['mark', 'update', 'delete'], required: true },
    previousStatus: { type: String },
    newStatus: { type: String },
    performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reason: { type: String },
    ipAddress: { type: String },
    userAgent: { type: String },
  },
  { timestamps: true },
);

attendanceLogSchema.index({ event: 1, student: 1 });
attendanceLogSchema.index({ createdAt: -1 });

module.exports = mongoose.model('AttendanceLog', attendanceLogSchema);
