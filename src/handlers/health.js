import { success, jsonResponse } from '../lib/response.js';

export const ping = async () => {
  const payload = success({ status: 'ok', time: new Date().toISOString() });
  return jsonResponse(200, payload);
};
