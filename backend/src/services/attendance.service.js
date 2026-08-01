const attendanceRepository = require('../repositories/attendance.repository');
const eventRepository = require('../repositories/event.repository');
const Registration = require('../models/Registration.model');
const Student = require('../models/Student.model');
const { verifyQRToken } = require('../utils/generateQR');
const { ATTENDANCE_STATUS, ATTENDANCE_METHOD } = require('../constants/attendanceStatus');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');

class AttendanceService {
  async _syncToStudentModel(registrationId, status) {
    const reg = await Registration.findById(registrationId);
    if (!reg) return null;

    const studentData = {
      name: reg.name,
      rollNo: reg.rollNo,
      studentNo: reg.studentNo,
      phone: reg.phone,
      domain: reg.domain,
      github: reg.github,
      unstopProfile: reg.unstopProfile,
      codingProfiles: reg.codingProfiles,
      hackerrank: reg.hackerrank,
      email: reg.email,
      gender: reg.gender,
      branch: reg.branch,
      hosteller: reg.hosteller,
      isPresent: status === ATTENDANCE_STATUS.PRESENT,
      lastMarkedAt: new Date(),
    };

    let student = await Student.findOne({ rollNo: reg.rollNo });
    if (student) {
      Object.assign(student, studentData);
      await student.save();
    } else {
      student = await Student.create(studentData);
    }
    return student;
  }

  async markViaQR(qrToken, studentId, userId) {
    let payload;
    try {
      payload = verifyQRToken(qrToken);
    } catch (err) {
      if (err.message === 'QR_EXPIRED') throw { status: 400, message: 'QR code has expired' };
      throw { status: 400, message: 'Invalid QR code' };
    }

    const { eventId, sessionId } = payload;
    const event = await eventRepository.findById(eventId);
    if (!event) throw { status: 404, message: 'Event not found' };
    if (!event.isAttendanceOpen) throw { status: 400, message: 'Attendance window is closed' };
    if (event.qrSessionId !== sessionId) throw { status: 400, message: 'QR code is outdated' };

    const student = await this._syncToStudentModel(studentId, ATTENDANCE_STATUS.PRESENT);
    if (!student) throw { status: 404, message: 'Registered user not found' };

    const existing = await attendanceRepository.findOne({ event: eventId, student: student._id });
    if (existing) throw { status: 409, message: 'Attendance already recorded for this student' };

    return attendanceRepository.create({
      event: eventId,
      student: student._id,
      status: ATTENDANCE_STATUS.PRESENT,
      method: ATTENDANCE_METHOD.QR,
      markedBy: userId,
      qrSessionId: sessionId,
    });
  }

  async markManual(eventId, studentId, status, userId, note) {
    const event = await eventRepository.findById(eventId);
    if (!event) throw { status: 404, message: 'Event not found' };

    const student = await this._syncToStudentModel(studentId, status);
    if (!student) throw { status: 404, message: 'Registered user not found' };

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
      return attendanceRepository.updateById(existing._id, { status, note, markedBy: userId });
    }

    await attendanceRepository.createLog({
      event: eventId,
      student: student._id,
      action: 'mark',
      newStatus: status,
      performedBy: userId,
    });

    return attendanceRepository.create({
      event: eventId,
      student: student._id,
      status,
      method: ATTENDANCE_METHOD.MANUAL,
      markedBy: userId,
      note,
    });
  }

  async markBulk(eventId, records, userId) {
    const event = await eventRepository.findById(eventId);
    if (!event) throw { status: 404, message: 'Event not found' };

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
