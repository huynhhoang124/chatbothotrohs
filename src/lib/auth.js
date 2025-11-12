import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { config } from './config.js';
import { fail, jsonResponse } from './response.js';

const SALT_ROUNDS = 10;

export const hashPassword = async (password) => bcrypt.hash(password, SALT_ROUNDS);
export const comparePassword = async (password, hash) => bcrypt.compare(password, hash);

export const signToken = (payload) =>
  jwt.sign(payload, config.jwtSecret, {
    algorithm: 'HS256',
    expiresIn: '7d'
  });

export const verifyToken = (token) => {
  try {
    return jwt.verify(token, config.jwtSecret);
  } catch (error) {
    return null;
  }
};

export const getTokenFromHeader = (req) => {
  const authHeader = req.headers?.authorization || req.headers?.Authorization;
  if (!authHeader) return null;
  const [scheme, token] = authHeader.split(' ');
  if (scheme !== 'Bearer' || !token) return null;
  return token;
};

export const requireAuth = (req, res, next) => {
  const token = getTokenFromHeader(req);
  if (!token) {
    const response = jsonResponse(401, fail('UNAUTHORIZED', 'Yêu cầu đăng nhập.'));
    return res.status(response.statusCode).json(response.body ? JSON.parse(response.body) : {});
  }
  const decoded = verifyToken(token);
  if (!decoded) {
    const response = jsonResponse(401, fail('UNAUTHORIZED', 'Token không hợp lệ.'));
    return res.status(response.statusCode).json(response.body ? JSON.parse(response.body) : {});
  }
  req.user = decoded;
  return next();
};

export const buildAuthSuccess = (user) => {
  const token = signToken({ userId: user.userId, email: user.email, role: user.role });
  return token;
};
