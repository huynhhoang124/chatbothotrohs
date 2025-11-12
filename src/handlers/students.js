import { v4 as uuid } from 'uuid';
import { dbGet, dbPut, dbScan, dbDelete, tables } from '../lib/db.js';
import { success, fail } from '../lib/response.js';
import { queryKeywordSchema, studentSchema, updateStudentSchema, validate } from '../lib/validator.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

export const listStudents = async (req, res, next) => {
  try {
    const validation = validate(queryKeywordSchema, req.query || {});
    if (!validation.ok) throw new ValidationError(validation.details);

    const { keyword } = validation.data;
    let params = { TableName: tables.students };

    if (keyword) {
      params = {
        ...params,
        FilterExpression: 'contains(fullName, :keyword) OR contains(email, :keyword)',
        ExpressionAttributeValues: {
          ':keyword': keyword
        }
      };
    }

    const result = await dbScan(params);
    return res.status(200).json(success(result.Items || []));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const getStudentById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await dbGet({
      TableName: tables.students,
      Key: { studentId: id }
    });
    if (!result.Item) throw new NotFoundError('Không tìm thấy sinh viên');
    return res.status(200).json(success(result.Item));
  } catch (error) {
    if (error instanceof NotFoundError) {
      return res.status(error.statusCode).json(fail(error.code, error.message));
    }
    return next(error);
  }
};

export const createStudent = async (req, res, next) => {
  try {
    const validation = validate(studentSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const data = validation.data;

    const duplicate = await dbScan({
      TableName: tables.students,
      FilterExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': data.email
      }
    });
    if (duplicate.Items && duplicate.Items.length > 0) {
      return res.status(400).json(fail('STUDENT_EMAIL_EXISTS', 'Email sinh viên đã tồn tại.'));
    }

    const studentId = uuid();
    const item = { studentId, ...data };
    await dbPut({
      TableName: tables.students,
      Item: item,
      ConditionExpression: 'attribute_not_exists(studentId)'
    });

    return res.status(201).json(success(item));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const updateStudent = async (req, res, next) => {
  try {
    const validation = validate(updateStudentSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const { id } = req.params;
    const data = validation.data;

    const existing = await dbGet({
      TableName: tables.students,
      Key: { studentId: id }
    });
    if (!existing.Item) throw new NotFoundError('Không tìm thấy sinh viên');

    const updated = { ...existing.Item, ...data };
    await dbPut({
      TableName: tables.students,
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

export const deleteStudent = async (req, res, next) => {
  try {
    const { id } = req.params;
    await dbDelete({
      TableName: tables.students,
      Key: { studentId: id }
    });
    return res.status(200).json(success({ deleted: true }));
  } catch (error) {
    return next(error);
  }
};
