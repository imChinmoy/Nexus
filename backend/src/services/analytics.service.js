const studentRepository = require('../repositories/student.repository');
const attendanceRepository = require('../repositories/attendance.repository');
const eventRepository = require('../repositories/event.repository');
const Attendance = require('../models/Attendance.model');
const Registration = require('../models/Registration.model');
const User = require('../models/User.model');
const Student = require('../models/Student.model');
const Event = require('../models/Event.model');
const mongoose = require('mongoose');

class AnalyticsService {
  async getOverview() {
    const [totalStudents, activeMembers, totalEvents, recentAttendance] = await Promise.all([
      Registration.countDocuments(),
      User.countDocuments({ isActive: true }),
      eventRepository.count(),
      Student.find({ isPresent: true }).sort({ lastMarkedAt: -1 }).limit(10),
    ]);

    const attendanceRate = await this._getOverallAttendanceRate();
    return { totalStudents, activeMembers, totalEvents, recentAttendance, attendanceRate };
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

  /**
   * Helper to validate and normalize a timezone string.
   * Defaults to Asia/Kolkata (canonical society operational timezone).
   * @param {string} tz
   * @returns {string}
   */
  _resolveTimezone(tz) {
    const defaultTz = process.env.APP_TIMEZONE || 'Asia/Kolkata';
    if (!tz || typeof tz !== 'string') return defaultTz;
    try {
      Intl.DateTimeFormat(undefined, { timeZone: tz.trim() });
      return tz.trim();
    } catch {
      return defaultTz;
    }
  }

  /**
   * Formats a date into YYYY-MM-DD in the specified timezone.
   * @param {Date} date
   * @param {string} tz
   * @returns {string}
   */
  _formatDateInTz(date, tz) {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: tz,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    return formatter.format(new Date(date));
  }

  /**
   * Retrieve annual activity heatmap data grouped by calendar date.
   * Supports 'events' (active/scheduled event dates) and 'attendance' (marked attendance records).
   *
   * @param {object} params
   * @param {number|string} params.year
   * @param {string} params.metric - 'events' | 'attendance'
   * @param {string} params.timezone - Target timezone (e.g. 'Asia/Kolkata')
   * @returns {Promise<object>}
   */
  async getActivityHeatmap({ year, metric = 'events', timezone }) {
    const currentYear = new Date().getFullYear();
    const y = parseInt(year, 10) || currentYear;
    const normalizedMetric = (metric || 'events').toLowerCase().trim() === 'attendance' ? 'attendance' : 'events';
    const tz = this._resolveTimezone(timezone);

    if (normalizedMetric === 'events') {
      return this._getEventsHeatmap(y, tz);
    } else {
      return this._getAttendanceHeatmap(y, tz);
    }
  }

  /**
   * Aggregate events activity for the given year.
   * Excludes cancelled events. Counts multi-day events on each active date.
   */
  async _getEventsHeatmap(year, tz) {
    // Broad query bounds to capture events overlapping the year in target timezone
    const queryStart = new Date(Date.UTC(year - 1, 11, 28, 0, 0, 0));
    const queryEnd = new Date(Date.UTC(year + 1, 0, 4, 0, 0, 0));

    const events = await Event.find({
      status: { $ne: 'cancelled' },
      startDate: { $lt: queryEnd },
      $or: [
        { endDate: { $gte: queryStart } },
        { endDate: null, startDate: { $gte: queryStart } },
      ],
    })
      .select('_id title type status startDate endDate venue capacity isAttendanceOpen')
      .lean();

    const daysMap = new Map();
    let totalUniqueEventsInYear = 0;
    let completedCount = 0;
    let upcomingCount = 0;
    const monthCounts = new Array(12).fill(0);

    for (const event of events) {
      if (!event.startDate) continue;
      const start = new Date(event.startDate);
      const end = event.endDate ? new Date(event.endDate) : start;
      if (isNaN(start.getTime()) || isNaN(end.getTime())) continue;

      // Apply event effective boundary logic
      const isEndDateOnly =
        (end.getUTCHours() === 0 && end.getUTCMinutes() === 0 && end.getUTCSeconds() === 0 && end.getUTCMilliseconds() === 0) ||
        (end.getHours() === 0 && end.getMinutes() === 0 && end.getSeconds() === 0 && end.getMilliseconds() === 0);

      const endBoundary = isEndDateOnly
        ? new Date(end.getFullYear(), end.getMonth(), end.getDate(), 23, 59, 59, 999)
        : end;

      const startDateStr = this._formatDateInTz(start, tz);
      const endDateStr = this._formatDateInTz(endBoundary, tz);

      // Check if event spans any date in the target year
      let cur = new Date(`${startDateStr}T00:00:00Z`);
      const endD = new Date(`${endDateStr}T00:00:00Z`);
      let spansYear = false;

      while (cur <= endD) {
        const dateStr = cur.toISOString().slice(0, 10);
        if (dateStr.startsWith(`${year}-`)) {
          spansYear = true;
          const monthIndex = parseInt(dateStr.slice(5, 7), 10) - 1;
          monthCounts[monthIndex]++;

          if (!daysMap.has(dateStr)) {
            daysMap.set(dateStr, {
              date: dateStr,
              count: 0,
              events: [],
            });
          }

          const dayData = daysMap.get(dateStr);
          dayData.count += 1;
          dayData.events.push({
            id: event._id.toString(),
            title: event.title,
            type: event.type,
            status: event.status,
            venue: event.venue || '',
            capacity: event.capacity || 0,
            isAttendanceOpen: event.isAttendanceOpen || false,
            startDate: event.startDate,
            endDate: event.endDate,
          });
        }
        cur.setUTCDate(cur.getUTCDate() + 1);
      }

      if (spansYear) {
        totalUniqueEventsInYear++;
        const effStatus = Event.calculateEffectiveStatus
          ? Event.calculateEffectiveStatus(event.startDate, event.endDate, event.status)
          : event.status;
        if (effStatus === 'completed') {
          completedCount++;
        } else {
          upcomingCount++;
        }
      }
    }

    // Convert daysMap to sorted array
    const days = Array.from(daysMap.values()).sort((a, b) => a.date.localeCompare(b.date));

    // Calculate busiest day
    let busiestDay = null;
    for (const day of days) {
      if (!busiestDay || day.count > busiestDay.count) {
        busiestDay = { date: day.date, count: day.count };
      }
    }

    // Calculate month with highest activity
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    let maxMonthCount = 0;
    let busiestPeriod = 'None';
    monthCounts.forEach((cnt, idx) => {
      if (cnt > maxMonthCount) {
        maxMonthCount = cnt;
        busiestPeriod = monthNames[idx];
      }
    });

    return {
      year,
      metric: 'events',
      timezone: tz,
      stats: {
        totalCount: totalUniqueEventsInYear,
        activeDays: days.length,
        busiestDay,
        busiestPeriod: maxMonthCount > 0 ? busiestPeriod : 'None',
        completedCount,
        upcomingCount,
      },
      days,
    };
  }

  /**
   * Aggregate attendance records marked for the given year.
   * Groups by markedAt converted to the society timezone.
   */
  async _getAttendanceHeatmap(year, tz) {
    const queryStart = new Date(Date.UTC(year - 1, 11, 28, 0, 0, 0));
    const queryEnd = new Date(Date.UTC(year + 1, 0, 4, 0, 0, 0));

    const pipeline = [
      {
        $match: {
          markedAt: { $type: 'date', $gte: queryStart, $lt: queryEnd },
        },
      },
      {
        $project: {
          dateStr: { $dateToString: { format: '%Y-%m-%d', date: '$markedAt', timezone: tz } },
          event: '$event',
          status: '$status',
          method: '$method',
        },
      },
      {
        $match: {
          dateStr: { $regex: `^${year}-` },
        },
      },
      {
        $group: {
          _id: {
            date: '$dateStr',
            event: '$event',
          },
          eventCheckins: { $sum: 1 },
        },
      },
      {
        $lookup: {
          from: 'events',
          localField: '_id.event',
          foreignField: '_id',
          as: 'eventDoc',
        },
      },
      {
        $unwind: { path: '$eventDoc', preserveNullAndEmptyArrays: true },
      },
      {
        $group: {
          _id: '$_id.date',
          count: { $sum: '$eventCheckins' },
          events: {
            $push: {
              id: '$_id.event',
              title: { $ifNull: ['$eventDoc.title', 'Event Check-in'] },
              count: '$eventCheckins',
            },
          },
        },
      },
      {
        $sort: { _id: 1 },
      },
    ];

    const results = await Attendance.aggregate(pipeline);

    let totalAttendance = 0;
    let busiestDay = null;
    const monthCounts = new Array(12).fill(0);

    const days = results.map((r) => {
      const date = r._id;
      const count = r.count;
      totalAttendance += count;

      const monthIndex = parseInt(date.slice(5, 7), 10) - 1;
      if (monthIndex >= 0 && monthIndex < 12) {
        monthCounts[monthIndex] += count;
      }

      if (!busiestDay || count > busiestDay.count) {
        busiestDay = { date, count };
      }

      return {
        date,
        count,
        events: r.events.map((e) => ({
          id: e.id ? e.id.toString() : '',
          title: e.title || 'Event Check-in',
          count: e.count,
        })),
      };
    });

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    let maxMonthCount = 0;
    let busiestPeriod = 'None';
    monthCounts.forEach((cnt, idx) => {
      if (cnt > maxMonthCount) {
        maxMonthCount = cnt;
        busiestPeriod = monthNames[idx];
      }
    });

    return {
      year,
      metric: 'attendance',
      timezone: tz,
      stats: {
        totalCount: totalAttendance,
        activeDays: days.length,
        busiestDay,
        busiestPeriod: maxMonthCount > 0 ? busiestPeriod : 'None',
      },
      days,
    };
  }
}

module.exports = new AnalyticsService();
