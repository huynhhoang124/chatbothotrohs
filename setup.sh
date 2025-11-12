#!/usr/bin/env bash
set -e
echo 'Tạo cấu trúc Student Support Copilot...'
mkdir -p 'seed'
mkdir -p 'src'
mkdir -p 'src/handlers'
mkdir -p 'src/lib'
mkdir -p 'src/prompts'
mkdir -p 'src/utils'
mkdir -p 'tests'
cat <<'EOF' > '.env.example'
OPENAI_API_KEY=
JWT_SECRET=supersecret
NODE_ENV=development

EOF
echo 'Đã ghi .env.example'
cat <<'EOF' > '.eslintrc.cjs'
module.exports = {
  env: {
    es2021: true,
    node: true,
    jest: true
  },
  extends: ['eslint:recommended', 'plugin:import/errors', 'plugin:import/warnings', 'plugin:import/node', 'prettier'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  rules: {
    'import/no-unresolved': 'off',
    'no-console': 'off'
  }
};

EOF
echo 'Đã ghi .eslintrc.cjs'
cat <<'EOF' > '.gitignore'
node_modules
.serverless
.dynamodb
.env
coverage
npm-debug.log*
.DS_Store
.idea
.sls-next

EOF
echo 'Đã ghi .gitignore'
cat <<'EOF' > '.nvmrc'
20.19.0

EOF
echo 'Đã ghi .nvmrc'
cat <<'EOF' > '.prettierrc'
{
  "singleQuote": true,
  "semi": true,
  "tabWidth": 2,
  "printWidth": 100,
  "trailingComma": "none"
}

EOF
echo 'Đã ghi .prettierrc'
cat <<'EOF' > 'README.md'
# Student Support Copilot (GPT-only, Trường học)

Student Support Copilot là dự án API serverless hỗ trợ sinh viên tra cứu học vụ, đăng ký học phần và tương tác với trợ lý GPT hoàn toàn bằng tiếng Việt. Hệ thống chạy offline với Serverless Framework, mô phỏng AWS Lambda và DynamoDB Local, tích hợp xác thực JWT bảo mật.

## Tính năng chính

- 🔐 Đăng ký/đăng nhập người dùng với bcrypt + JWT, vai trò mặc định `student`.
- 🎓 Quản lý sinh viên, môn học, đăng ký học phần (CRUD đầy đủ, lọc theo tiêu chí).
- 🤖 Trợ lý GPT-only đọc prompt chuyên biệt (`faq`, `hocvu`, `dangky`, `email`, `khieunai`, `tonghop`) và trả lời tiếng Việt lịch sự.
- 📚 Seed sẵn dữ liệu mẫu: 10 sinh viên, 8 môn học, 12 đăng ký.
- 🧰 Kiến trúc Express + Serverless Offline, sử dụng DynamoDB Local in-memory.
- 🧪 Bộ kiểm thử Jest + Supertest kiểm tra các luồng chính và lỗi phổ biến.

## Yêu cầu hệ thống

- Node.js >= 20.19.0 (khuyến nghị dùng `nvm use`).
- Java JRE 8+ để chạy DynamoDB Local.
- Quyền thực thi shell script (Unix).

## Cài đặt nhanh

```bash
npm install
npx serverless plugin install -n serverless-offline
npx serverless plugin install -n serverless-dynamodb-local
npm run ddb:install
cp .env.example .env
```

Chỉnh sửa `.env` (thay bằng khóa thật của bạn):

```
OPENAI_API_KEY=sk-xxxxxxx_your_key_here
JWT_SECRET=change_me
NODE_ENV=development
```

> **Lưu ý:** Không commit khóa thật lên kho mã công khai. Chỉ dùng khóa do bạn quản lý.

## Chạy môi trường local

Chạy song song hai cửa sổ:

```bash
npm run ddb:start      # Cửa sổ 1: khởi động DynamoDB Local (cổng 8000)
npm run dev            # Cửa sổ 2: bật Serverless Offline (cổng 3000)
```

Hoặc dùng script thiết lập:

```bash
npm run setup
```

Server sẽ lắng nghe tại `http://localhost:3000`.

## API endpoints chính

Tất cả API trả JSON `{ success, data?, error? }`. Các endpoint (cần JWT trừ `/auth/*` và `/health`):

| Method | URL | Mô tả |
| ------ | --- | ----- |
| GET | `/health` | Kiểm tra trạng thái dịch vụ |
| POST | `/auth/register` | Đăng ký tài khoản mới |
| POST | `/auth/login` | Đăng nhập nhận JWT |
| GET | `/students?keyword=` | Lọc sinh viên theo tên/email |
| GET | `/students/:id` | Chi tiết sinh viên |
| POST | `/students` | Tạo sinh viên |
| PUT | `/students/:id` | Cập nhật sinh viên |
| DELETE | `/students/:id` | Xóa sinh viên |
| GET | `/courses?semester=` | Lọc môn theo học kỳ |
| GET | `/courses/:id` | Chi tiết môn |
| POST | `/courses` | Tạo môn |
| PUT | `/courses/:id` | Cập nhật môn |
| DELETE | `/courses/:id` | Xóa môn |
| GET | `/enrollments?studentId=` | Lấy đăng ký theo sinh viên |
| POST | `/enrollments` | Tạo đăng ký (mặc định `enrolled`) |
| PATCH | `/enrollments/:id` | Đổi trạng thái đăng ký |
| DELETE | `/enrollments/:id` | Hủy đăng ký |
| POST | `/chat/ask` | Hỏi trợ lý GPT |

## Ví dụ `curl`

```bash
# 1) Đăng ký
curl -sS -X POST http://localhost:3000/auth/register \
 -H "Content-Type: application/json" \
 -d '{"email":"sv1@example.com","password":"123456"}'

# 2) Đăng nhập (lấy token)
curl -sS -X POST http://localhost:3000/auth/login \
 -H "Content-Type: application/json" \
 -d '{"email":"sv1@example.com","password":"123456"}'

# 3) Tạo sinh viên
curl -sS -X POST http://localhost:3000/students \
 -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" \
 -d '{"fullName":"Nguyễn Văn A","dob":"2003-05-12","major":"CNTT","email":"a@ptit.edu.vn","classes":["INT3306"]}'

# 4) Hỏi trợ lý GPT
curl -sS -X POST http://localhost:3000/chat/ask \
 -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" \
 -d '{"topic":"faq","question":"Điều kiện tốt nghiệp là gì?"}'
```

## Kiểm thử & lint

- `npm test` (script đã tự thêm cờ `NODE_OPTIONS=--experimental-vm-modules` cho môi trường ESM)
- `npm run lint`
- `npm run format`

## Troubleshooting

| Vấn đề | Cách xử lý |
| ------ | ---------- |
| Node version không đúng | Chạy `nvm use 20.19.0` (đọc `.nvmrc`). |
| DynamoDB Local không chạy | Kiểm tra đã cài JRE và chạy `npm run ddb:install`. |
| Cổng 3000/8000 bận | Đổi cổng trong `serverless.yml` hoặc tắt tiến trình khác. |
| Quyền thực thi `setup.sh` | Chạy `chmod +x setup.sh`. |
| Thiếu OPENAI_API_KEY | Cập nhật `.env` theo mẫu ở trên, đảm bảo có quyền sử dụng. |

## Cấu trúc thư mục

Xem `summary.txt` để có mô tả chi tiết từng file.

EOF
echo 'Đã ghi README.md'
cat <<'EOF' > 'jest.config.js'
export default {
  testEnvironment: 'node',
  verbose: true,
  collectCoverage: false,
  roots: ['<rootDir>/tests'],
  extensionsToTreatAsEsm: ['.js'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  transform: {}
};

EOF
echo 'Đã ghi jest.config.js'
cat <<'EOF' > 'package.json'
{
  "name": "student-support-copilot",
  "version": "1.0.0",
  "description": "API GPT hỗ trợ sinh viên trường học chạy trên Serverless Framework offline.",
  "type": "module",
  "main": "src/app.js",
  "scripts": {
    "dev": "serverless offline start",
    "ddb:install": "sls dynamodb install",
    "ddb:start": "sls dynamodb start",
    "seed": "node ./seed/seed-runner.js",
    "test": "cross-env NODE_OPTIONS=--experimental-vm-modules jest --runInBand",
    "lint": "eslint .",
    "format": "prettier -w .",
    "setup": "bash ./setup.sh"
  },
  "engines": {
    "node": ">=20.19.0"
  },
  "dependencies": {
    "@aws-sdk/client-dynamodb": "^3.540.0",
    "@aws-sdk/lib-dynamodb": "^3.540.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "morgan": "^1.10.0",
    "openai": "^4.52.2",
    "serverless-http": "^3.2.0",
    "uuid": "^9.0.1",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "cross-env": "^7.0.3",
    "eslint": "^8.57.0",
    "eslint-config-prettier": "^9.1.0",
    "eslint-plugin-import": "^2.29.1",
    "jest": "^29.7.0",
    "prettier": "^3.2.5",
    "rimraf": "^5.0.5",
    "serverless": "^3.39.0",
    "serverless-dynamodb-local": "^0.2.40",
    "serverless-offline": "^13.3.2",
    "supertest": "^6.3.4"
  }
}

EOF
echo 'Đã ghi package.json'
cat <<'EOF' > 'postman_collection.json'
{
  "info": {
    "name": "Student Support Copilot",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    "description": "Bộ sưu tập Postman cho API Student Support Copilot"
  },
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000"
    },
    {
      "key": "authToken",
      "value": ""
    },
    {
      "key": "studentId",
      "value": ""
    },
    {
      "key": "courseId",
      "value": ""
    },
    {
      "key": "enrollmentId",
      "value": ""
    }
  ],
  "item": [
    {
      "name": "01 - Health",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{baseUrl}}/health",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "health"
          ]
        }
      }
    },
    {
      "name": "02 - Auth Register",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"email\": \"sv.postman@example.com\",\n  \"password\": \"123456\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/auth/register",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "auth",
            "register"
          ]
        }
      }
    },
    {
      "name": "03 - Auth Login",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"email\": \"sv.postman@example.com\",\n  \"password\": \"123456\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/auth/login",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "auth",
            "login"
          ]
        }
      },
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": [
              "const json = pm.response.json();",
              "if (json.success && json.data.token) {",
              "  pm.collectionVariables.set('authToken', json.data.token);",
              "}"
            ]
          }
        }
      ]
    },
    {
      "name": "04 - Students List",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/students?keyword=sv",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "students"
          ],
          "query": [
            {
              "key": "keyword",
              "value": "sv"
            }
          ]
        }
      }
    },
    {
      "name": "05 - Students Create",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"fullName\": \"Sinh viên Postman\",\n  \"dob\": \"2003-09-09\",\n  \"major\": \"CNTT\",\n  \"email\": \"postman@student.edu\",\n  \"classes\": [\"INT3306\"]\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/students",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "students"
          ]
        }
      }
    },
    {
      "name": "06 - Students Detail",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/students/{{studentId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "students",
            "{{studentId}}"
          ]
        }
      }
    },
    {
      "name": "07 - Students Update",
      "request": {
        "method": "PUT",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"major\": \"Khoa học dữ liệu\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/students/{{studentId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "students",
            "{{studentId}}"
          ]
        }
      }
    },
    {
      "name": "08 - Students Delete",
      "request": {
        "method": "DELETE",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/students/{{studentId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "students",
            "{{studentId}}"
          ]
        }
      }
    },
    {
      "name": "09 - Courses List",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/courses?semester=2024A",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "courses"
          ],
          "query": [
            {
              "key": "semester",
              "value": "2024A"
            }
          ]
        }
      }
    },
    {
      "name": "10 - Courses Create",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"title\": \"Môn mới\",\n  \"credits\": 3,\n  \"semester\": \"2024B\",\n  \"teacher\": \"GV Demo\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/courses",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "courses"
          ]
        }
      }
    },
    {
      "name": "11 - Courses Update",
      "request": {
        "method": "PUT",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"teacher\": \"GV Khác\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/courses/{{courseId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "courses",
            "{{courseId}}"
          ]
        }
      }
    },
    {
      "name": "12 - Courses Delete",
      "request": {
        "method": "DELETE",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/courses/{{courseId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "courses",
            "{{courseId}}"
          ]
        }
      }
    },
    {
      "name": "13 - Enrollments List",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/enrollments?studentId={{studentId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "enrollments"
          ],
          "query": [
            {
              "key": "studentId",
              "value": "{{studentId}}"
            }
          ]
        }
      }
    },
    {
      "name": "14 - Enrollments Create",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"studentId\": \"S001\",\n  \"courseId\": \"C001\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/enrollments",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "enrollments"
          ]
        }
      }
    },
    {
      "name": "15 - Enrollments Update",
      "request": {
        "method": "PATCH",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"status\": \"completed\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/enrollments/{{enrollmentId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "enrollments",
            "{{enrollmentId}}"
          ]
        }
      }
    },
    {
      "name": "16 - Enrollments Delete",
      "request": {
        "method": "DELETE",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "url": {
          "raw": "{{baseUrl}}/enrollments/{{enrollmentId}}",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "enrollments",
            "{{enrollmentId}}"
          ]
        }
      }
    },
    {
      "name": "17 - Chat FAQ",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"topic\": \"faq\",\n  \"question\": \"Thời hạn nộp học phí?\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/chat/ask",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "chat",
            "ask"
          ]
        }
      }
    },
    {
      "name": "18 - Chat Khiếu nại",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          },
          {
            "key": "Authorization",
            "value": "Bearer {{authToken}}"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"topic\": \"khieunai\",\n  \"question\": \"Tôi muốn phản ánh điểm giữa kỳ\",\n  \"context\": {\n    \"studentId\": \"S001\",\n    \"courseId\": \"C001\"\n  }\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/chat/ask",
          "host": [
            "{{baseUrl}}"
          ],
          "path": [
            "chat",
            "ask"
          ]
        }
      }
    }
  ]
}

EOF
echo 'Đã ghi postman_collection.json'
cat <<'EOF' > 'seed/seed-courses.json'
{
  "Items": [
    {
      "courseId": "C001",
      "title": "Nhập môn Công nghệ thông tin",
      "credits": 3,
      "semester": "2024A",
      "teacher": "TS. Nguyễn Hữu Long"
    },
    {
      "courseId": "C002",
      "title": "Cấu trúc dữ liệu",
      "credits": 4,
      "semester": "2024A",
      "teacher": "ThS. Trần Minh"
    },
    {
      "courseId": "C003",
      "title": "Nguyên lý Marketing",
      "credits": 3,
      "semester": "2024B",
      "teacher": "TS. Hoàng Lan"
    },
    {
      "courseId": "C004",
      "title": "Kinh tế vi mô",
      "credits": 3,
      "semester": "2024B",
      "teacher": "PGS. Phạm Thái"
    },
    {
      "courseId": "C005",
      "title": "Lập trình Web",
      "credits": 3,
      "semester": "2024A",
      "teacher": "ThS. Lê Hòa"
    },
    {
      "courseId": "C006",
      "title": "Phân tích dữ liệu",
      "credits": 3,
      "semester": "2024C",
      "teacher": "TS. Nguyễn Lệ"
    },
    {
      "courseId": "C007",
      "title": "Thiết kế đồ họa",
      "credits": 2,
      "semester": "2024C",
      "teacher": "GV. Bùi Hà"
    },
    {
      "courseId": "C008",
      "title": "Truyền thông đa phương tiện",
      "credits": 3,
      "semester": "2024B",
      "teacher": "TS. Đặng Sơn"
    }
  ]
}

EOF
echo 'Đã ghi seed/seed-courses.json'
cat <<'EOF' > 'seed/seed-enrollments.json'
{
  "Items": [
    { "enrollmentId": "E001", "studentId": "S001", "courseId": "C001", "status": "enrolled" },
    { "enrollmentId": "E002", "studentId": "S001", "courseId": "C002", "status": "enrolled" },
    { "enrollmentId": "E003", "studentId": "S002", "courseId": "C003", "status": "completed" },
    { "enrollmentId": "E004", "studentId": "S003", "courseId": "C005", "status": "enrolled" },
    { "enrollmentId": "E005", "studentId": "S004", "courseId": "C004", "status": "dropped" },
    { "enrollmentId": "E006", "studentId": "S005", "courseId": "C006", "status": "enrolled" },
    { "enrollmentId": "E007", "studentId": "S006", "courseId": "C007", "status": "completed" },
    { "enrollmentId": "E008", "studentId": "S007", "courseId": "C008", "status": "enrolled" },
    { "enrollmentId": "E009", "studentId": "S008", "courseId": "C001", "status": "enrolled" },
    { "enrollmentId": "E010", "studentId": "S009", "courseId": "C002", "status": "enrolled" },
    { "enrollmentId": "E011", "studentId": "S010", "courseId": "C005", "status": "enrolled" },
    { "enrollmentId": "E012", "studentId": "S010", "courseId": "C006", "status": "enrolled" }
  ]
}

EOF
echo 'Đã ghi seed/seed-enrollments.json'
cat <<'EOF' > 'seed/seed-runner.js'
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

EOF
echo 'Đã ghi seed/seed-runner.js'
cat <<'EOF' > 'seed/seed-students.json'
{
  "Items": [
    {
      "studentId": "S001",
      "fullName": "Nguyễn Văn A",
      "dob": "2003-01-15",
      "major": "Công nghệ thông tin",
      "email": "s001@school.edu",
      "classes": ["INT3306", "INT3401"]
    },
    {
      "studentId": "S002",
      "fullName": "Trần Thị B",
      "dob": "2002-12-22",
      "major": "Khoa học máy tính",
      "email": "s002@school.edu",
      "classes": ["MAT1101", "PHY1102"]
    },
    {
      "studentId": "S003",
      "fullName": "Lê Văn C",
      "dob": "2003-03-05",
      "major": "Truyền thông",
      "email": "s003@school.edu",
      "classes": ["COM2001"]
    },
    {
      "studentId": "S004",
      "fullName": "Phạm Thị D",
      "dob": "2003-04-12",
      "major": "Quản trị kinh doanh",
      "email": "s004@school.edu",
      "classes": ["BUS1001", "BUS2001"]
    },
    {
      "studentId": "S005",
      "fullName": "Vũ Văn E",
      "dob": "2002-11-01",
      "major": "Tài chính ngân hàng",
      "email": "s005@school.edu",
      "classes": ["FIN2201"]
    },
    {
      "studentId": "S006",
      "fullName": "Đặng Thị F",
      "dob": "2003-06-17",
      "major": "Ngôn ngữ Anh",
      "email": "s006@school.edu",
      "classes": ["ENG3001"]
    },
    {
      "studentId": "S007",
      "fullName": "Hoàng Văn G",
      "dob": "2003-07-21",
      "major": "Logistics",
      "email": "s007@school.edu",
      "classes": ["LOG2101", "LOG2202"]
    },
    {
      "studentId": "S008",
      "fullName": "Bùi Thị H",
      "dob": "2003-02-10",
      "major": "Thiết kế đồ họa",
      "email": "s008@school.edu",
      "classes": ["DES1001", "DES2001"]
    },
    {
      "studentId": "S009",
      "fullName": "Mai Văn I",
      "dob": "2002-09-30",
      "major": "Điện tử viễn thông",
      "email": "s009@school.edu",
      "classes": ["TEL3001"]
    },
    {
      "studentId": "S010",
      "fullName": "Đỗ Thị K",
      "dob": "2003-08-25",
      "major": "Kỹ thuật phần mềm",
      "email": "s010@school.edu",
      "classes": ["SWE3001", "SWE4001"]
    }
  ]
}

EOF
echo 'Đã ghi seed/seed-students.json'
cat <<'EOF' > 'seed/seed-users.json'
{
  "Items": [
    {
      "userId": "11111111-1111-1111-1111-111111111111",
      "email": "admin@school.edu",
      "passwordHash": "$2a$10$CwTycUXWue0Thq9StjUM0uJ8y2bHGhEqTG3OC/qoTr4Wr9yiItEe",
      "role": "admin",
      "createdAt": "2024-01-01T00:00:00.000Z"
    },
    {
      "userId": "22222222-2222-2222-2222-222222222222",
      "email": "svdemo@school.edu",
      "passwordHash": "$2a$10$CwTycUXWue0Thq9StjUM0uJ8y2bHGhEqTG3OC/qoTr4Wr9yiItEe",
      "role": "student",
      "createdAt": "2024-01-02T00:00:00.000Z"
    }
  ]
}

EOF
echo 'Đã ghi seed/seed-users.json'
cat <<'EOF' > 'serverless.yml'
service: student-support-copilot

frameworkVersion: '3'

provider:
  name: aws
  runtime: nodejs20.x
  stage: local
  region: us-east-1
  environment:
    NODE_ENV: ${env:NODE_ENV, 'development'}
    USERS_TABLE: Users
    STUDENTS_TABLE: Students
    COURSES_TABLE: Courses
    ENROLLMENTS_TABLE: Enrollments
    DYNAMODB_ENDPOINT: ${env:DYNAMODB_ENDPOINT, 'http://localhost:8000'}
    JWT_SECRET: ${env:JWT_SECRET}
    OPENAI_API_KEY: ${env:OPENAI_API_KEY}
  iamRoleStatements:
    - Effect: Allow
      Action:
        - dynamodb:DescribeTable
        - dynamodb:Query
        - dynamodb:Scan
        - dynamodb:GetItem
        - dynamodb:PutItem
        - dynamodb:UpdateItem
        - dynamodb:DeleteItem
      Resource:
        - arn:aws:dynamodb:*:*:table/Users
        - arn:aws:dynamodb:*:*:table/Students
        - arn:aws:dynamodb:*:*:table/Courses
        - arn:aws:dynamodb:*:*:table/Enrollments
        - arn:aws:dynamodb:*:*:table/Users/index/gsi_email
        - arn:aws:dynamodb:*:*:table/Enrollments/index/gsi_student

plugins:
  - serverless-dynamodb-local
  - serverless-offline

custom:
  stage: ${opt:stage, self:provider.stage}
  serverless-offline:
    httpPort: 3000
    stage: local
    noPrependStageInUrl: true
    corsAllowOrigin: '*'
    corsAllowHeaders: '*'
    corsAllowCredentials: false
  dynamodb:
    stages:
      - local
    start:
      port: 8000
      inMemory: true
      migrate: true
      seed: true
      convertEmptyValues: true
    seed:
      local:
        sources:
          - table: Users
            sources:
              - seed/seed-users.json
          - table: Students
            sources:
              - seed/seed-students.json
          - table: Courses
            sources:
              - seed/seed-courses.json
          - table: Enrollments
            sources:
              - seed/seed-enrollments.json

functions:
  api:
    handler: src/app.handler
    events:
      - http:
          path: health
          method: get
      - http:
          path: auth/register
          method: post
      - http:
          path: auth/login
          method: post
      - http:
          path: students
          method: get
      - http:
          path: students
          method: post
      - http:
          path: students/{id}
          method: get
      - http:
          path: students/{id}
          method: put
      - http:
          path: students/{id}
          method: delete
      - http:
          path: courses
          method: get
      - http:
          path: courses
          method: post
      - http:
          path: courses/{id}
          method: get
      - http:
          path: courses/{id}
          method: put
      - http:
          path: courses/{id}
          method: delete
      - http:
          path: enrollments
          method: get
      - http:
          path: enrollments
          method: post
      - http:
          path: enrollments/{id}
          method: patch
      - http:
          path: enrollments/{id}
          method: delete
      - http:
          path: chat/ask
          method: post

resources:
  Resources:
    UsersTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: Users
        AttributeDefinitions:
          - AttributeName: userId
            AttributeType: S
          - AttributeName: email
            AttributeType: S
        KeySchema:
          - AttributeName: userId
            KeyType: HASH
        GlobalSecondaryIndexes:
          - IndexName: gsi_email
            KeySchema:
              - AttributeName: email
                KeyType: HASH
            Projection:
              ProjectionType: ALL
        BillingMode: PAY_PER_REQUEST
    StudentsTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: Students
        AttributeDefinitions:
          - AttributeName: studentId
            AttributeType: S
        KeySchema:
          - AttributeName: studentId
            KeyType: HASH
        BillingMode: PAY_PER_REQUEST
    CoursesTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: Courses
        AttributeDefinitions:
          - AttributeName: courseId
            AttributeType: S
        KeySchema:
          - AttributeName: courseId
            KeyType: HASH
        BillingMode: PAY_PER_REQUEST
    EnrollmentsTable:
      Type: AWS::DynamoDB::Table
      Properties:
        TableName: Enrollments
        AttributeDefinitions:
          - AttributeName: enrollmentId
            AttributeType: S
          - AttributeName: studentId
            AttributeType: S
        KeySchema:
          - AttributeName: enrollmentId
            KeyType: HASH
        GlobalSecondaryIndexes:
          - IndexName: gsi_student
            KeySchema:
              - AttributeName: studentId
                KeyType: HASH
            Projection:
              ProjectionType: ALL
        BillingMode: PAY_PER_REQUEST

EOF
echo 'Đã ghi serverless.yml'
cat <<'EOF' > 'src/app.js'
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

EOF
echo 'Đã ghi src/app.js'
cat <<'EOF' > 'src/handlers/auth.js'
import { v4 as uuid } from 'uuid';
import { dbPut, dbQuery, tables } from '../lib/db.js';
import { success, fail } from '../lib/response.js';
import { hashPassword, comparePassword, buildAuthSuccess } from '../lib/auth.js';
import { loginSchema, registerSchema, validate } from '../lib/validator.js';
import { ValidationError } from '../utils/errors.js';

export const register = async (req, res, next) => {
  try {
    const validation = validate(registerSchema, req.body);
    if (!validation.ok) {
      throw new ValidationError(validation.details);
    }
    const { email, password } = validation.data;

    const existing = await dbQuery({
      TableName: tables.users,
      IndexName: 'gsi_email',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email
      }
    });

    if (existing.Items && existing.Items.length > 0) {
      return res.status(400).json(fail('EMAIL_EXISTS', 'Email đã được đăng ký.'));
    }

    const userId = uuid();
    const passwordHash = await hashPassword(password);
    const now = new Date().toISOString();

    await dbPut({
      TableName: tables.users,
      Item: {
        userId,
        email,
        passwordHash,
        role: 'student',
        createdAt: now
      },
      ConditionExpression: 'attribute_not_exists(userId)'
    });

    const token = buildAuthSuccess({ userId, email, role: 'student' });
    return res.status(201).json(success({ token }));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const validation = validate(loginSchema, req.body);
    if (!validation.ok) {
      throw new ValidationError(validation.details);
    }

    const { email, password } = validation.data;
    const query = await dbQuery({
      TableName: tables.users,
      IndexName: 'gsi_email',
      KeyConditionExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': email
      }
    });

    if (!query.Items || query.Items.length === 0) {
      return res.status(401).json(fail('INVALID_CREDENTIALS', 'Email hoặc mật khẩu không đúng.'));
    }

    const user = query.Items[0];
    const isMatch = await comparePassword(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json(fail('INVALID_CREDENTIALS', 'Email hoặc mật khẩu không đúng.'));
    }

    const token = buildAuthSuccess(user);
    return res.status(200).json(success({ token }));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

EOF
echo 'Đã ghi src/handlers/auth.js'
cat <<'EOF' > 'src/handlers/chat.js'
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

EOF
echo 'Đã ghi src/handlers/chat.js'
cat <<'EOF' > 'src/handlers/courses.js'
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

EOF
echo 'Đã ghi src/handlers/courses.js'
cat <<'EOF' > 'src/handlers/enrollments.js'
import { v4 as uuid } from 'uuid';
import { dbDelete, dbGet, dbPut, dbQuery, dbScan, tables } from '../lib/db.js';
import { success, fail } from '../lib/response.js';
import {
  enrollmentSchema,
  enrollmentUpdateSchema,
  queryEnrollmentSchema,
  validate
} from '../lib/validator.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

export const listEnrollments = async (req, res, next) => {
  try {
    const validation = validate(queryEnrollmentSchema, req.query || {});
    if (!validation.ok) throw new ValidationError(validation.details);
    const { studentId } = validation.data;

    let items = [];
    if (studentId) {
      const result = await dbQuery({
        TableName: tables.enrollments,
        IndexName: 'gsi_student',
        KeyConditionExpression: 'studentId = :studentId',
        ExpressionAttributeValues: {
          ':studentId': studentId
        }
      });
      items = result.Items || [];
    } else {
      const result = await dbScan({ TableName: tables.enrollments });
      items = result.Items || [];
    }

    return res.status(200).json(success(items));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const createEnrollment = async (req, res, next) => {
  try {
    const validation = validate(enrollmentSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const data = validation.data;

    const enrollmentId = uuid();
    const item = { enrollmentId, status: 'enrolled', ...data };

    await dbPut({
      TableName: tables.enrollments,
      Item: item,
      ConditionExpression: 'attribute_not_exists(enrollmentId)'
    });

    return res.status(201).json(success(item));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const updateEnrollment = async (req, res, next) => {
  try {
    const validation = validate(enrollmentUpdateSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const { id } = req.params;

    const existing = await dbGet({
      TableName: tables.enrollments,
      Key: { enrollmentId: id }
    });
    if (!existing.Item) throw new NotFoundError('Không tìm thấy đăng ký học');

    const updated = { ...existing.Item, ...validation.data };
    await dbPut({
      TableName: tables.enrollments,
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

export const deleteEnrollment = async (req, res, next) => {
  try {
    const { id } = req.params;
    await dbDelete({
      TableName: tables.enrollments,
      Key: { enrollmentId: id }
    });
    return res.status(200).json(success({ deleted: true }));
  } catch (error) {
    return next(error);
  }
};

EOF
echo 'Đã ghi src/handlers/enrollments.js'
cat <<'EOF' > 'src/handlers/health.js'
import { success, jsonResponse } from '../lib/response.js';

export const ping = async () => {
  const payload = success({ status: 'ok', time: new Date().toISOString() });
  return jsonResponse(200, payload);
};

EOF
echo 'Đã ghi src/handlers/health.js'
cat <<'EOF' > 'src/handlers/students.js'
import { v4 as uuid } from 'uuid';
import { dbGet, dbPut, dbScan, dbDelete, tables } from '../lib/db.js';
import { success, fail } from '../lib/response.js';
import { queryKeywordSchema, studentSchema, updateStudentSchema, validate } from '../lib/validator.js';
import { ValidationError, NotFoundError } from '../utils/errors.js';

export const listStudents = async (req, res, next) => {
  try {
    const validation = validate(queryKeywordSchema, req.query || {});
    if (!validation.ok) throw new ValidationError(validation.details);

    const { keyword } = validation.data;
    let params = { TableName: tables.students };

    if (keyword) {
      params = {
        ...params,
        FilterExpression: 'contains(fullName, :keyword) OR contains(email, :keyword)',
        ExpressionAttributeValues: {
          ':keyword': keyword
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

export const getStudentById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await dbGet({
      TableName: tables.students,
      Key: { studentId: id }
    });
    if (!result.Item) throw new NotFoundError('Không tìm thấy sinh viên');
    return res.status(200).json(success(result.Item));
  } catch (error) {
    if (error instanceof NotFoundError) {
      return res.status(error.statusCode).json(fail(error.code, error.message));
    }
    return next(error);
  }
};

export const createStudent = async (req, res, next) => {
  try {
    const validation = validate(studentSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const data = validation.data;

    const duplicate = await dbScan({
      TableName: tables.students,
      FilterExpression: 'email = :email',
      ExpressionAttributeValues: {
        ':email': data.email
      }
    });
    if (duplicate.Items && duplicate.Items.length > 0) {
      return res.status(400).json(fail('STUDENT_EMAIL_EXISTS', 'Email sinh viên đã tồn tại.'));
    }

    const studentId = uuid();
    const item = { studentId, ...data };
    await dbPut({
      TableName: tables.students,
      Item: item,
      ConditionExpression: 'attribute_not_exists(studentId)'
    });

    return res.status(201).json(success(item));
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(error.statusCode).json(fail(error.code, error.message, error.details));
    }
    return next(error);
  }
};

export const updateStudent = async (req, res, next) => {
  try {
    const validation = validate(updateStudentSchema, req.body);
    if (!validation.ok) throw new ValidationError(validation.details);
    const { id } = req.params;
    const data = validation.data;

    const existing = await dbGet({
      TableName: tables.students,
      Key: { studentId: id }
    });
    if (!existing.Item) throw new NotFoundError('Không tìm thấy sinh viên');

    const updated = { ...existing.Item, ...data };
    await dbPut({
      TableName: tables.students,
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

export const deleteStudent = async (req, res, next) => {
  try {
    const { id } = req.params;
    await dbDelete({
      TableName: tables.students,
      Key: { studentId: id }
    });
    return res.status(200).json(success({ deleted: true }));
  } catch (error) {
    return next(error);
  }
};

EOF
echo 'Đã ghi src/handlers/students.js'
cat <<'EOF' > 'src/lib/auth.js'
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { config } from './config.js';
import { fail, jsonResponse } from './response.js';

const SALT_ROUNDS = 10;

export const hashPassword = async (password) => bcrypt.hash(password, SALT_ROUNDS);
export const comparePassword = async (password, hash) => bcrypt.compare(password, hash);

export const signToken = (payload) =>
  jwt.sign(payload, config.jwtSecret, {
    algorithm: 'HS256',
    expiresIn: '7d'
  });

export const verifyToken = (token) => {
  try {
    return jwt.verify(token, config.jwtSecret);
  } catch (error) {
    return null;
  }
};

export const getTokenFromHeader = (req) => {
  const authHeader = req.headers?.authorization || req.headers?.Authorization;
  if (!authHeader) return null;
  const [scheme, token] = authHeader.split(' ');
  if (scheme !== 'Bearer' || !token) return null;
  return token;
};

export const requireAuth = (req, res, next) => {
  const token = getTokenFromHeader(req);
  if (!token) {
    const response = jsonResponse(401, fail('UNAUTHORIZED', 'Yêu cầu đăng nhập.'));
    return res.status(response.statusCode).json(response.body ? JSON.parse(response.body) : {});
  }
  const decoded = verifyToken(token);
  if (!decoded) {
    const response = jsonResponse(401, fail('UNAUTHORIZED', 'Token không hợp lệ.'));
    return res.status(response.statusCode).json(response.body ? JSON.parse(response.body) : {});
  }
  req.user = decoded;
  return next();
};

export const buildAuthSuccess = (user) => {
  const token = signToken({ userId: user.userId, email: user.email, role: user.role });
  return token;
};

EOF
echo 'Đã ghi src/lib/auth.js'
cat <<'EOF' > 'src/lib/config.js'
import dotenv from 'dotenv';

dotenv.config();

const tableNames = {
  users: process.env.USERS_TABLE || 'Users',
  students: process.env.STUDENTS_TABLE || 'Students',
  courses: process.env.COURSES_TABLE || 'Courses',
  enrollments: process.env.ENROLLMENTS_TABLE || 'Enrollments'
};

const corsOrigins = [/^http:\/\/localhost(:\d+)?$/];

export const config = {
  get environment() {
    return process.env.NODE_ENV || 'development';
  },
  tableNames,
  get jwtSecret() {
    return process.env.JWT_SECRET || 'local-secret';
  },
  set jwtSecret(value) {
    process.env.JWT_SECRET = value;
  },
  get openAiKey() {
    return process.env.OPENAI_API_KEY || '';
  },
  set openAiKey(value) {
    process.env.OPENAI_API_KEY = value;
  },
  get dynamoEndpoint() {
    return process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000';
  },
  set dynamoEndpoint(value) {
    process.env.DYNAMODB_ENDPOINT = value;
  },
  corsOrigins
};

export const isProduction = () => config.environment === 'production';

EOF
echo 'Đã ghi src/lib/config.js'
cat <<'EOF' > 'src/lib/db.js'
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  QueryCommand,
  ScanCommand,
  UpdateCommand,
  DeleteCommand
} from '@aws-sdk/lib-dynamodb';
import { config } from './config.js';

export const tables = config.tableNames;

const isTestEnv = process.env.NODE_ENV === 'test';

let documentClient;
if (!isTestEnv) {
  const dynamoClient = new DynamoDBClient({
    region: 'local',
    endpoint: config.dynamoEndpoint,
    credentials: {
      accessKeyId: 'fakeMyKeyId',
      secretAccessKey: 'fakeSecretAccessKey'
    }
  });

  documentClient = DynamoDBDocumentClient.from(dynamoClient, {
    marshallOptions: {
      removeUndefinedValues: true
    }
  });
}

const memoryStore = Object.values(tables).reduce((acc, tableName) => {
  acc[tableName] = new Map();
  return acc;
}, {});

const clone = (value) => JSON.parse(JSON.stringify(value));

const applyFilter = (item, { FilterExpression, ExpressionAttributeValues }) => {
  if (!FilterExpression) return true;
  const values = ExpressionAttributeValues || {};
  if (FilterExpression.includes('contains(fullName, :keyword)')) {
    const keyword = values[':keyword'] || '';
    return (
      item.fullName?.toLowerCase().includes(keyword.toLowerCase()) ||
      item.email?.toLowerCase().includes(keyword.toLowerCase())
    );
  }
  if (FilterExpression.includes('email = :email')) {
    return item.email === values[':email'];
  }
  if (FilterExpression.includes('semester = :semester')) {
    return item.semester === values[':semester'];
  }
  return true;
};

const queryByIndex = (table, indexName, values) => {
  const items = Array.from(memoryStore[table].values());
  if (indexName === 'gsi_email') {
    const email = values[':email'];
    return items.filter((item) => item.email === email);
  }
  if (indexName === 'gsi_student') {
    const studentId = values[':studentId'];
    return items.filter((item) => item.studentId === studentId);
  }
  return items;
};

export const resetMemoryStore = () => {
  Object.keys(memoryStore).forEach((table) => memoryStore[table].clear());
};

export const getDocumentClient = () => {
  if (isTestEnv) {
    throw new Error('DocumentClient không khả dụng trong môi trường test in-memory.');
  }
  return documentClient;
};

export const dbGet = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const keyName = Object.keys(params.Key)[0];
    const keyValue = params.Key[keyName];
    const item = memoryStore[table].get(keyValue);
    return { Item: item ? clone(item) : undefined };
  }
  return documentClient.send(new GetCommand(params));
};

export const dbPut = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const item = clone(params.Item);
    const keyName = Object.keys(item).find((key) => key.endsWith('Id'));
    if (!keyName) throw new Error('Không xác định được khóa chính.');
    memoryStore[table].set(item[keyName], item);
    return {};
  }
  return documentClient.send(new PutCommand(params));
};

export const dbScan = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const items = Array.from(memoryStore[table].values()).filter((item) =>
      applyFilter(item, params)
    );
    return { Items: clone(items) };
  }
  return documentClient.send(new ScanCommand(params));
};

export const dbQuery = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const items = queryByIndex(table, params.IndexName, params.ExpressionAttributeValues || {});
    return { Items: clone(items) };
  }
  return documentClient.send(new QueryCommand(params));
};

export const dbUpdate = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const keyName = Object.keys(params.Key)[0];
    const keyValue = params.Key[keyName];
    const existing = memoryStore[table].get(keyValue) || {};
    const updated = { ...existing, ...(params.ExpressionAttributeValues?.[':value'] || {}) };
    memoryStore[table].set(keyValue, updated);
    return { Attributes: clone(updated) };
  }
  return documentClient.send(new UpdateCommand(params));
};

export const dbDelete = async (params) => {
  if (isTestEnv) {
    const table = params.TableName;
    const keyName = Object.keys(params.Key)[0];
    const keyValue = params.Key[keyName];
    memoryStore[table].delete(keyValue);
    return {};
  }
  return documentClient.send(new DeleteCommand(params));
};

export const __memoryStore = memoryStore;

EOF
echo 'Đã ghi src/lib/db.js'
cat <<'EOF' > 'src/lib/logger.js'
import morgan from 'morgan';
import { isProduction } from './config.js';

const format = isProduction() ? 'combined' : 'dev';

export const requestLogger = morgan(format, {
  stream: {
    write: (message) => {
      console.log(message.trim());
    }
  }
});

export const logError = (error, context = {}) => {
  console.error('[LỖI]', {
    message: error.message,
    name: error.name,
    context
  });
};

EOF
echo 'Đã ghi src/lib/logger.js'
cat <<'EOF' > 'src/lib/response.js'
export const success = (data = null, meta = {}) => ({
  success: true,
  data,
  meta
});

export const fail = (code, message, details = []) => ({
  success: false,
  error: {
    code,
    message,
    details
  }
});

export const jsonResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(body)
});

EOF
echo 'Đã ghi src/lib/response.js'
cat <<'EOF' > 'src/lib/validator.js'
import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email({ message: 'Email không hợp lệ' }).max(255),
  password: z.string().min(6, { message: 'Mật khẩu tối thiểu 6 ký tự' }).max(100)
});

export const loginSchema = registerSchema;

export const studentSchema = z.object({
  fullName: z.string().min(2, { message: 'Họ tên quá ngắn' }),
  dob: z.string().min(4, { message: 'Ngày sinh không hợp lệ' }),
  major: z.string().min(2, { message: 'Chuyên ngành không hợp lệ' }),
  email: z.string().email({ message: 'Email sinh viên không hợp lệ' }),
  classes: z.array(z.string().min(1)).default([])
});

export const updateStudentSchema = studentSchema.partial();

export const courseSchema = z.object({
  title: z.string().min(2),
  credits: z.number().int().min(1).max(10),
  semester: z.string().min(1),
  teacher: z.string().min(2)
});

export const updateCourseSchema = courseSchema.partial();

export const enrollmentSchema = z.object({
  studentId: z.string().min(1),
  courseId: z.string().min(1)
});

export const enrollmentUpdateSchema = z.object({
  status: z.enum(['enrolled', 'completed', 'dropped'])
});

export const chatSchema = z.object({
  topic: z.enum(['faq', 'hocvu', 'dangky', 'email', 'khieunai', 'tonghop']),
  question: z.string().min(5),
  context: z.record(z.any()).optional()
});

export const queryKeywordSchema = z.object({
  keyword: z.string().optional()
});

export const querySemesterSchema = z.object({
  semester: z.string().optional()
});

export const queryEnrollmentSchema = z.object({
  studentId: z.string().optional()
});

export const validate = (schema, data) => {
  const result = schema.safeParse(data);
  if (!result.success) {
    const details = result.error.issues.map((issue) => ({
      path: issue.path.join('.'),
      message: issue.message
    }));
    return { ok: false, details };
  }
  return { ok: true, data: result.data };
};

EOF
echo 'Đã ghi src/lib/validator.js'
cat <<'EOF' > 'src/prompts/dangky.md'
Tư vấn đăng ký học phần: kiểm tra điều kiện tiên quyết, gợi ý lịch học cân bằng, cảnh báo mốc thời gian và học phí.

EOF
echo 'Đã ghi src/prompts/dangky.md'
cat <<'EOF' > 'src/prompts/email.md'
Hỗ trợ soạn email học vụ trang trọng: mở đầu chào hỏi, giới thiệu bản thân, trình bày vấn đề rõ ràng, đề xuất mong muốn và cảm ơn cuối thư.

EOF
echo 'Đã ghi src/prompts/email.md'
cat <<'EOF' > 'src/prompts/faq.md'
Bạn có bộ tài liệu FAQ học vụ bao gồm:
- Điều kiện tốt nghiệp, thời gian xét tốt nghiệp.
- Quy định đăng ký tín chỉ, giới hạn tín chỉ mỗi kỳ.
- Liên hệ phòng đào tạo, phòng CTSV.
Cung cấp câu trả lời ngắn gọn, dẫn chiếu quy định nếu có.

EOF
echo 'Đã ghi src/prompts/faq.md'
cat <<'EOF' > 'src/prompts/hocvu.md'
Bạn hỗ trợ các thủ tục học vụ như bảo lưu, gia hạn học phí, xác nhận sinh viên. Hãy hướng dẫn từng bước cụ thể và lưu ý giấy tờ cần nộp.

EOF
echo 'Đã ghi src/prompts/hocvu.md'
cat <<'EOF' > 'src/prompts/khieunai.md'
Tiếp nhận khiếu nại: tóm tắt vấn đề, xác định bộ phận xử lý, đề xuất bước tiếp theo và hẹn phản hồi.

EOF
echo 'Đã ghi src/prompts/khieunai.md'
cat <<'EOF' > 'src/utils/errors.js'
export class ApplicationError extends Error {
  constructor(message, statusCode = 500, code = 'APPLICATION_ERROR', details = []) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

export class ValidationError extends ApplicationError {
  constructor(details) {
    super('Dữ liệu không hợp lệ', 400, 'VALIDATION_ERROR', details);
  }
}

export class UnauthorizedError extends ApplicationError {
  constructor(message = 'Yêu cầu đăng nhập.') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

export class NotFoundError extends ApplicationError {
  constructor(message = 'Không tìm thấy dữ liệu') {
    super(message, 404, 'NOT_FOUND');
  }
}

EOF
echo 'Đã ghi src/utils/errors.js'
cat <<'EOF' > 'summary.txt'
serverless.yml - Cấu hình Serverless Framework, plugin offline và khai báo bảng DynamoDB.
package.json - Khai báo package Node.js, scripts và dependency ESM.
.env.example - Mẫu cấu hình môi trường (API key, JWT secret, NODE_ENV).
.gitignore - Loại trừ thư mục build, node_modules, file môi trường.
.nvmrc - Khuyến nghị phiên bản Node 20.19.0.
README.md - Tài liệu hướng dẫn cài đặt, chạy và mô tả API tiếng Việt.
setup.sh - Script tái tạo toàn bộ cấu trúc dự án và nội dung file.
summary.txt - Danh sách mô tả nhanh từng file.
postman_collection.json - Bộ sưu tập Postman cho toàn bộ endpoint.
jest.config.js - Cấu hình Jest chạy trong môi trường Node ESM.
.eslintrc.cjs - Quy tắc ESLint.
.prettierrc - Thiết lập Prettier.
seed/seed-users.json - Dữ liệu mẫu bảng Users.
seed/seed-students.json - Dữ liệu mẫu bảng Students (10 bản ghi).
seed/seed-courses.json - Dữ liệu mẫu bảng Courses (8 bản ghi).
seed/seed-enrollments.json - Dữ liệu mẫu bảng Enrollments (12 bản ghi).
seed/seed-runner.js - Script nạp seed vào DynamoDB Local.
src/app.js - Ứng dụng Express bọc Serverless, định nghĩa route và middleware.
src/handlers/auth.js - Xử lý đăng ký/đăng nhập, hash mật khẩu, trả JWT.
src/handlers/students.js - CRUD sinh viên và tìm kiếm theo từ khóa.
src/handlers/courses.js - CRUD môn học và lọc theo học kỳ.
src/handlers/enrollments.js - CRUD đăng ký học phần và lọc theo sinh viên.
src/handlers/chat.js - Proxy gọi OpenAI GPT-only với prompt tiếng Việt.
src/handlers/health.js - Endpoint kiểm tra sức khỏe dịch vụ.
src/lib/config.js - Nạp biến môi trường và cấu hình chung.
src/lib/db.js - Kết nối DynamoDB hoặc in-memory (khi test), helper CRUD.
src/lib/response.js - Tiện ích chuẩn hóa JSON response.
src/lib/validator.js - Định nghĩa schema zod cho các payload.
src/lib/auth.js - Hàm hash/compare bcrypt, JWT helper và middleware.
src/lib/logger.js - Middleware morgan và logging lỗi.
src/prompts/*.md - Prompt GPT theo từng chủ đề hỗ trợ sinh viên.
src/utils/errors.js - Định nghĩa lớp lỗi ứng dụng tùy biến.
tests/setup.js - Thiết lập môi trường test, reset in-memory store.
tests/auth.test.js - Kiểm thử auth happy path và lỗi.
tests/students.test.js - Kiểm thử CRUD sinh viên với JWT.
tests/courses.test.js - Kiểm thử API môn học.
tests/enrollments.test.js - Kiểm thử API đăng ký học.
tests/chat.test.js - Kiểm thử endpoint chat và xử lý thiếu khóa.

EOF
echo 'Đã ghi summary.txt'
cat <<'EOF' > 'tests/auth.test.js'
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

EOF
echo 'Đã ghi tests/auth.test.js'
cat <<'EOF' > 'tests/chat.test.js'
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

EOF
echo 'Đã ghi tests/chat.test.js'
cat <<'EOF' > 'tests/courses.test.js'
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

EOF
echo 'Đã ghi tests/courses.test.js'
cat <<'EOF' > 'tests/enrollments.test.js'
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

EOF
echo 'Đã ghi tests/enrollments.test.js'
cat <<'EOF' > 'tests/setup.js'
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

EOF
echo 'Đã ghi tests/setup.js'
cat <<'EOF' > 'tests/students.test.js'
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

EOF
echo 'Đã ghi tests/students.test.js'
echo 'Hoàn tất.'