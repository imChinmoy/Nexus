const attendanceService = require('../services/attendance.service');
const { sendSuccess, sendCreated } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

exports.scanQR = asyncHandler(async (req, res) => {
  const { qrToken, studentId } = req.body;
  const record = await attendanceService.markViaQR(qrToken, studentId, req.user._id);
  sendCreated(res, 'Attendance marked via QR', record);
});

exports.markManual = asyncHandler(async (req, res) => {
  const { studentId, status, note } = req.body;
  const record = await attendanceService.markManual(
    req.params.eventId, studentId, status, req.user._id, note,
  );
  sendSuccess(res, 'Attendance marked', record);
});

exports.markBulk = asyncHandler(async (req, res) => {
  const result = await attendanceService.markBulk(
    req.params.eventId, req.body.records, req.user._id,
  );
  sendSuccess(res, 'Bulk attendance processed', result);
});

exports.getByEvent = asyncHandler(async (req, res) => {
  const { data, meta } = await attendanceService.getByEvent(req.params.eventId, req.query);
  sendSuccess(res, 'Attendance fetched', data, meta);
});

exports.getByStudent = asyncHandler(async (req, res) => {
  const { data, meta } = await attendanceService.getByStudent(req.params.studentId, req.query);
  sendSuccess(res, 'Attendance history fetched', data, meta);
});

exports.getEventStats = asyncHandler(async (req, res) => {
  const stats = await attendanceService.getEventStats(req.params.eventId);
  sendSuccess(res, 'Stats fetched', stats);
});
