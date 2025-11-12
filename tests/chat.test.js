import { jest } from '@jest/globals';

jest.mock('openai', () => {
  return {
    default: jest.fn().mockImplementation(() => ({
      responses: {
        create: jest.fn().mockResolvedValue({ output_text: 'Phản hồi mô phỏng' })
      }
    }))
  };
});

import request from 'supertest';
import app from '../src/app.js';
import { signToken } from '../src/lib/auth.js';
import { config } from '../src/lib/config.js';

const token = signToken({ userId: 'tester', email: 'tester@example.com', role: 'student' });

describe('Chat API', () => {
  test('Gửi câu hỏi GPT thành công', async () => {
    const response = await request(app)
      .post('/chat/ask')
      .set('Authorization', `Bearer ${token}`)
      .send({ topic: 'faq', question: 'Điều kiện tốt nghiệp là gì?' });
    expect(response.status).toBe(200);
    expect(response.body.data.answer).toContain('Phản hồi');
  });

  test('Báo lỗi khi thiếu khóa OpenAI', async () => {
    const originalKey = config.openAiKey;
    config.openAiKey = '';

    const response = await request(app)
      .post('/chat/ask')
      .set('Authorization', `Bearer ${token}`)
      .send({ topic: 'faq', question: 'Thiếu khóa thì sao?' });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('OPENAI_KEY_MISSING');
    config.openAiKey = originalKey;
  });
});
