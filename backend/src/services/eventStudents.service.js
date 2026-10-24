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

    // 2. Resolve registration source key from event (with canonical inference fallback)
    const sourceKey = registrationSourceService.resolveEventSourceKey(event);
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

    // Build fast lookup maps by roll number, student number, email, and ID
    const attendanceByRollNo = new Map();
    const attendanceByStudentNo = new Map();
    const attendanceByEmail = new Map();
    const attendanceByStudentId = new Map();

    const presentRolls = [];
    const absentRolls = [];
    const lateRolls = [];
    const excusedRolls = [];
    const presentStudentNos = [];
    const absentStudentNos = [];
    const lateStudentNos = [];
    const excusedStudentNos = [];

    let presentCount = 0;
    let absentCount = 0;
    let lateCount = 0;
    let excusedCount = 0;

    for (const record of attendanceRecords) {
      const normStatus = String(record.status || '').trim().toLowerCase();
      record.status = normStatus;

      if (normStatus === 'present') presentCount++;
      else if (normStatus === 'absent') absentCount++;
      else if (normStatus === 'late') lateCount++;
      else if (normStatus === 'excused') excusedCount++;

      if (!record.student) continue;

      const s = record.student;
      if (s._id) {
        attendanceByStudentId.set(String(s._id), record);
      }
      const studentRoll = s.rollNo || s.rollNumber;
      if (studentRoll) {
        const normRoll = String(studentRoll).trim().toUpperCase();
        attendanceByRollNo.set(normRoll, record);
        if (normStatus === 'present') presentRolls.push(normRoll);
        else if (normStatus === 'absent') absentRolls.push(normRoll);
        else if (normStatus === 'late') lateRolls.push(normRoll);
        else if (normStatus === 'excused') excusedRolls.push(normRoll);
      }
      const stNo = s.studentNo || s.studentNumber;
      if (stNo) {
        const normStudentNo = String(stNo).trim();
        attendanceByStudentNo.set(normStudentNo, record);
        if (normStatus === 'present') presentStudentNos.push(normStudentNo);
        else if (normStatus === 'absent') absentStudentNos.push(normStudentNo);
        else if (normStatus === 'late') lateStudentNos.push(normStudentNo);
        else if (normStatus === 'excused') excusedStudentNos.push(normStudentNo);
      }
      if (s.email) {
        attendanceByEmail.set(String(s.email).trim().toLowerCase(), record);
      }
    }

    // Helper to build match condition for collection
    // Handles string/numeric roll numbers, rollNo/rollNumber fields, and studentNo/studentNumber
    function buildMatchCondition(rolls, studentNos, isNotIn = false) {
      const stringRolls = (rolls || []).flatMap((r) => [
        String(r).trim().toUpperCase(),
        String(r).trim().toLowerCase(),
        String(r).trim(),
      ]);
      const numericRolls = (rolls || []).map((r) => Number(r)).filter((n) => !isNaN(n));
      const allRollValues = [...new Set([...stringRolls, ...numericRolls])];
      const allStudentNos = [...new Set((studentNos || []).map((st) => String(st).trim()))];

      if (allRollValues.length === 0 && allStudentNos.length === 0) {
        return isNotIn ? {} : { _id: { $in: [] } };
      }

      if (isNotIn) {
        const andClauses = [];
        if (allRollValues.length > 0) {
          andClauses.push({
            rollNo: { $nin: allRollValues },
            rollNumber: { $nin: allRollValues },
          });
        }
        if (allStudentNos.length > 0) {
          andClauses.push({
            studentNo: { $nin: allStudentNos },
            studentNumber: { $nin: allStudentNos },
          });
        }
        return andClauses.length === 1 ? andClauses[0] : { $and: andClauses };
      }

      const orClauses = [];
      if (allRollValues.length > 0) {
        orClauses.push({ rollNo: { $in: allRollValues } });
        orClauses.push({ rollNumber: { $in: allRollValues } });
      }
      if (allStudentNos.length > 0) {
        orClauses.push({ studentNo: { $in: allStudentNos } });
        orClauses.push({ studentNumber: { $in: allStudentNos } });
      }
      return { $or: orClauses };
    }

    // 5. Total registered students in this event's source
    const totalRegistered = await collection.countDocuments({});

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
    const andClauses = [];

    // Branch filter
    if (query.branch && query.branch.trim() && query.branch.trim().toLowerCase() !== 'all') {
      andClauses.push({ branch: { $regex: new RegExp(`^${escapeRegex(query.branch.trim())}$`, 'i') } });
    }

    // Attendance status filter
    if (query.attendanceStatus && query.attendanceStatus.trim() && query.attendanceStatus.trim().toLowerCase() !== 'all') {
      const targetStatus = query.attendanceStatus.trim().toLowerCase();
      if (targetStatus === 'not_marked' || targetStatus === 'not_scanned' || targetStatus === 'unmarked') {
        const allMarkedRolls = [...presentRolls, ...absentRolls, ...lateRolls, ...excusedRolls];
        const allMarkedStudentNos = [...presentStudentNos, ...absentStudentNos, ...lateStudentNos, ...excusedStudentNos];
        if (allMarkedRolls.length > 0 || allMarkedStudentNos.length > 0) {
          andClauses.push(buildMatchCondition(allMarkedRolls, allMarkedStudentNos, true));
        }
      } else if (['present', 'absent', 'late', 'excused'].includes(targetStatus)) {
        let targetRolls = [];
        let targetStudentNos = [];
        if (targetStatus === 'present') {
          targetRolls = presentRolls;
          targetStudentNos = presentStudentNos;
        } else if (targetStatus === 'absent') {
          targetRolls = absentRolls;
          targetStudentNos = absentStudentNos;
        } else if (targetStatus === 'late') {
          targetRolls = lateRolls;
          targetStudentNos = lateStudentNos;
        } else if (targetStatus === 'excused') {
          targetRolls = excusedRolls;
          targetStudentNos = excusedStudentNos;
        }

        andClauses.push(buildMatchCondition(targetRolls, targetStudentNos, false));
      }
    }

    // Search filter (scoped to this event's registration dataset)
    if (query.search && query.search.trim()) {
      const safe = escapeRegex(query.search.trim());
      const searchRegex = { $regex: safe, $options: 'i' };
      andClauses.push({
        $or: [
          { name: searchRegex },
          { rollNo: searchRegex },
          { rollNumber: searchRegex },
          { studentNo: searchRegex },
          { studentNumber: searchRegex },
        ],
      });
    }

    const filter = andClauses.length > 0 ? { $and: andClauses } : {};

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
      const rollNo = doc.rollNo !== undefined ? String(doc.rollNo).trim() : (doc.rollNumber !== undefined ? String(doc.rollNumber).trim() : '');
      const studentNo = doc.studentNo !== undefined ? String(doc.studentNo).trim() : (doc.studentNumber !== undefined ? String(doc.studentNumber).trim() : '');
      const email = doc.email !== undefined ? String(doc.email).trim().toLowerCase() : (doc.emailAddress !== undefined ? String(doc.emailAddress).trim().toLowerCase() : '');
      const docId = doc._id ? String(doc._id) : '';

      const attRecord = (rollNo ? attendanceByRollNo.get(rollNo.toUpperCase()) : null) ||
        (studentNo ? attendanceByStudentNo.get(studentNo) : null) ||
        (email ? attendanceByEmail.get(email) : null) ||
        (docId ? attendanceByStudentId.get(docId) : null) ||
        null;

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
