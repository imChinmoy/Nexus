const mongoose = require('mongoose');
const attendanceRepository = require('../repositories/attendance.repository');
const eventRepository = require('../repositories/event.repository');
const Registration = require('../models/Registration.model');
const Student = require('../models/Student.model');
const qrResolverService = require('./qrResolver.service');
const registrationSourceService = require('./registrationSource.service');
const { verifyQRToken } = require('../utils/generateQR');
const { ATTENDANCE_STATUS, ATTENDANCE_METHOD } = require('../constants/attendanceStatus');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');
const logger = require('../config/logger');

class AttendanceService {
  /**
   * Validate that an event exists, is active, and accepts attendance within configured time window.
   */
  _validateEventForAttendance(event) {
    if (!event) {
      throw { status: 404, code: 'EVENT_NOT_FOUND', message: 'Event not found' };
    }
    if (['archived', 'cancelled'].includes(event.status)) {
      throw { status: 400, code: 'EVENT_INACTIVE', message: `Event is ${event.status}` };
    }
    if (!event.isAttendanceOpen) {
      throw { status: 400, code: 'ATTENDANCE_CLOSED', message: 'Attendance is not open for this event' };
    }

    const now = new Date();
    if (event.attendanceWindowStart && now < new Date(event.attendanceWindowStart)) {
      throw {
        status: 400,
        code: 'ATTENDANCE_WINDOW_NOT_STARTED',
        message: 'Attendance window has not started yet',
      };
    }
    if (event.attendanceWindowEnd && now > new Date(event.attendanceWindowEnd)) {
      throw {
        status: 400,
        code: 'ATTENDANCE_WINDOW_EXPIRED',
        message: 'Attendance window has expired',
      };
    }
  }

  /**
   * Resolve student reference for attendance from either Student, Registration ID, or event registration source.
   */
  async _resolveStudentById(studentOrRegId, event = null) {
    let student = await Student.findById(studentOrRegId).exec();
    if (student) return student;

    // Check if the ID belongs to a local Registration document
    const reg = await Registration.findById(studentOrRegId).exec();
    if (reg) {
      student = await qrResolverService._getOrCreateStudentFromRegistration(reg);
      return student;
    }

    // Check event-specific registration source if available
    if (event) {
      const sourceKey = registrationSourceService.resolveEventSourceKey(event);
      if (sourceKey && registrationSourceService.isConfigured(sourceKey)) {
        try {
          const { collection } = await registrationSourceService.getCollection(sourceKey);
          const isMongoId = mongoose.Types.ObjectId.isValid(studentOrRegId);
          const query = [];
          if (isMongoId) {
            query.push({ _id: new mongoose.Types.ObjectId(studentOrRegId) });
          }
          query.push({ rollNo: String(studentOrRegId).trim().toUpperCase() });
          query.push({ rollNo: String(studentOrRegId).trim() });
          query.push({ studentNo: String(studentOrRegId).trim() });

          const externalDoc = await collection.findOne({ $or: query });
          if (externalDoc) {
            student = await qrResolverService._getOrCreateStudentFromRegistration(externalDoc);
            return student;
          }
        } catch (err) {
          logger.warn('Failed querying event registration source in _resolveStudentById', { error: err.message });
        }
      }
    }

    return null;
  }

  /**
   * Dedicated entry-gate scan method.
   * Consumes existing student QR, resolves student, checks event window,
   * handles duplicate races safely, and records attendance.
   */
  async scanAttendance({ eventId, qrValue, userId }) {
    const startTime = Date.now();

    // Step 1: Event lookup & window validation
    const event = await eventRepository.findById(eventId);
    this._validateEventForAttendance(event);
    const eventValidationMs = Date.now() - startTime;

    // Step 2: Student resolution from external QR
    const resolveStart = Date.now();
    const student = await qrResolverService.resolveStudent(qrValue, event);
    if (!student) {
      throw {
        status: 404,
        code: 'STUDENT_NOT_FOUND',
        message: 'Student could not be resolved from scanned QR code',
      };
    }
    const qrResolutionMs = Date.now() - resolveStart;

    // Step 3: Check for existing attendance
    const existing = await attendanceRepository.findOne({ event: eventId, student: student._id });
    if (existing) {
      logger.info('Duplicate scan detected', {
        eventId,
        studentId: student._id,
        durationMs: Date.now() - startTime,
      });
      return {
        record: existing,
        isDuplicate: true,
        code: 'ALREADY_MARKED',
        message: 'Attendance already recorded for this student',
      };
    }

    // Step 4: Atomic insertion with race-condition error handling
    const dbWriteStart = Date.now();
    try {
      const created = await attendanceRepository.create({
        event: eventId,
        student: student._id,
        status: ATTENDANCE_STATUS.PRESENT,
        method: ATTENDANCE_METHOD.QR,
        markedBy: userId,
        markedAt: new Date(),
      });

      await attendanceRepository.createLog({
        event: eventId,
        student: student._id,
        action: 'mark',
        newStatus: ATTENDANCE_STATUS.PRESENT,
        performedBy: userId,
      });

      // Update student last marked timestamp
      await Student.updateOne({ _id: student._id }, { $set: { lastMarkedAt: new Date() } });

      const record = await attendanceRepository.findById(created._id);
      const totalDurationMs = Date.now() - startTime;

      logger.info('Attendance marked via QR successfully', {
        eventId,
        studentId: student._id,
        eventValidationMs,
        qrResolutionMs,
        dbWriteMs: Date.now() - dbWriteStart,
        totalDurationMs,
      });

      return {
        record,
        isDuplicate: false,
        code: 'ATTENDANCE_MARKED',
        message: 'Attendance marked successfully',
      };
    } catch (err) {
      if (err.code === 11000) {
        // Handled race condition: concurrent request inserted record first
        const dupRecord = await attendanceRepository.findOne({ event: eventId, student: student._id });
        logger.info('Concurrency duplicate resolved safely', {
          eventId,
          studentId: student._id,
          totalDurationMs: Date.now() - startTime,
        });
        return {
          record: dupRecord,
          isDuplicate: true,
          code: 'ALREADY_MARKED',
          message: 'Attendance already recorded for this student',
        };
      }
      throw err;
    }
  }

  /**
   * Manual attendance marking.
   */
  async markManual(eventId, studentId, status, userId, note) {
    const event = await eventRepository.findById(eventId);
    this._validateEventForAttendance(event);

    const student = await this._resolveStudentById(studentId, event);
    if (!student) throw { status: 404, code: 'STUDENT_NOT_FOUND', message: 'Registered student not found' };

    const existing = await attendanceRepository.findOne({ event: eventId, student: student._id });

    if (existing) {
      await attendanceRepository.createLog({
        event: eventId,
        student: student._id,
        action: 'update',
        previousStatus: existing.status,
        newStatus: status,
        performedBy: userId,
      });
      await Student.updateOne({ _id: student._id }, { $set: { lastMarkedAt: new Date() } });
      return attendanceRepository.updateById(existing._id, { status, note, markedBy: userId });
    }

    try {
      await attendanceRepository.createLog({
        event: eventId,
        student: student._id,
        action: 'mark',
        newStatus: status,
        performedBy: userId,
      });

      await Student.updateOne({ _id: student._id }, { $set: { lastMarkedAt: new Date() } });

      return await attendanceRepository.create({
        event: eventId,
        student: student._id,
        status,
        method: ATTENDANCE_METHOD.MANUAL,
        markedBy: userId,
        note,
      });
    } catch (err) {
      if (err.code === 11000) {
        return attendanceRepository.findOne({ event: eventId, student: student._id });
      }
      throw err;
    }
  }

  /**
   * Bulk attendance marking.
   */
  async markBulk(eventId, records, userId) {
    const event = await eventRepository.findById(eventId);
    this._validateEventForAttendance(event);

    const results = { success: 0, failed: 0, errors: [] };
    for (const record of records) {
      try {
        await this.markManual(eventId, record.studentId, record.status, userId, record.note);
        results.success++;
      } catch (err) {
        results.failed++;
        results.errors.push({ studentId: record.studentId, error: err.message });
      }
    }
    return results;
  }

  /**
   * Legacy QR token method (for backward compatibility).
   */
  async markViaQR(qrToken, studentId, userId) {
    let payload;
    try {
      payload = verifyQRToken(qrToken);
    } catch (err) {
      if (err.message === 'QR_EXPIRED') throw { status: 400, code: 'QR_EXPIRED', message: 'QR code has expired' };
      throw { status: 400, code: 'INVALID_QR', message: 'Invalid QR code' };
    }

    const { eventId, sessionId } = payload;
    const event = await eventRepository.findById(eventId);
    this._validateEventForAttendance(event);
    if (event.qrSessionId && event.qrSessionId !== sessionId) {
      throw { status: 400, code: 'QR_OUTDATED', message: 'QR code is outdated' };
    }

    const student = await this._resolveStudentById(studentId, event);
    if (!student) throw { status: 404, code: 'STUDENT_NOT_FOUND', message: 'Registered student not found' };

    const existing = await attendanceRepository.findOne({ event: eventId, student: student._id });
    if (existing) {
      return existing;
    }

    try {
      return await attendanceRepository.create({
        event: eventId,
        student: student._id,
        status: ATTENDANCE_STATUS.PRESENT,
        method: ATTENDANCE_METHOD.QR,
        markedBy: userId,
        qrSessionId: sessionId,
      });
    } catch (err) {
      if (err.code === 11000) {
        return attendanceRepository.findOne({ event: eventId, student: student._id });
      }
      throw err;
    }
  }

  async getByEvent(eventId, query) {
    const { skip, limit, page } = getPagination(query);
    const { data, total } = await attendanceRepository.findByEvent(eventId, { skip, limit });
    return { data, meta: buildPaginationMeta(total, page, limit) };
  }

  async getByStudent(studentId, query) {
    const { skip, limit, page } = getPagination(query);
    const { data, total } = await attendanceRepository.findByStudent(studentId, { skip, limit });
    return { data, meta: buildPaginationMeta(total, page, limit) };
  }

  async getEventStats(eventId) {
    const stats = await attendanceRepository.getEventStats(eventId);
    return stats.reduce((acc, { _id, count }) => ({ ...acc, [_id]: count }), {
      present: 0, absent: 0, late: 0, excused: 0,
    });
  }
}

module.exports = new AttendanceService();
