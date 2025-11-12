import request from 'supertest';
import app from '../src/app.js';
import { __memoryStore, tables } from '../src/lib/db.js';
import { hashPassword } from '../src/lib/auth.js';

describe('Auth API', () => {
  test('Đăng ký thành công trả token', async () => {
    const response = await request(app).post('/auth/register').send({
      email: 'newuser@example.com',
      password: '123456'
    });
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.data.token).toBeDefined();
  });

  test('Không cho phép đăng ký trùng email', async () => {
    __memoryStore[tables.users].set('existing', {
      userId: 'existing',
      email: 'dup@example.com',
      passwordHash: 'hash',
      role: 'student',
      createdAt: new Date().toISOString()
    });

    const response = await request(app).post('/auth/register').send({
      email: 'dup@example.com',
      password: '123456'
    });
    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
  });

  test('Đăng nhập thành công', async () => {
    const passwordHash = await hashPassword('123456');
    __memoryStore[tables.users].set('loginUser', {
      userId: 'loginUser',
      email: 'login@example.com',
      passwordHash,
      role: 'student',
      createdAt: new Date().toISOString()
    });

    const response = await request(app).post('/auth/login').send({
      email: 'login@example.com',
      password: '123456'
    });
    expect(response.status).toBe(200);
    expect(response.body.data.token).toBeDefined();
  });

  test('Đăng nhập sai mật khẩu', async () => {
    const passwordHash = await hashPassword('123456');
    __memoryStore[tables.users].set('loginUser2', {
      userId: 'loginUser2',
      email: 'wrongpass@example.com',
      passwordHash,
      role: 'student',
      createdAt: new Date().toISOString()
    });

    const response = await request(app).post('/auth/login').send({
      email: 'wrongpass@example.com',
      password: '654321'
    });
    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
  });
});
