import { readFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { BatchWriteCommand } from '@aws-sdk/lib-dynamodb';
import { getDocumentClient, tables } from '../src/lib/db.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const client = getDocumentClient();

const sources = [
  { table: tables.users, file: 'seed-users.json' },
  { table: tables.students, file: 'seed-students.json' },
  { table: tables.courses, file: 'seed-courses.json' },
  { table: tables.enrollments, file: 'seed-enrollments.json' }
];

const chunk = (array, size) => {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
};

const seedTable = async (table, items) => {
  const batches = chunk(items, 25);
  for (const batch of batches) {
    const command = new BatchWriteCommand({
      RequestItems: {
        [table]: batch.map((item) => ({ PutRequest: { Item: item } }))
      }
    });
    await client.send(command);
  }
  console.log(`Đã seed bảng ${table} với ${items.length} bản ghi.`);
};

(async () => {
  for (const source of sources) {
    const filePath = path.join(__dirname, source.file);
    const raw = await readFile(filePath, 'utf-8');
    const parsed = JSON.parse(raw);
    await seedTable(source.table, parsed.Items || []);
  }
  console.log('Seed dữ liệu hoàn tất.');
})().catch((error) => {
  console.error('Seed lỗi:', error);
  process.exit(1);
});
