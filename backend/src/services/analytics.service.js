const studentRepository = require('../repositories/student.repository');
const attendanceRepository = require('../repositories/attendance.repository');
const eventRepository = require('../repositories/event.repository');
const Attendance = require('../models/Attendance.model');
const Event = require('../models/Event.model');
const mongoose = require('mongoose');

class AnalyticsService {
  async getOverview() {
    const [totalStudents, totalEvents, recentAttendance] = await Promise.all([
      studentRepository.findAll({ filter: { isActive: true } }).then(r => r.total),
      eventRepository.count(),
      Attendance.countDocuments({
        markedAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
      }),
    ]);

    const attendanceRate = await this._getOverallAttendanceRate();
    return { totalStudents, totalEvents, recentAttendance, attendanceRate };
  }

  async _getOverallAttendanceRate() {
    const result = await Attendance.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);
    const stats = result.reduce((acc, { _id, count }) => ({ ...acc, [_id]: count }), {});
    const total = Object.values(stats).reduce((a, b) => a + b, 0);
    if (total === 0) return 0;
    const positive = (stats.present || 0) + (stats.late || 0);
    return Math.round((positive / total) * 100);
  }

  async getMonthlyTrends(year) {
    const y = parseInt(year) || new Date().getFullYear();
    return Attendance.aggregate([
      {
        $match: {
          markedAt: { $gte: new Date(`${y}-01-01`), $lte: new Date(`${y}-12-31`) },
        },
      },
      {
        $group: {
          _id: { month: { $month: '$markedAt' }, status: '$status' },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.month': 1 } },
    ]);
  }

  async getBranchWise() {
    return Attendance.aggregate([
      {
        $lookup: {
          from: 'students',
          localField: 'student',
          foreignField: '_id',
          as: 'student',
        },
      },
      { $unwind: '$student' },
      {
        $group: {
          _id: { branch: '$student.branch', status: '$status' },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.branch': 1 } },
    ]);
  }

  async getYearWise() {
    return Attendance.aggregate([
      {
        $lookup: {
          from: 'students',
          localField: 'student',
          foreignField: '_id',
          as: 'student',
        },
      },
      { $unwind: '$student' },
      {
        $group: {
          _id: { year: '$student.year', status: '$status' },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.year': 1 } },
    ]);
  }
}

module.exports = new AnalyticsService();
