import { readFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import OpenAI from 'openai';
import { config } from '../lib/config.js';
import { success, fail } from '../lib/response.js';
import { chatSchema, validate } from '../lib/validator.js';
import { ValidationError } from '../utils/errors.js';
import { logError } from '../lib/logger.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const promptsDir = path.resolve(__dirname, '../prompts');

const promptFiles = {
  faq: 'faq.md',
  hocvu: 'hocvu.md',
  dangky: 'dangky.md',
  email: 'email.md',
  khieunai: 'khieunai.md',
  tonghop: 'faq.md'
};

const loadPrompt = async (topic) => {
  const fileName = promptFiles[topic];
  if (!fileName) return '';
  const filePath = path.join(promptsDir, fileName);
  const content = await readFile(filePath, 'utf-8');
  return content;
};

export const askChat = async (req, res, next) => {
  try {
    const validation = validate(chatSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const { topic, question, context } = validation.data;

    if (!config.openAiKey) {
      return res.status(400).json(
        fail(
          'OPENAI_KEY_MISSING',
          'Thiếu khóa OPENAI_API_KEY. Vui lòng cấu hình trong file .env rồi chạy lại.'
        )
      );
    }

    const client = new OpenAI({ apiKey: config.openAiKey });
    const basePrompt = await loadPrompt(topic);

    const systemPrompt = `Bạn là trợ lý học vụ trường đại học. Hãy trả lời rõ ràng, bằng tiếng Việt, ưu tiên gọn gàng, dùng bullet khi thích hợp, tránh suy đoán vô căn cứ.\n\n${basePrompt}`;

    const contextText = context ? `\n\nBối cảnh bổ sung:\n${JSON.stringify(context, null, 2)}` : '';
    const finalQuestion = `${question}${contextText}`;

    const response = await client.responses.create({
      model: 'gpt-4o-mini',
      input: [
        {
          role: 'system',
          content: systemPrompt
        },
        {
          role: 'user',
          content: finalQuestion
        }
      ]
    });

    const answer = response.output_text || 'Xin lỗi, hiện chưa có câu trả lời.';
    return res.status(200).json(success({ answer }));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    logError(error, { scope: 'chat' });
    return res
      .status(500)
      .json(fail('OPENAI_ERROR', 'Không thể kết nối tới mô hình GPT, vui lòng thử lại sau.'));
  }
};
