const eventRepository = require('../repositories/event.repository');
const { generateQRPayload } = require('../utils/generateQR');
const { getPagination, buildPaginationMeta, buildSortOptions } = require('../utils/pagination');

class EventService {
  async getAll(query) {
    const { page, limit, skip } = getPagination(query);
    const sort = buildSortOptions(query.sort, ['title', 'startDate', 'status', 'createdAt']);
    const filter = {};
    if (query.status) filter.status = query.status;
    if (query.type) filter.type = query.type;
    if (query.search) filter.$text = { $search: query.search };

    const { data, total } = await eventRepository.findAll({ filter, sort, skip, limit });
    return { data, meta: buildPaginationMeta(total, page, limit) };
  }

  async getById(id) {
    const event = await eventRepository.findById(id);
    if (!event) throw { status: 404, message: 'Event not found' };
    return event;
  }

  async create(data, userId) {
    return eventRepository.create({ ...data, createdBy: userId });
  }

  async update(id, data) {
    const event = await eventRepository.updateById(id, data);
    if (!event) throw { status: 404, message: 'Event not found' };
    return event;
  }

  async delete(id) {
    const event = await eventRepository.deleteById(id);
    if (!event) throw { status: 404, message: 'Event not found' };
  }

  async generateQR(eventId) {
    const event = await eventRepository.findById(eventId);
    if (!event) throw { status: 404, message: 'Event not found' };
    if (!event.isAttendanceOpen) throw { status: 400, message: 'Attendance is not open for this event' };

    const { token, sessionId, expiresAt } = generateQRPayload(eventId);
    await eventRepository.updateById(eventId, {
      qrToken: token,
      qrSessionId: sessionId,
      qrExpiresAt: expiresAt,
    });

    return { token, sessionId, expiresAt };
  }

  async toggleAttendance(eventId, isOpen) {
    const event = await eventRepository.updateById(eventId, { isAttendanceOpen: isOpen });
    if (!event) throw { status: 404, message: 'Event not found' };
    return event;
  }

  async archive(eventId) {
    return this.update(eventId, { status: 'archived' });
  }

  async getUpcoming(limit = 5) {
    return eventRepository.findUpcoming(limit);
  }
}

module.exports = new EventService();
