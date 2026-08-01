const Registration = require('../models/Registration.model');
const Student = require('../models/Student.model');
const Attendance = require('../models/Attendance.model');
const studentRepository = require('../repositories/student.repository');
const { getPagination, buildPaginationMeta, buildSortOptions } = require('../utils/pagination');

const SORTABLE_FIELDS = ['name', 'rollNo', 'branch', 'createdAt'];

class StudentService {
  async getAll(query) {
    const { page, limit, skip } = getPagination(query);
    const sort = buildSortOptions(query.sort, SORTABLE_FIELDS);
    const filter = this._buildFilter(query);

    let data, total;
    if (query.search) {
      const searchFilter = {
        ...filter,
        $or: [
          { name: { $regex: query.search, $options: 'i' } },
          { rollNo: { $regex: query.search, $options: 'i' } },
          { email: { $regex: query.search, $options: 'i' } },
          { studentNo: { $regex: query.search, $options: 'i' } }
        ]
      };
      [data, total] = await Promise.all([
        Registration.find(searchFilter).sort(sort).skip(skip).limit(limit),
        Registration.countDocuments(searchFilter),
      ]);
    } else {
      [data, total] = await Promise.all([
        Registration.find(filter).sort(sort).skip(skip).limit(limit),
        Registration.countDocuments(filter),
      ]);
    }

    const rollNumbers = data.map(r => r.rollNo);
    const students = await Student.find({ rollNo: { $in: rollNumbers } }).lean();
    
    const attendanceStats = await Attendance.aggregate([
      { $match: { student: { $in: students.map(s => s._id) } } },
      {
        $group: {
          _id: '$student',
          total: { $sum: 1 },
          present: {
            $sum: { $cond: [{ $in: ['$status', ['present', 'late']] }, 1, 0] }
          }
        }
      }
    ]);
    
    const attendanceMap = attendanceStats.reduce((acc, stat) => {
      acc[stat._id.toString()] = stat.total > 0 ? Math.round((stat.present / stat.total) * 100) : 0;
      return acc;
    }, {});

    const studentMap = students.reduce((acc, s) => {
      acc[s.rollNo] = s;
      return acc;
    }, {});

    const enrichedData = data.map(d => {
      const doc = d.toObject();
      const student = studentMap[doc.rollNo];
      doc.isPresent = student ? student.isPresent : false;
      doc.attendance = student ? (attendanceMap[student._id.toString()] || 0) : 0;
      return doc;
    });

    return { data: enrichedData, total, meta: buildPaginationMeta(total, page, limit) };
  }

  _buildFilter(query) {
    const filter = {};
    if (query.branch) filter.branch = query.branch;
    if (query.domain) filter.domain = query.domain;
    return filter;
  }

  async getById(id) {
    const student = await Registration.findById(id);
    if (!student) throw { status: 404, message: 'Student not found' };
    return student;
  }

  async create(data) {
    const existing = await Registration.findOne({ rollNo: data.rollNo });
    if (existing) throw { status: 409, message: 'A student with this roll number already exists' };
    return Registration.create(data);
  }

  async update(id, data) {
    if (data.rollNo) {
      const existing = await Registration.findOne({ rollNo: data.rollNo });
      if (existing && existing._id.toString() !== id) {
        throw { status: 409, message: 'Roll number already taken' };
      }
    }
    const student = await Registration.findByIdAndUpdate(id, data, { new: true, runValidators: true });
    if (!student) throw { status: 404, message: 'Student not found' };
    return student;
  }

  async delete(id) {
    const student = await Registration.findByIdAndDelete(id);
    if (!student) throw { status: 404, message: 'Student not found' };
  }

  async importFromCSV(records) {
    const sanitized = records.map((r) => ({
      name: r.name?.trim(),
      rollNo: r.rollNo?.trim().toUpperCase(),
      studentNo: r.studentNo?.trim(),
      email: r.email?.trim().toLowerCase(),
      branch: r.branch?.trim(),
      phone: r.phone?.trim(),
      domain: r.domain?.trim(),
      gender: r.gender?.trim(),
    })).filter((r) => r.name && r.rollNo && r.branch && r.email);

    const result = await Registration.insertMany(sanitized, { ordered: false });
    return {
      inserted: result.length,
      total: records.length,
    };
  }

  async getStats() {
    const [byBranch, byDomain] = await Promise.all([
      Registration.aggregate([
        { $group: { _id: '$branch', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
      Registration.aggregate([
        { $group: { _id: '$domain', count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
    ]);
    return { byBranch, byDomain };
  }
}

module.exports = new StudentService();
