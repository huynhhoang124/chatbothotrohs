export const success = (data = null, meta = {}) => ({
  success: true,
  data,
  meta
});

export const fail = (code, message, details = []) => ({
  success: false,
  error: {
    code,
    message,
    details
  }
});

export const jsonResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(body)
});
