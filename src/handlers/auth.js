import { v4 as uuid } from 'uuid';
import { dbPut, dbQuery, tables } from '../lib/db.js';
import { success, fail } from '../lib/response.js';
import { hashPassword, comparePassword, buildAuthSuccess } from '../lib/auth.js';
import { loginSchema, registerSchema, validate } from '../lib/validator.js';
import { ValidationError } from '../utils/errors.js';

export const register = async (req, res, next) => {
  try {
    const validation = validate(registerSchema, req.body);
    if (!validation.ok) {
      throw new ValidationError(validation.details);
    }
    const { email, password } = validation.data;

    const existing = await dbQuery({
      TableName: tables.users,
      IndexName: 'gsi_email',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email
      }
    });

    if (existing.Items && existing.Items.length > 0) {
      return res.status(400).json(fail('EMAIL_EXISTS', 'Email đã được đăng ký.'));
    }

    const userId = uuid();
    const passwordHash = await hashPassword(password);
    const now = new Date().toISOString();

    await dbPut({
      TableName: tables.users,
      Item: {
        userId,
        email,
        passwordHash,
        role: 'student',
        createdAt: now
      },
      ConditionExpression: 'attribute_not_exists(userId)'
    });

    const token = buildAuthSuccess({ userId, email, role: 'student' });
    return res.status(201).json(success({ token }));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const validation = validate(loginSchema, req.body);
    if (!validation.ok) {
      throw new ValidationError(validation.details);
    }

    const { email, password } = validation.data;
    const query = await dbQuery({
      TableName: tables.users,
      IndexName: 'gsi_email',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email
      }
    });

    if (!query.Items || query.Items.length === 0) {
      return res.status(401).json(fail('INVALID_CREDENTIALS', 'Email hoặc mật khẩu không đúng.'));
    }

    const user = query.Items[0];
    const isMatch = await comparePassword(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json(fail('INVALID_CREDENTIALS', 'Email hoặc mật khẩu không đúng.'));
    }

    const token = buildAuthSuccess(user);
    return res.status(200).json(success({ token }));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};
