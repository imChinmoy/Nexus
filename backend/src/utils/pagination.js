const getPagination = (query) => {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit) || 20));
  const skip = (page - 1) * limit;
  return { page, limit, skip };
};

const buildPaginationMeta = (total, page, limit) => ({
  total,
  page,
  limit,
  totalPages: Math.ceil(total / limit),
  hasNext: page * limit < total,
  hasPrev: page > 1,
});

const buildSortOptions = (sortParam, allowedFields, defaultSort = { createdAt: -1 }) => {
  if (!sortParam) return defaultSort;
  const [field, order] = sortParam.split(':');
  if (!allowedFields.includes(field)) return defaultSort;
  return { [field]: order === 'asc' ? 1 : -1 };
};

module.exports = { getPagination, buildPaginationMeta, buildSortOptions };
