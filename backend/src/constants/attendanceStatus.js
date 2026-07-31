const ATTENDANCE_STATUS = Object.freeze({
  PRESENT: 'present',
  ABSENT: 'absent',
  LATE: 'late',
  EXCUSED: 'excused',
});

const ATTENDANCE_METHOD = Object.freeze({
  QR: 'qr',
  MANUAL: 'manual',
  BULK: 'bulk',
});

module.exports = { ATTENDANCE_STATUS, ATTENDANCE_METHOD };
