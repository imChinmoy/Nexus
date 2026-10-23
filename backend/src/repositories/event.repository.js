const Event = require('../models/Event.model');

class EventRepository {
  async create(data) { return Event.create(data); }

  async syncPastEvents(now = new Date()) {
    try {
      await Event.updateMany(
        { endDate: { $lt: now }, status: { $in: ['upcoming', 'ongoing'] } },
        { $set: { status: 'completed', isAttendanceOpen: false } }
      );
      await Event.updateMany(
        { startDate: { $lte: now }, endDate: { $gte: now }, status: 'upcoming' },
        { $set: { status: 'ongoing' } }
      );
    } catch (_) {
      // Non-blocking sync
    }
  }

  async findById(id, includeQR = false) {
    await this.syncPastEvents();
    const query = Event.findById(id).populate('createdBy', 'name email');
    if (includeQR) query.select('+qrToken');
    return query.exec();
  }

  async findAll({ filter = {}, sort = { startDate: -1 }, skip = 0, limit = 20 } = {}) {
    await this.syncPastEvents();
    const [data, total] = await Promise.all([
      Event.find(filter).populate('createdBy', 'name').sort(sort).skip(skip).limit(limit),
      Event.countDocuments(filter),
    ]);
    return { data, total };
  }

  async updateById(id, data) {
    return Event.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  }

  async deleteById(id) { return Event.findByIdAndDelete(id); }

  async findUpcoming(limit = 5) {
    return Event.find({ status: 'upcoming', startDate: { $gte: new Date() } })
      .sort({ startDate: 1 })
      .limit(limit)
      .exec();
  }

  async findByDateRange(start, end) {
    return Event.find({ startDate: { $gte: start, $lte: end } }).sort({ startDate: 1 });
  }

  async count(filter = {}) { return Event.countDocuments(filter); }
}

module.exports = new EventRepository();
