import request from 'supertest';
import app from '../src/app.js';
import { __memoryStore, tables } from '../src/lib/db.js';
import { signToken } from '../src/lib/auth.js';

const token = signToken({ userId: 'tester', email: 'tester@example.com', role: 'admin' });

describe('Enrollments API', () => {
  beforeEach(() => {
    __memoryStore[tables.enrollments].set('E900', {
      enrollmentId: 'E900',
      studentId: 'S900',
      courseId: 'C900',
      status: 'enrolled'
    });
  });

  test('Lọc đăng ký theo sinh viên', async () => {
    const response = await request(app)
      .get('/enrollments?studentId=S900')
      .set('Authorization', `Bearer ${token}`);
    expect(response.status).toBe(200);
    expect(response.body.data[0].enrollmentId).toBe('E900');
  });

  test('Cập nhật trạng thái đăng ký', async () => {
    const response = await request(app)
      .patch('/enrollments/E900')
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'completed' });
    expect(response.status).toBe(200);
    expect(response.body.data.status).toBe('completed');
  });
});
