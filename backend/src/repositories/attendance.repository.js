const Attendance = require('../models/Attendance.model');
const AttendanceLog = require('../models/AttendanceLog.model');

class AttendanceRepository {
  async create(data) { return Attendance.create(data); }

  async findOne(filter) {
    return Attendance.findOne(filter).populate('student', 'name rollNumber').exec();
  }

  async findById(id) { return Attendance.findById(id).populate('student event').exec(); }

  async findByEvent(eventId, { skip = 0, limit = 50 } = {}) {
    const [data, total] = await Promise.all([
      Attendance.find({ event: eventId })
        .populate('student', 'name rollNumber branch year')
        .populate('markedBy', 'name')
        .sort({ markedAt: -1 })
        .skip(skip)
        .limit(limit),
      Attendance.countDocuments({ event: eventId }),
    ]);
    return { data, total };
  }

  async findByStudent(studentId, { skip = 0, limit = 20 } = {}) {
    const [data, total] = await Promise.all([
      Attendance.find({ student: studentId })
        .populate('event', 'title startDate type')
        .sort({ markedAt: -1 })
        .skip(skip)
        .limit(limit),
      Attendance.countDocuments({ student: studentId }),
    ]);
    return { data, total };
  }

  async bulkCreate(records) {
    return Attendance.insertMany(records, { ordered: false });
  }

  async updateById(id, data) {
    return Attendance.findByIdAndUpdate(id, data, { new: true });
  }

  async getEventStats(eventId) {
    return Attendance.aggregate([
      { $match: { event: require('mongoose').Types.ObjectId.createFromHexString(eventId) } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);
  }

  async getStudentAttendanceRate(studentId) {
    const [total, present] = await Promise.all([
      Attendance.countDocuments({ student: studentId }),
      Attendance.countDocuments({ student: studentId, status: { $in: ['present', 'late'] } }),
    ]);
    return total === 0 ? 0 : Math.round((present / total) * 100);
  }

  async getMonthlyStats(year, month) {
    const { getMonthRange } = require('../utils/dateHelpers');
    const { start, end } = getMonthRange(year, month);
    return Attendance.aggregate([
      { $match: { markedAt: { $gte: start, $lte: end } } },
      { $group: { _id: { day: { $dayOfMonth: '$markedAt' }, status: '$status' }, count: { $sum: 1 } } },
      { $sort: { '_id.day': 1 } },
    ]);
  }

  async createLog(data) { return AttendanceLog.create(data); }
}

module.exports = new AttendanceRepository();
