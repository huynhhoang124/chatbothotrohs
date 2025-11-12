import { beforeEach } from '@jest/globals';

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'jest-secret';
process.env.OPENAI_API_KEY = 'sk-test';

const { resetMemoryStore } = await import('../src/lib/db.js');
const { config } = await import('../src/lib/config.js');

config.jwtSecret = process.env.JWT_SECRET;
config.openAiKey = process.env.OPENAI_API_KEY;

beforeEach(() => {
  resetMemoryStore();
});
