const studentService = require('../services/student.service');
const { sendSuccess, sendCreated, sendError } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

exports.getAll = asyncHandler(async (req, res) => {
  const { data, meta } = await studentService.getAll(req.query);
  sendSuccess(res, 'Students fetched', data, meta);
});

exports.getById = asyncHandler(async (req, res) => {
  const student = await studentService.getById(req.params.id);
  sendSuccess(res, 'Student fetched', student);
});

exports.create = asyncHandler(async (req, res) => {
  const student = await studentService.create(req.body);
  sendCreated(res, 'Student created successfully', student);
});

exports.update = asyncHandler(async (req, res) => {
  const student = await studentService.update(req.params.id, req.body);
  sendSuccess(res, 'Student updated successfully', student);
});

exports.delete = asyncHandler(async (req, res) => {
  await studentService.delete(req.params.id);
  sendSuccess(res, 'Student deleted successfully');
});

exports.importCSV = asyncHandler(async (req, res) => {
  if (!req.file) return sendError(res, 'CSV file is required', 400);
  const csv = require('csv-parse/sync');
  const records = csv.parse(req.file.buffer, { columns: true, skip_empty_lines: true });
  const result = await studentService.importFromCSV(records);
  sendSuccess(res, `Imported ${result.inserted} students`, result);
});

exports.getStats = asyncHandler(async (req, res) => {
  const stats = await studentService.getStats();
  sendSuccess(res, 'Stats fetched', stats);
});
