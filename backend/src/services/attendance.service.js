const attendanceRepository = require('../repositories/attendance.repository');
const eventRepository = require('../repositories/event.repository');
const studentRepository = require('../repositories/student.repository');
const { verifyQRToken } = require('../utils/generateQR');
const { ATTENDANCE_STATUS, ATTENDANCE_METHOD } = require('../constants/attendanceStatus');
const { getPagination, buildPaginationMeta } = require('../utils/pagination');

class AttendanceService {
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

    const existing = await attendanceRepository.findOne({ event: eventId, student: studentId });
    if (existing) throw { status: 409, message: 'Attendance already recorded for this student' };

    const student = await studentRepository.findById(studentId);
    if (!student) throw { status: 404, message: 'Student not found' };

    return attendanceRepository.create({
      event: eventId,
      student: studentId,
      status: ATTENDANCE_STATUS.PRESENT,
      method: ATTENDANCE_METHOD.QR,
      markedBy: userId,
      qrSessionId: sessionId,
    });
  }

  async markManual(eventId, studentId, status, userId, note) {
    const [event, student] = await Promise.all([
      eventRepository.findById(eventId),
      studentRepository.findById(studentId),
    ]);

    if (!event) throw { status: 404, message: 'Event not found' };
    if (!student) throw { status: 404, message: 'Student not found' };

    const existing = await attendanceRepository.findOne({ event: eventId, student: studentId });

    if (existing) {
      await attendanceRepository.createLog({
        event: eventId,
        student: studentId,
        action: 'update',
        previousStatus: existing.status,
        newStatus: status,
        performedBy: userId,
      });
      return attendanceRepository.updateById(existing._id, { status, note, markedBy: userId });
    }

    await attendanceRepository.createLog({
      event: eventId,
      student: studentId,
      action: 'mark',
      newStatus: status,
      performedBy: userId,
    });

    return attendanceRepository.create({
      event: eventId,
      student: studentId,
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
