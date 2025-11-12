import express from 'express';
import cors from 'cors';
import serverless from 'serverless-http';
import { config } from './lib/config.js';
import { requestLogger, logError } from './lib/logger.js';
import { fail } from './lib/response.js';
import { requireAuth } from './lib/auth.js';
import * as authHandlers from './handlers/auth.js';
import * as studentHandlers from './handlers/students.js';
import * as courseHandlers from './handlers/courses.js';
import * as enrollmentHandlers from './handlers/enrollments.js';
import * as chatHandlers from './handlers/chat.js';
import * as healthHandler from './handlers/health.js';

const app = express();

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      const allowed = config.corsOrigins.some((rule) => rule.test(origin));
      return allowed ? callback(null, true) : callback(new Error('Origin không được phép'));
    }
  })
);
app.use(express.json({ limit: '1mb' }));
app.use(requestLogger);

app.get('/health', async (req, res) => {
  const response = await healthHandler.ping();
  res.status(response.statusCode).json(JSON.parse(response.body));
});

app.post('/auth/register', authHandlers.register);
app.post('/auth/login', authHandlers.login);

app.get('/students', requireAuth, studentHandlers.listStudents);
app.get('/students/:id', requireAuth, studentHandlers.getStudentById);
app.post('/students', requireAuth, studentHandlers.createStudent);
app.put('/students/:id', requireAuth, studentHandlers.updateStudent);
app.delete('/students/:id', requireAuth, studentHandlers.deleteStudent);

app.get('/courses', requireAuth, courseHandlers.listCourses);
app.get('/courses/:id', requireAuth, courseHandlers.getCourseById);
app.post('/courses', requireAuth, courseHandlers.createCourse);
app.put('/courses/:id', requireAuth, courseHandlers.updateCourse);
app.delete('/courses/:id', requireAuth, courseHandlers.deleteCourse);

app.get('/enrollments', requireAuth, enrollmentHandlers.listEnrollments);
app.post('/enrollments', requireAuth, enrollmentHandlers.createEnrollment);
app.patch('/enrollments/:id', requireAuth, enrollmentHandlers.updateEnrollment);
app.delete('/enrollments/:id', requireAuth, enrollmentHandlers.deleteEnrollment);

app.post('/chat/ask', requireAuth, chatHandlers.askChat);

app.use((err, req, res, next) => {
  logError(err, { path: req.path });
  const status = err.statusCode || 500;
  const body = fail(err.code || 'INTERNAL_ERROR', err.message || 'Lỗi không xác định', err.details);
  res.status(status).json(body);
});

export const handler = serverless(app);
export default app;
