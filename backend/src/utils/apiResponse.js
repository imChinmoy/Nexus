const sendResponse = (res, { status, success, message, data, meta }) => {
  const response = { success, message };
  if (data !== undefined) response.data = data;
  if (meta !== undefined) response.meta = meta;
  return res.status(status).json(response);
};

const sendSuccess = (res, message, data, meta, status = 200) =>
  sendResponse(res, { status, success: true, message, data, meta });

const sendCreated = (res, message, data) =>
  sendResponse(res, { status: 201, success: true, message, data });

const sendError = (res, message, status = 500, errors) => {
  const response = { success: false, message };
  if (errors) response.errors = errors;
  return res.status(status).json(response);
};

module.exports = { sendSuccess, sendCreated, sendError };
