const eventService = require('../services/event.service');
const { sendSuccess, sendCreated } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

exports.getAll = asyncHandler(async (req, res) => {
  const { data, meta } = await eventService.getAll(req.query);
  sendSuccess(res, 'Events fetched', data, meta);
});

exports.getById = asyncHandler(async (req, res) => {
  const event = await eventService.getById(req.params.id);
  sendSuccess(res, 'Event fetched', event);
});

exports.create = asyncHandler(async (req, res) => {
  const eventData = { ...req.body };
  if (req.file) {
    eventData.banner = req.file.path;
  }
  const event = await eventService.create(eventData, req.user._id);
  sendCreated(res, 'Event created successfully', event);
});

exports.update = asyncHandler(async (req, res) => {
  const eventData = { ...req.body };
  if (req.file) {
    eventData.banner = req.file.path;
  }
  const event = await eventService.update(req.params.id, eventData);
  sendSuccess(res, 'Event updated successfully', event);
});

exports.delete = asyncHandler(async (req, res) => {
  await eventService.delete(req.params.id);
  sendSuccess(res, 'Event deleted successfully');
});

exports.generateQR = asyncHandler(async (req, res) => {
  const qr = await eventService.generateQR(req.params.id);
  sendSuccess(res, 'QR generated', qr);
});

exports.toggleAttendance = asyncHandler(async (req, res) => {
  const { isOpen } = req.body;
  const event = await eventService.toggleAttendance(req.params.id, isOpen);
  sendSuccess(res, `Attendance ${isOpen ? 'opened' : 'closed'}`, event);
});

exports.archive = asyncHandler(async (req, res) => {
  const event = await eventService.archive(req.params.id);
  sendSuccess(res, 'Event archived', event);
});
