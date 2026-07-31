const studentRepository = require('../repositories/student.repository');
const { getPagination, buildPaginationMeta, buildSortOptions } = require('../utils/pagination');

const SORTABLE_FIELDS = ['name', 'rollNumber', 'branch', 'year', 'createdAt'];

class StudentService {
  async getAll(query) {
    const { page, limit, skip } = getPagination(query);
    const sort = buildSortOptions(query.sort, SORTABLE_FIELDS);
    const filter = this._buildFilter(query);

    if (query.search) {
      const { data, total } = await studentRepository.search(query.search, filter, { skip, limit });
      return { data, meta: buildPaginationMeta(total, page, limit) };
    }

    const { data, total } = await studentRepository.findAll({ filter, sort, skip, limit });
    return { data, meta: buildPaginationMeta(total, page, limit) };
  }

  _buildFilter(query) {
    const filter = {};
    if (query.branch) filter.branch = query.branch;
    if (query.year) filter.year = parseInt(query.year);
    if (query.isActive !== undefined) filter.isActive = query.isActive === 'true';
    else filter.isActive = true;
    return filter;
  }

  async getById(id) {
    const student = await studentRepository.findById(id);
    if (!student) throw { status: 404, message: 'Student not found' };
    return student;
  }

  async create(data) {
    const existing = await studentRepository.findByRollNumber(data.rollNumber);
    if (existing) throw { status: 409, message: 'A student with this roll number already exists' };
    return studentRepository.create(data);
  }

  async update(id, data) {
    if (data.rollNumber) {
      const existing = await studentRepository.findByRollNumber(data.rollNumber);
      if (existing && existing._id.toString() !== id) {
        throw { status: 409, message: 'Roll number already taken' };
      }
    }
    const student = await studentRepository.updateById(id, data);
    if (!student) throw { status: 404, message: 'Student not found' };
    return student;
  }

  async delete(id) {
    const student = await studentRepository.deleteById(id);
    if (!student) throw { status: 404, message: 'Student not found' };
  }

  async importFromCSV(records) {
    const sanitized = records.map((r) => ({
      name: r.name?.trim(),
      rollNumber: r.rollNumber?.trim().toUpperCase(),
      email: r.email?.trim().toLowerCase(),
      branch: r.branch?.trim(),
      year: parseInt(r.year),
      phone: r.phone?.trim(),
      section: r.section?.trim(),
    })).filter((r) => r.name && r.rollNumber && r.branch && r.year);

    const result = await studentRepository.bulkCreate(sanitized);
    return {
      inserted: result.length,
      total: records.length,
    };
  }

  async getStats() {
    const [byBranch, byYear] = await Promise.all([
      studentRepository.countByBranch(),
      studentRepository.countByYear(),
    ]);
    return { byBranch, byYear };
  }
}

module.exports = new StudentService();
