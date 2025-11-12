import request from 'supertest';
import app from '../src/app.js';
import { __memoryStore, tables } from '../src/lib/db.js';
import { signToken } from '../src/lib/auth.js';

const token = signToken({ userId: 'tester', email: 'tester@example.com', role: 'admin' });

describe('Courses API', () => {
  beforeEach(() => {
    __memoryStore[tables.courses].set('C900', {
      courseId: 'C900',
      title: 'Khởi nghiệp',
      credits: 2,
      semester: '2024A',
      teacher: 'GV. Demo'
    });
  });

  test('Lọc môn học theo học kỳ', async () => {
    const response = await request(app)
      .get('/courses?semester=2024A')
      .set('Authorization', `Bearer ${token}`);
    expect(response.status).toBe(200);
    expect(response.body.data[0].courseId).toBe('C900');
  });

  test('Tạo môn học', async () => {
    const response = await request(app)
      .post('/courses')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Kỹ năng mềm', credits: 2, semester: '2024B', teacher: 'GV. Mới' });
    expect(response.status).toBe(201);
    expect(response.body.data.title).toBe('Kỹ năng mềm');
  });
});
