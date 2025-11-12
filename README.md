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
