import { v4 as uuid } from 'uuid';
import { dbGet, dbPut, dbDelete, dbScan, tables } from '../lib/db.js';
import { success, fail } from '../lib/response.js';
import { courseSchema, querySemesterSchema, updateCourseSchema, validate } from '../lib/validator.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

export const listCourses = async (req, res, next) => {
  try {
    const validation = validate(querySemesterSchema, req.query || {});
    if (!validation.ok) throw new ValidationError(validation.details);
    const { semester } = validation.data;

    let params = { TableName: tables.courses };
    if (semester) {
      params = {
        ...params,
        FilterExpression: 'semester = :semester',
        ExpressionAttributeValues: {
          ':semester': semester
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

export const getCourseById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await dbGet({
      TableName: tables.courses,
      Key: { courseId: id }
    });
    if (!result.Item) throw new NotFoundError('Không tìm thấy môn học');
    return res.status(200).json(success(result.Item));
  } catch (error) {
    if (error instanceof NotFoundError) {
      return res.status(error.statusCode).json(fail(error.code, error.message));
    }
    return next(error);
  }
};

export const createCourse = async (req, res, next) => {
  try {
    const validation = validate(courseSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const data = validation.data;

    const courseId = uuid();
    const item = { courseId, ...data };
    await dbPut({
      TableName: tables.courses,
      Item: item,
      ConditionExpression: 'attribute_not_exists(courseId)'
    });
    return res.status(201).json(success(item));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const updateCourse = async (req, res, next) => {
  try {
    const validation = validate(updateCourseSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const { id } = req.params;
    const data = validation.data;

    const existing = await dbGet({
      TableName: tables.courses,
      Key: { courseId: id }
    });
    if (!existing.Item) throw new NotFoundError('Không tìm thấy môn học');

    const updated = { ...existing.Item, ...data };
    await dbPut({
      TableName: tables.courses,
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

export const deleteCourse = async (req, res, next) => {
  try {
    const { id } = req.params;
    await dbDelete({
      TableName: tables.courses,
      Key: { courseId: id }
    });
    return res.status(200).json(success({ deleted: true }));
  } catch (error) {
    return next(error);
  }
};
