const Attendance = require('../models/Attendance.model');
const eventRepository = require('../repositories/event.repository');
const registrationSourceService = require('./registrationSource.service');
const logger = require('../config/logger');

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function deriveYearFromStudentNo(studentNo) {
  if (!studentNo || typeof studentNo !== 'string') return 2;
  const match = studentNo.match(/^(\d{2})/);
  if (!match) return 2;
  const joinYear = 2000 + parseInt(match[1], 10);
  const currentYear = new Date().getFullYear();
  const yearDiff = currentYear - joinYear + 1;
  return Math.min(Math.max(yearDiff, 1), 4);
}

class EventStudentsService {
  /**
   * Fetch registered students for a specific event with attendance status merged.
   *
   * @param {string} eventId
   * @param {object} query - page, limit, search, branch, attendanceStatus
   * @returns {Promise<{ data: Array, meta: object, counts: object }>}
   */
  async getStudentsByEvent(eventId, query = {}) {
    // 1. Verify event exists
    const event = await eventRepository.findById(eventId);
    if (!event) {
      throw { status: 404, code: 'EVENT_NOT_FOUND', message: 'Event not found' };
    }

    // 2. Resolve registration source key from event
    const sourceKey = event.registrationSourceKey || (event.meta && event.meta.registrationSourceKey);
    if (!sourceKey) {
      throw {
        status: 422,
        code: 'REGISTRATION_SOURCE_NOT_CONFIGURED',
        message: `Registration source is not configured for event "${event.title}"`,
      };
    }

    // 3. Resolve collection using trusted configuration registry (read-only access)
    const { collection } = await registrationSourceService.getCollection(sourceKey);

    // 4. Query Attendance records for this specific event
    let attendanceRecords = [];
    try {
      attendanceRecords = await Attendance.find({ event: eventId })
        .populate('student', 'rollNo studentNo name email')
        .lean()
        .exec();
    } catch (err) {
      logger.error('Failed to query attendance records for event', { eventId, error: err.message });
      throw {
        status: 500,
        code: 'ATTENDANCE_QUERY_FAILED',
        message: 'Failed to retrieve attendance records for this event',
      };
    }

    // Build fast lookup maps by roll number and student number
    const attendanceByRollNo = new Map();
    const attendanceByStudentNo = new Map();

    for (const record of attendanceRecords) {
      if (record.student && record.student.rollNo) {
        const normRoll = String(record.student.rollNo).trim().toUpperCase();
        attendanceByRollNo.set(normRoll, record);
      }
      if (record.student && record.student.studentNo) {
        const normStudentNo = String(record.student.studentNo).trim();
        attendanceByStudentNo.set(normStudentNo, record);
      }
    }

    // 5. Total registered students in this event's source
    const totalRegistered = await collection.countDocuments({});

    // Compute status counts for the selected event
    let presentCount = 0;
    let absentCount = 0;
    let lateCount = 0;
    let excusedCount = 0;

    for (const att of attendanceRecords) {
      if (att.status === 'present') presentCount++;
      else if (att.status === 'absent') absentCount++;
      else if (att.status === 'late') lateCount++;
      else if (att.status === 'excused') excusedCount++;
    }

    const markedCount = presentCount + absentCount + lateCount + excusedCount;
    const notMarkedCount = Math.max(0, totalRegistered - markedCount);

    const counts = {
      total: totalRegistered,
      present: presentCount,
      notMarked: notMarkedCount,
      absent: absentCount,
      late: lateCount,
      excused: excusedCount,
    };

    // If no students registered, return empty result early
    if (totalRegistered === 0) {
      return {
        data: [],
        meta: {
          page: 1,
          limit: parseInt(query.limit, 10) || 20,
          total: 0,
          totalPages: 0,
        },
        counts,
      };
    }

    // 6. Build filter for registrations query
    const filter = {};

    // Branch filter
    if (query.branch && query.branch.trim() && query.branch.trim().toLowerCase() !== 'all') {
      filter.branch = { $regex: new RegExp(`^${escapeRegex(query.branch.trim())}$`, 'i') };
    }

    // Attendance status filter
    if (query.attendanceStatus && query.attendanceStatus.trim() && query.attendanceStatus.trim().toLowerCase() !== 'all') {
      const targetStatus = query.attendanceStatus.trim().toLowerCase();
      if (targetStatus === 'not_marked' || targetStatus === 'not_scanned' || targetStatus === 'unmarked') {
        const markedRollNos = Array.from(attendanceByRollNo.keys());
        filter.rollNo = { $nin: markedRollNos };
      } else if (['present', 'absent', 'late', 'excused'].includes(targetStatus)) {
        const matchingRollNos = [];
        for (const [r, att] of attendanceByRollNo.entries()) {
          if (att.status === targetStatus) matchingRollNos.push(r);
        }
        filter.rollNo = { $in: matchingRollNos };
      }
    }

    // Search filter (scoped to this event's registration dataset)
    if (query.search && query.search.trim()) {
      const safe = escapeRegex(query.search.trim());
      const searchRegex = { $regex: safe, $options: 'i' };
      const searchFilter = {
        $or: [
          { name: searchRegex },
          { rollNo: searchRegex },
          { rollNumber: searchRegex },
          { studentNo: searchRegex },
          { studentNumber: searchRegex },
        ],
      };

      if (Object.keys(filter).length > 0) {
        filter.$and = [searchFilter];
      } else {
        Object.assign(filter, searchFilter);
      }
    }

    // 7. Server-side pagination & stable sorting
    const page = Math.max(1, parseInt(query.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
    const skip = (page - 1) * limit;
    const sort = { name: 1, rollNo: 1, _id: 1 };

    let docs = [];
    let filteredTotal = 0;

    try {
      [docs, filteredTotal] = await Promise.all([
        collection.find(filter).sort(sort).skip(skip).limit(limit).toArray(),
        collection.countDocuments(filter),
      ]);
    } catch (err) {
      logger.error('Failed to query registrations from registration source', { error: err.message });
      throw {
        status: 500,
        code: 'REGISTRATION_QUERY_FAILED',
        message: 'Failed to retrieve registrations from event source',
      };
    }

    // 8. Transform and merge attendance status with registrations
    const data = docs.map((doc) => {
      const rollNo = doc.rollNo || doc.rollNumber || '';
      const studentNo = doc.studentNo || doc.studentNumber || '';
      const normRoll = String(rollNo).trim().toUpperCase();
      const normStudentNo = String(studentNo).trim();

      const attRecord = attendanceByRollNo.get(normRoll) || attendanceByStudentNo.get(normStudentNo) || null;

      return {
        studentId: doc._id.toString(),
        name: doc.name || '',
        rollNo,
        studentNo,
        branch: doc.branch || '',
        year: doc.year || deriveYearFromStudentNo(studentNo),
        gender: doc.gender || null,
        hosteller: doc.hosteller !== undefined ? Boolean(doc.hosteller) : null,
        domain: doc.domain || null,
        attendance: attRecord
          ? {
              status: attRecord.status,
              markedAt: attRecord.markedAt,
              method: attRecord.method,
            }
          : null,
      };
    });

    return {
      data,
      meta: {
        page,
        limit,
        total: filteredTotal,
        totalPages: Math.ceil(filteredTotal / limit) || 0,
      },
      counts,
    };
  }
}

module.exports = new EventStudentsService();
