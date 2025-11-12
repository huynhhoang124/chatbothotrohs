import { v4 as uuid } from 'uuid';
import { dbDelete, dbGet, dbPut, dbQuery, dbScan, tables } from '../lib/db.js';
import { success, fail } from '../lib/response.js';
import {
  enrollmentSchema,
  enrollmentUpdateSchema,
  queryEnrollmentSchema,
  validate
} from '../lib/validator.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

export const listEnrollments = async (req, res, next) => {
  try {
    const validation = validate(queryEnrollmentSchema, req.query || {});
    if (!validation.ok) throw new ValidationError(validation.details);
    const { studentId } = validation.data;

    let items = [];
    if (studentId) {
      const result = await dbQuery({
        TableName: tables.enrollments,
        IndexName: 'gsi_student',
        KeyConditionExpression: 'studentId = :studentId',
        ExpressionAttributeValues: {
          ':studentId': studentId
        }
      });
      items = result.Items || [];
    } else {
      const result = await dbScan({ TableName: tables.enrollments });
      items = result.Items || [];
    }

    return res.status(200).json(success(items));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const createEnrollment = async (req, res, next) => {
  try {
    const validation = validate(enrollmentSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const data = validation.data;

    const enrollmentId = uuid();
    const item = { enrollmentId, status: 'enrolled', ...data };

    await dbPut({
      TableName: tables.enrollments,
      Item: item,
      ConditionExpression: 'attribute_not_exists(enrollmentId)'
    });

    return res.status(201).json(success(item));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const updateEnrollment = async (req, res, next) => {
  try {
    const validation = validate(enrollmentUpdateSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const { id } = req.params;

    const existing = await dbGet({
      TableName: tables.enrollments,
      Key: { enrollmentId: id }
    });
    if (!existing.Item) throw new NotFoundError('Không tìm thấy đăng ký học');

    const updated = { ...existing.Item, ...validation.data };
    await dbPut({
      TableName: tables.enrollments,
      Item: updated
    });

    return res.status(200).json(success(updated));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    if (error instanceof NotFoundError) {
      return res.status(error.statusCode).json(fail(error.code, error.message));
    }
    return next(error);
  }
};

export const deleteEnrollment = async (req, res, next) => {
  try {
    const { id } = req.params;
    await dbDelete({
      TableName: tables.enrollments,
      Key: { enrollmentId: id }
    });
    return res.status(200).json(success({ deleted: true }));
  } catch (error) {
    return next(error);
  }
};
