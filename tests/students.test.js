import request from 'supertest';
import app from '../src/app.js';
import { __memoryStore, tables } from '../src/lib/db.js';
import { signToken } from '../src/lib/auth.js';

const token = signToken({ userId: 'tester', email: 'tester@example.com', role: 'admin' });

const authHeader = () => ({ Authorization: `Bearer ${token}` });

describe('Students API', () => {
  beforeEach(() => {
    __memoryStore[tables.students].set('S900', {
      studentId: 'S900',
      fullName: 'Sinh Viên 900',
      dob: '2003-01-01',
      major: 'CNTT',
      email: 's900@school.edu',
      classes: ['INT3306']
    });
  });

  test('Liệt kê sinh viên', async () => {
    const response = await request(app).get('/students').set(authHeader());
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body.data)).toBe(true);
  });

  test('Tạo sinh viên mới', async () => {
    const response = await request(app)
      .post('/students')
      .set(authHeader())
      .send({
        fullName: 'Sinh Viên 901',
        dob: '2003-05-12',
        major: 'Kinh tế',
        email: 's901@school.edu',
        classes: ['BUS1001']
      });
    expect(response.status).toBe(201);
    expect(response.body.data.fullName).toBe('Sinh Viên 901');
  });

  test('Cập nhật sinh viên', async () => {
    const response = await request(app)
      .put('/students/S900')
      .set(authHeader())
      .send({ major: 'Khoa học dữ liệu' });
    expect(response.status).toBe(200);
    expect(response.body.data.major).toBe('Khoa học dữ liệu');
  });

  test('Xóa sinh viên', async () => {
    const response = await request(app).delete('/students/S900').set(authHeader());
    expect(response.status).toBe(200);
    expect(response.body.data.deleted).toBe(true);
  });
});
