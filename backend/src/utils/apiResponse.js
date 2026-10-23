const sendResponse = (res, { status, success, message, code, data, meta }) => {
  const response = { success, message };
  if (code !== undefined) response.code = code;
  if (data !== undefined) response.data = data;
  if (meta !== undefined) response.meta = meta;
  return res.status(status).json(response);
};

const sendSuccess = (res, message, data, meta, status = 200, code) =>
  sendResponse(res, { status, success: true, message, code, data, meta });

const sendCreated = (res, message, data, code = 'CREATED') =>
  sendResponse(res, { status: 201, success: true, message, code, data });

const sendError = (res, message, status = 500, errors, code) => {
  const response = { success: false, message };
  if (code !== undefined) response.code = code;
  if (errors) response.errors = errors;
  return res.status(status).json(response);
};

module.exports = { sendResponse, sendSuccess, sendCreated, sendError };

