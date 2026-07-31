const Student = require('../models/Student.model');

class StudentRepository {
  async create(data) { return Student.create(data); }

  async findById(id) { return Student.findById(id).exec(); }

  async findByRollNumber(rollNumber) {
    return Student.findOne({ rollNumber: rollNumber.toUpperCase() }).exec();
  }

  async findAll({ filter = {}, sort = { createdAt: -1 }, skip = 0, limit = 20 } = {}) {
    const [data, total] = await Promise.all([
      Student.find(filter).sort(sort).skip(skip).limit(limit),
      Student.countDocuments(filter),
    ]);
    return { data, total };
  }

  async search(query, filter = {}, { skip = 0, limit = 20 } = {}) {
    const searchFilter = {
      ...filter,
      $text: { $search: query },
    };
    const [data, total] = await Promise.all([
      Student.find(searchFilter, { score: { $meta: 'textScore' } })
        .sort({ score: { $meta: 'textScore' } })
        .skip(skip)
        .limit(limit),
      Student.countDocuments(searchFilter),
    ]);
    return { data, total };
  }

  async updateById(id, data) {
    return Student.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  }

  async deleteById(id) { return Student.findByIdAndDelete(id); }

  async bulkCreate(students) { return Student.insertMany(students, { ordered: false }); }

  async countByBranch() {
    return Student.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: '$branch', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);
  }

  async countByYear() {
    return Student.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: '$year', count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);
  }
}

module.exports = new StudentRepository();
